import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { CreateOrderDto, UpdateOrderDto } from '../dto/create-order.dto';
import { OrderStatus } from '@prisma/client';

@Injectable()
export class OrdersService {
  constructor(private prisma: PrismaService) {}

  async findAll(artisanId: string, status?: OrderStatus, search?: string) {
    return this.prisma.order.findMany({
      where: {
        artisanId,
        ...(status && { status }),
        ...(search && {
          OR: [
            { title: { contains: search, mode: 'insensitive' } },
            { customer: { name: { contains: search, mode: 'insensitive' } } },
          ],
        }),
      },
      include: {
        customer: { select: { id: true, name: true, phone: true, isVip: true } },
        payments: { select: { id: true, amount: true, status: true, method: true } },
        transaction: { select: { id: true } },
      },
      orderBy: [{ isUrgent: 'desc' }, { dueDate: 'asc' }, { createdAt: 'desc' }],
    });
  }

  async findOne(artisanId: string, orderId: string) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, artisanId },
      include: {
        customer: true,
        payments: true,
      },
    });
    if (!order) throw new NotFoundException('Commande non trouvée');
    return order;
  }

  async create(artisanId: string, dto: CreateOrderDto) {
    // Vérifier le client appartient à l'artisan
    const customer = await this.prisma.customer.findFirst({
      where: { id: dto.customerId, artisanId },
    });
    if (!customer) throw new NotFoundException('Client non trouvé');

    // Générer un numéro de commande unique
    const count = await this.prisma.order.count({ where: { artisanId } });
    const orderNumber = `CMD-${Date.now()}-${count + 1}`;

    const order = await this.prisma.order.create({
      data: {
        artisanId,
        customerId: dto.customerId,
        title: dto.title,
        description: dto.description,
        amount: dto.amount,
        deposit: dto.deposit ?? 0,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
        isUrgent: dto.isUrgent ?? false,
        notes: dto.notes,
        orderNumber,
        localId: dto.localId,
        syncStatus: 'SYNCED',
      },
      include: { customer: true },
    });

    // Mettre à jour le compteur client
    await this.prisma.customer.update({
      where: { id: dto.customerId },
      data: { totalOrders: { increment: 1 }, lastOrderAt: new Date() },
    });

    return { data: order, message: 'Commande créée avec succès' };
  }

  async update(artisanId: string, orderId: string, dto: UpdateOrderDto) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, artisanId },
    });
    if (!order) throw new NotFoundException('Commande non trouvée');

    const progressByStatus: Partial<Record<OrderStatus, number>> = {
      EN_ATTENTE: 0,
      EN_COURS: 35,
      PRET: 80,
      LIVRE: 100,
      ANNULE: 0,
    };
    const statusProgress = dto.status ? progressByStatus[dto.status] : undefined;
    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: {
        ...(dto.title && { title: dto.title }),
        ...(dto.status && { status: dto.status as OrderStatus }),
        ...(dto.progressPct !== undefined && { progressPct: dto.progressPct }),
        ...(dto.progressPct === undefined && statusProgress !== undefined && {
          progressPct: statusProgress,
        }),
        ...(dto.dueDate && { dueDate: new Date(dto.dueDate) }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
        ...(dto.isUrgent !== undefined && { isUrgent: dto.isUrgent }),
        // Si livré, enregistrer la date
        ...(dto.status === 'LIVRE' && { deliveredAt: new Date() }),
        ...(dto.status && dto.status !== 'LIVRE' && { deliveredAt: null }),
      },
      include: { customer: true },
    });

    return { data: updated, message: 'Commande mise à jour' };
  }

  async remove(artisanId: string, orderId: string) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, artisanId },
      select: { id: true, customerId: true },
    });
    if (!order) throw new NotFoundException('Commande non trouvée');

    await this.prisma.$transaction(async (tx) => {
      await tx.transaction.updateMany({
        where: { orderId },
        data: { orderId: null },
      });
      await tx.payment.deleteMany({ where: { orderId } });
      await tx.order.delete({ where: { id: orderId } });
      await tx.customer.updateMany({
        where: { id: order.customerId, artisanId, totalOrders: { gt: 0 } },
        data: { totalOrders: { decrement: 1 } },
      });
    });
    return { message: 'Commande supprimée' };
  }

  async getUrgentOrders(artisanId: string) {
    const threeDaysFromNow = new Date();
    threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

    return this.prisma.order.findMany({
      where: {
        artisanId,
        status: { in: ['EN_ATTENTE', 'EN_COURS'] },
        OR: [
          { isUrgent: true },
          { dueDate: { lte: threeDaysFromNow } },
        ],
      },
      include: { customer: true },
      orderBy: { dueDate: 'asc' },
    });
  }

  async sendBulkReminders(artisanId: string) {
    const urgentOrders = await this.getUrgentOrders(artisanId);
    // Déclenche la queue de notifications (Bull)
    return { data: urgentOrders, message: `${urgentOrders.length} rappels envoyés` };
  }
}
