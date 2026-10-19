import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';
import { UpgradeSubscriptionDto } from './dto/upgrade-subscription.dto';
import { SubscriptionPlan } from '@prisma/client';

@Injectable()
export class SubscriptionsService {
  private readonly logger = new Logger(SubscriptionsService.name);

  constructor(private prisma: PrismaService) {}

  async upgradePlan(userId: string, dto: UpgradeSubscriptionDto) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { userId },
      include: { subscription: true },
    });
    if (!artisan) throw new NotFoundException('Profil artisan non trouvé');

    if (dto.plan === SubscriptionPlan.FREE) {
      throw new BadRequestException('Veuillez choisir un plan payant (PREMIUM ou PREMIUM_PLUS)');
    }

    const prices: Record<SubscriptionPlan, number> = {
      FREE: 0,
      PREMIUM: 5000,
      PREMIUM_PLUS: 10000,
    };
    const price = prices[dto.plan] ?? 5000;

    // Calculer la date de fin (30 jours)
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 30);

    const paymentRef = `SUB-${dto.method}-${Date.now()}`;

    const subscription = await this.prisma.subscription.upsert({
      where: { artisanId: artisan.id },
      update: {
        plan: dto.plan,
        status: 'ACTIVE',
        price,
        startDate,
        endDate,
        paymentRef,
      },
      create: {
        artisanId: artisan.id,
        plan: dto.plan,
        status: 'ACTIVE',
        price,
        startDate,
        endDate,
        paymentRef,
      },
    });

    // Enregistrer le paiement
    await this.prisma.payment.create({
      data: {
        amount: price,
        method: dto.method,
        status: 'PAYE',
        reference: paymentRef,
        paidAt: new Date(),
      },
    });

    // Notification pour l'artisan
    const planLabel = dto.plan === 'PREMIUM' ? 'Premium (5 000 FCFA)' : 'Premium+ (10 000 FCFA)';
    await this.prisma.notification.create({
      data: {
        userId,
        type: 'PAIEMENT',
        channel: 'IN_APP',
        title: '🎉 Abonnement Activé !',
        body: `Félicitations ! Votre abonnement ${planLabel} a été activé avec succès via ${dto.method}. Profitez de vos fonctionnalités illimitées.`,
      },
    });

    this.logger.log(`Abonnement ${dto.plan} activé pour l'artisan ${artisan.id} via ${dto.method}`);

    return {
      data: subscription,
      message: `Félicitations ! Votre abonnement ${dto.plan} est maintenant actif.`,
    };
  }

  async getMySubscription(userId: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { userId },
      include: { subscription: true },
    });
    if (!artisan) throw new NotFoundException('Profil artisan non trouvé');
    return artisan.subscription;
  }
}
