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

      const mktOrder = await tx.marketplaceOrder.create({
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

      // Regrouper les articles par artisan
      const itemsByArtisan = new Map<string, typeof orderItems>();
      for (const item of orderItems) {
        const list = itemsByArtisan.get(item.artisanId) || [];
        list.push(item);
        itemsByArtisan.set(item.artisanId, list);
      }

      // Synchroniser avec l'espace de chaque artisan concerné
      for (const [artisanId, items] of itemsByArtisan.entries()) {
        const artisan = await tx.artisan.findUnique({
          where: { id: artisanId },
          include: { user: true },
        });
        if (!artisan) continue;

        const clientUser = await tx.user.findUnique({
          where: { id: userId },
        });

        const clientPhone = clientUser?.phone || '+22100000000';
        const clientName = clientUser?.email?.split('@')[0] || 'Client Marketplace';

        // 1. Ajouter ou mettre à jour le client dans le carnet de l'artisan
        let customer = await tx.customer.findFirst({
          where: { artisanId, phone: clientPhone },
        });

        if (!customer) {
          customer = await tx.customer.create({
            data: {
              artisanId,
              name: clientName,
              phone: clientPhone,
              email: clientUser?.email,
              address: dto.address,
              notes: 'Client venu de la Marketplace NDOKETE',
              totalOrders: 1,
            },
          });
        } else {
          await tx.customer.update({
            where: { id: customer.id },
            data: {
              totalOrders: { increment: 1 },
              lastOrderAt: new Date(),
            },
          });
        }

        // 2. Créer la commande dans l'espace de travail de l'artisan (en attente de paiement)
        const artisanAmount = items.reduce((sum, i) => sum + i.unitPrice * i.quantity, 0);
        const commission = Math.round(artisanAmount * 0.10);

        const itemNames = items
          .map((i) => {
            const p = products.find((prod) => prod.id === i.productId);
            return `${p?.name || 'Produit'} (x${i.quantity})`;
          })
          .join(', ');

        const artisanOrder = await tx.order.create({
          data: {
            artisanId,
            customerId: customer.id,
            orderNumber: `CMD-MKT-${orderNumber}`,
            title: `Marketplace: ${itemNames}`,
            description: `Adresse de livraison: ${dto.address || 'Non spécifiée'}. Notes: ${dto.notes || 'Aucune'}`,
            amount: artisanAmount,
            deposit: 0, // En attente de paiement
            status: 'EN_ATTENTE', // En attente de paiement
            progressPct: 0,
            syncStatus: 'SYNCED',
          },
        });

        // 2c. Enregistrer le paiement en attente
        await tx.payment.create({
          data: {
            marketplaceOrderId: mktOrder.id,
            orderId: artisanOrder.id,
            amount: artisanAmount,
            method: 'WAVE',
            status: 'EN_ATTENTE',
            reference: `PENDING-MKT-${Date.now()}-${Math.floor(Math.random() * 100)}`,
            commission,
            commissionPct: 10,
          },
        });

        // 3. Envoyer une notification in-app à l'artisan
        await tx.notification.create({
          data: {
            userId: artisan.userId,
            type: 'COMMANDE',
            channel: 'IN_APP',
            title: '🛍️ Nouvelle commande (En attente de paiement)',
            body: `${clientName} a commandé "${itemNames}" (${artisanAmount} FCFA). En attente du paiement par le client.`,
            data: {
              orderId: artisanOrder.id,
              marketplaceOrderId: mktOrder.id,
            },
          },
        });
      }

      return mktOrder;
    });

    return { data: order, message: 'Commande marketplace créée', totalAmount };
  }

  async getClientOrders(userId: string) {
    const client = await this.prisma.client.findUnique({ where: { userId } });
    if (!client) return [];
    
    const mktOrders = await this.prisma.marketplaceOrder.findMany({
      where: { clientId: client.id },
      include: {
        payments: true,
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

    // Synchroniser automatiquement les statuts des commandes Marketplace avec l'espace artisan
    for (const mktOrder of mktOrders) {
      const artisanOrder = await this.prisma.order.findFirst({
        where: { orderNumber: `CMD-MKT-${mktOrder.orderNumber}` },
      });
      if (artisanOrder && artisanOrder.status !== mktOrder.status) {
        await this.prisma.marketplaceOrder.update({
          where: { id: mktOrder.id },
          data: { status: artisanOrder.status },
        });
        mktOrder.status = artisanOrder.status;
      }
    }

    return mktOrders;
  }
}
