import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { IsString, IsOptional, IsEmail, IsBoolean, MinLength } from 'class-validator';

export class CreateCustomerDto {
  @IsString() @MinLength(1) name: string;
  @IsString() @MinLength(1) phone: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() address?: string;
  @IsOptional() @IsString() notes?: string;
  @IsOptional() @IsBoolean() isVip?: boolean;
  @IsOptional() measurements?: Record<string, any>;
  @IsOptional() @IsString() localId?: string;
}

@Injectable()
export class ClientsService {
  constructor(private prisma: PrismaService) {}

  async findAll(artisanId: string, search?: string) {
    const customers = await this.prisma.customer.findMany({
      where: {
        artisanId,
        ...(search && {
          OR: [
            { name: { contains: search, mode: 'insensitive' } },
            { phone: { contains: search } },
          ],
        }),
      },
      orderBy: [{ isVip: 'desc' }, { lastOrderAt: 'desc' }],
      include: { _count: { select: { orders: true } } },
    });
    return customers.map((customer) => {
      const summary: Record<string, unknown> = { ...customer };
      delete summary.measurements;
      delete summary._count;
      summary.totalOrders = customer._count.orders;
      return summary;
    });
  }

  async findOne(artisanId: string, customerId: string) {
    const customer = await this.prisma.customer.findFirst({
      where: { id: customerId, artisanId },
      include: {
        _count: { select: { orders: true } },
        orders: {
          orderBy: { createdAt: 'desc' },
          take: 10,
          include: { payments: true },
        },
      },
    });
    if (!customer) throw new NotFoundException('Client non trouvé');
    const { _count, ...details } = customer;
    return { ...details, totalOrders: _count.orders };
  }

  async create(artisanId: string, dto: CreateCustomerDto) {
    const name = dto.name?.trim();
    const phone = dto.phone?.trim();
    if (!name || !phone) {
      throw new BadRequestException('Le nom et le téléphone du client sont obligatoires');
    }
    // Vérifier limite plan FREE (20 clients max)
    const artisan = await this.prisma.artisan.findUnique({
      where: { id: artisanId },
      include: { subscription: true },
    });

    if (artisan?.subscription?.plan === 'FREE') {
      const count = await this.prisma.customer.count({ where: { artisanId } });
      if (count >= 20) {
        throw new ForbiddenException(
          'Limite de 20 clients atteinte sur le plan gratuit. Passez au Premium !',
        );
      }
    }

    const customer = await this.prisma.customer.create({
      data: {
        artisanId,
        name,
        phone,
        email: dto.email,
        address: dto.address,
        notes: dto.notes,
        isVip: dto.isVip ?? false,
        measurements: dto.measurements ?? {},
      },
    });

    return { data: customer, message: 'Client ajouté avec succès' };
  }

  async update(artisanId: string, customerId: string, dto: Partial<CreateCustomerDto>) {
    const customer = await this.prisma.customer.findFirst({
      where: { id: customerId, artisanId },
    });
    if (!customer) throw new NotFoundException('Client non trouvé');
    if (dto.name !== undefined && !dto.name.trim()) {
      throw new BadRequestException('Le nom du client est obligatoire');
    }
    if (dto.phone !== undefined && !dto.phone.trim()) {
      throw new BadRequestException('Le téléphone du client est obligatoire');
    }

    const updated = await this.prisma.customer.update({
      where: { id: customerId },
      data: {
        ...(dto.name !== undefined && { name: dto.name.trim() }),
        ...(dto.phone !== undefined && { phone: dto.phone.trim() }),
        ...(dto.email !== undefined && { email: dto.email }),
        ...(dto.address !== undefined && { address: dto.address }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
        ...(dto.isVip !== undefined && { isVip: dto.isVip }),
        ...(dto.measurements && { measurements: dto.measurements }),
      },
    });

    return { data: updated, message: 'Client mis à jour' };
  }

  async updateMeasurements(artisanId: string, customerId: string, measurements: Record<string, any>) {
    const customer = await this.prisma.customer.findFirst({
      where: { id: customerId, artisanId },
    });
    if (!customer) throw new NotFoundException('Client non trouvé');

    const updated = await this.prisma.customer.update({
      where: { id: customerId },
      data: { measurements },
    });

    return { data: updated, message: 'Mesures mises à jour' };
  }

  async remove(artisanId: string, customerId: string) {
    const customer = await this.prisma.customer.findFirst({
      where: { id: customerId, artisanId },
      select: { id: true },
    });
    if (!customer) throw new NotFoundException('Client non trouvé');

    const orders = await this.prisma.order.findMany({
      where: { customerId, artisanId },
      select: { id: true },
    });
    const orderIds = orders.map((order) => order.id);

    await this.prisma.$transaction(async (tx) => {
      if (orderIds.length) {
        // Keep accounting records while removing customer-linked order details.
        await tx.transaction.updateMany({
          where: { orderId: { in: orderIds } },
          data: { orderId: null },
        });
        await tx.payment.deleteMany({ where: { orderId: { in: orderIds } } });
        await tx.order.deleteMany({ where: { id: { in: orderIds }, artisanId } });
      }
      await tx.customer.delete({ where: { id: customerId } });
    });

    return {
      message: `Client supprimé${orderIds.length ? ` avec ${orderIds.length} commande(s)` : ''}`,
      deletedOrders: orderIds.length,
    };
  }
}
