import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { IsArray, IsInt, IsOptional, IsString, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateMarketplaceOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MarketplaceOrderItemDto)
  items: Array<{ productId: string; quantity: number }>;
  @IsOptional() @IsString()
  address?: string;
  @IsOptional() @IsString()
  notes?: string;
}

export class MarketplaceOrderItemDto {
  @IsString()
  productId: string;

  @IsInt()
  @Min(1)
  quantity: number;
}

@Injectable()
export class MarketplaceOrdersService {
  constructor(private prisma: PrismaService) {}

  async createOrder(userId: string, dto: CreateMarketplaceOrderDto) {
    const client = await this.prisma.client.findUnique({ where: { userId } });
    if (!client) throw new NotFoundException('Profil client non trouvé');
    if (dto.items.length === 0) {
      throw new BadRequestException('La commande doit contenir au moins un produit');
    }
    const uniqueProductIds = new Set(dto.items.map((item) => item.productId));
    if (uniqueProductIds.size !== dto.items.length) {
      throw new BadRequestException('Un produit ne peut apparaître qu’une seule fois');
    }

    // Récupérer les produits et calculer le total
    const productIds = dto.items.map((i) => i.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds }, status: 'ACTIF' },
    });

    let totalAmount = 0;
    const orderItems = dto.items.map((item) => {
      const product = products.find((p) => p.id === item.productId);
      if (!product) throw new BadRequestException(`Produit ${item.productId} non disponible`);
      if (product.stock < item.quantity) {
        throw new BadRequestException(`Stock insuffisant pour ${product.name}`);
      }
      const lineTotal = product.price * item.quantity;
      totalAmount += lineTotal;
      return {
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: product.price,
        artisanId: product.artisanId,
      };
    });

    const orderNumber = `MKT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    const order = await this.prisma.$transaction(async (tx) => {
      for (const item of dto.items) {
        const reserved = await tx.product.updateMany({
          where: { id: item.productId, status: 'ACTIF', stock: { gte: item.quantity } },
          data: { stock: { decrement: item.quantity }, orderCount: { increment: 1 } },
        });
        if (reserved.count !== 1) {
          throw new BadRequestException('Le stock a changé, veuillez réessayer');
        }
      }
      return tx.marketplaceOrder.create({
        data: {
          clientId: client.id,
          orderNumber,
          totalAmount,
          address: dto.address,
          notes: dto.notes,
          items: { createMany: { data: orderItems } },
        },
        include: { items: { include: { product: true } } },
      });
    });

    return { data: order, message: 'Commande marketplace créée', totalAmount };
  }

  async getClientOrders(userId: string) {
    const client = await this.prisma.client.findUnique({ where: { userId } });
    if (!client) throw new NotFoundException('Profil client non trouvé');
    return this.prisma.marketplaceOrder.findMany({
      where: { clientId: client.id },
      include: {
        items: {
          include: {
            product: {
              include: { artisan: { select: { businessName: true } } },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
