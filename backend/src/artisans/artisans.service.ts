import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';

@Injectable()
export class ArtisansService {
  constructor(private prisma: PrismaService) {}

  async getProfile(artisanId: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { id: artisanId },
      include: {
        user: { select: { email: true, phone: true } },
        subscription: true,
        analytics: true,
        autoReminders: true,
        _count: { select: { customers: true, orders: true, products: true } },
      },
    });
    if (!artisan) throw new NotFoundException('Artisan non trouvé');
    return artisan;
  }

  async getDashboard(artisanId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [todaySales, activeOrders, avgRating, recentOrders, stockAlerts] =
      await Promise.all([
        // Ventes du jour
        this.prisma.transaction.aggregate({
          where: {
            artisanId,
            type: 'ENTREE',
            date: { gte: today },
          },
          _sum: { amount: true },
        }),
        // Commandes en cours
        this.prisma.order.count({
          where: { artisanId, status: { in: ['EN_ATTENTE', 'EN_COURS'] } },
        }),
        // Note moyenne
        this.prisma.review.aggregate({
          where: { artisanId },
          _avg: { rating: true },
        }),
        // 5 dernières commandes
        this.prisma.order.findMany({
          where: { artisanId },
          orderBy: { createdAt: 'desc' },
          take: 5,
          include: { customer: { select: { name: true } } },
        }),
        // Alertes stock
        this.prisma.stockItem.findMany({
          where: { artisanId },
          select: { id: true, name: true, quantity: true, alertThreshold: true, unit: true },
        }).then((items) => items.filter((i) => i.quantity <= i.alertThreshold)),
      ]);

    return {
      todaySales: todaySales._sum.amount ?? 0,
      activeOrders,
      avgRating: Math.round((avgRating._avg.rating ?? 0) * 10) / 10,
      recentOrders,
      stockAlerts: stockAlerts.slice(0, 3),
    };
  }

  async updateProfile(artisanId: string, data: Partial<{
    businessName: string;
    description: string;
    quarter: string;
    waveNumber: string;
    orangeMoneyNumber: string;
    profilePhoto: string;
    coverPhoto: string;
    specialty: string[];
    isPublic: boolean;
  }> & { autoReminders?: {
    whatsappEnabled?: boolean;
    smsEnabled?: boolean;
    hoursBeforeDelivery?: number;
    messageTemplate?: string;
  } }) {
    const { autoReminders, ...artisanData } = data;
    const updated = await this.prisma.$transaction(async (tx) => {
      const artisan = await tx.artisan.update({
        where: { id: artisanId },
        data: artisanData,
      });
      if (autoReminders) {
        await tx.autoReminder.upsert({
          where: { artisanId },
          create: { artisanId, ...autoReminders },
          update: autoReminders,
        });
      }
      return artisan;
    });
    return { data: updated, message: 'Profil mis à jour' };
  }

  async getPublicProfile(artisanId: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { id: artisanId, isPublic: true },
      include: {
        products: { where: { status: 'ACTIF' }, take: 12 },
        reviews: {
          orderBy: { createdAt: 'desc' },
          take: 10,
          include: { client: { include: { user: { select: { email: true } } } } },
        },
        _count: { select: { orders: true, customers: true } },
      },
    });
    if (!artisan) throw new NotFoundException('Artisan non trouvé');
    return artisan;
  }
}
