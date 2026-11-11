import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private prisma: PrismaService) {}

  async getArtisanKPIs(artisanId: string) {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0);

    const [currentRevenue, lastRevenue, totalOrders, activeCustomers, avgOrderValue] =
      await Promise.all([
        this.prisma.transaction.aggregate({
          where: { artisanId, type: 'ENTREE', date: { gte: monthStart } },
          _sum: { amount: true },
        }),
        this.prisma.transaction.aggregate({
          where: {
            artisanId,
            type: 'ENTREE',
            date: { gte: lastMonthStart, lte: lastMonthEnd },
          },
          _sum: { amount: true },
        }),
        this.prisma.order.count({
          where: { artisanId, status: { in: ['EN_COURS', 'EN_ATTENTE'] } },
        }),
        this.prisma.customer.count({
          where: { artisanId, lastOrderAt: { gte: monthStart } },
        }),
        this.prisma.order.aggregate({
          where: { artisanId },
          _avg: { amount: true },
        }),
      ]);

    const currentRev = currentRevenue._sum.amount ?? 0;
    const lastRev = lastRevenue._sum.amount ?? 1;
    const growth = Math.round(((currentRev - lastRev) / lastRev) * 100);

    return {
      monthlyRevenue: currentRev,
      revenueGrowth: growth,
      activeOrders: totalOrders,
      activeCustomers,
      avgOrderValue: Math.round(avgOrderValue._avg.amount ?? 0),
    };
  }

  async getAdminKPIs() {
    const [totalArtisans, totalClients, premiumArtisans, totalRevenue, churnRisk] = await Promise.all([
      this.prisma.artisan.count(),
      this.prisma.client.count(),
      this.prisma.subscription.count({
        where: { plan: { in: ['PREMIUM', 'PREMIUM_PLUS'] }, status: 'ACTIVE' },
      }),
      this.prisma.payment.aggregate({
        where: { status: 'PAYE' },
        _sum: { commission: true },
      }),
      this.prisma.artisan.count({
        where: {
          orders: {
            none: {
              createdAt: { gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
            },
          },
        },
      }),
    ]);

    const mrr = await this.prisma.subscription.aggregate({
      where: { status: 'ACTIVE' },
      _sum: { price: true },
    });

    return {
      totalArtisans,
      totalClients,
      premiumArtisans,
      freePct: totalArtisans > 0 ? Math.round(((totalArtisans - premiumArtisans) / totalArtisans) * 100) : 100,
      totalCommissions: totalRevenue._sum.commission ?? 0,
      mrr: mrr._sum.price ?? 0,
      churnRisk,
    };
  }

  async getAdminArtisans() {
    const artisans = await this.prisma.artisan.findMany({
      include: {
        user: { select: { email: true, phone: true, isActive: true, isVerified: true, createdAt: true } },
        subscription: true,
        _count: { select: { customers: true, products: true, orders: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return artisans.map((a) => ({
      id: a.id,
      userId: a.userId,
      businessName: a.businessName,
      email: a.user.email,
      phone: a.user.phone,
      quarter: a.quarter,
      specialty: a.specialty,
      isActive: a.user.isActive ?? true,
      plan: a.subscription?.plan ?? 'FREE',
      subscriptionStatus: a.subscription?.status ?? 'INACTIVE',
      customersCount: a._count.customers,
      productsCount: a._count.products,
      ordersCount: a._count.orders,
      createdAt: a.createdAt,
    }));
  }

  async toggleArtisanStatus(artisanId: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { id: artisanId },
      include: { user: true },
    });
    if (!artisan) throw new NotFoundException('Artisan non trouvé');

    const newActiveState = !artisan.user.isActive;
    await this.prisma.user.update({
      where: { id: artisan.userId },
      data: { isActive: newActiveState },
    });

    return {
      success: true,
      isActive: newActiveState,
      message: newActiveState ? 'Compte artisan réactivé avec succès' : 'Compte artisan suspendu avec succès',
    };
  }

  async updateArtisanPlan(artisanId: string, plan: 'FREE' | 'PREMIUM' | 'PREMIUM_PLUS') {
    const prices = { FREE: 0, PREMIUM: 5000, PREMIUM_PLUS: 10000 };
    const price = prices[plan] ?? 0;

    const sub = await this.prisma.subscription.upsert({
      where: { artisanId },
      update: { plan, status: 'ACTIVE', price },
      create: { artisanId, plan, status: 'ACTIVE', price },
    });

    return { data: sub, message: `Plan modifié vers ${plan}` };
  }

  async deleteClient(clientId: string) {
    const client = await this.prisma.client.findUnique({
      where: { id: clientId },
      include: { cart: { include: { items: true } } },
    });
    if (!client) throw new NotFoundException('Client non trouvé');

    await this.prisma.$transaction(async (tx) => {
      if (client.cart) {
        await tx.cartItem.deleteMany({ where: { cartId: client.cart.id } });
        await tx.cart.delete({ where: { id: client.cart.id } });
      }

      await tx.review.deleteMany({ where: { clientId } });

      const mktOrders = await tx.marketplaceOrder.findMany({ where: { clientId } });
      for (const order of mktOrders) {
        await tx.marketplaceOrderItem.deleteMany({ where: { orderId: order.id } });
        await tx.payment.deleteMany({ where: { marketplaceOrderId: order.id } });
      }
      await tx.marketplaceOrder.deleteMany({ where: { clientId } });

      await tx.client.delete({ where: { id: clientId } });

      if (client.userId) {
        await tx.user.delete({ where: { id: client.userId } }).catch(() => {});
      }
    });

    return { success: true, message: 'Client et toutes ses données supprimés définitivement' };
  }

  async getAdminClients() {
    const clients = await this.prisma.client.findMany({
      include: {
        user: { select: { email: true, phone: true, isVerified: true, isActive: true, createdAt: true } },
        _count: { select: { marketplaceOrders: true, reviews: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return clients.map((c) => ({
      id: c.id,
      userId: c.userId,
      name: c.name || 'Client',
      email: c.user.email,
      phone: c.user.phone,
      address: c.address,
      isActive: c.user.isActive ?? true,
      ordersCount: c._count.marketplaceOrders,
      reviewsCount: c._count.reviews,
      createdAt: c.createdAt,
    }));
  }
}
