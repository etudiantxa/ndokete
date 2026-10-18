import { Injectable } from '@nestjs/common';
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
    const [totalArtisans, premiumArtisans, totalRevenue, churnRisk] = await Promise.all([
      this.prisma.artisan.count(),
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
      premiumArtisans,
      freePct: Math.round(((totalArtisans - premiumArtisans) / totalArtisans) * 100),
      totalCommissions: totalRevenue._sum.commission ?? 0,
      mrr: mrr._sum.price ?? 0,
      churnRisk,
    };
  }
}
