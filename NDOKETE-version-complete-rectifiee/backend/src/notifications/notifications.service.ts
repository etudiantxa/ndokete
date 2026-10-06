import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { NotificationsGateway } from './notifications.gateway';
import * as admin from 'firebase-admin';
import { NotificationType } from '@prisma/client';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
    private gateway: NotificationsGateway,
  ) {
    // Initialiser Firebase Admin SDK
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: config.get('FIREBASE_PROJECT_ID'),
          privateKey: config.get<string>('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
          clientEmail: config.get('FIREBASE_CLIENT_EMAIL'),
        }),
      });
    }
  }

  async getAll(userId: string, unreadOnly = false) {
    return this.prisma.notification.findMany({
      where: { userId, ...(unreadOnly && { isRead: false }) },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markAsRead(userId: string, notificationId: string) {
    await this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true },
    });
    return { message: 'Notification marquée comme lue' };
  }

  async markAllAsRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return { message: 'Toutes les notifications marquées comme lues' };
  }

  async sendOrderNotification(artisanId: string, orderId: string, type: NotificationType) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { id: artisanId },
      include: { user: true },
    });
    if (!artisan) return;

    const titles: Record<string, string> = {
      COMMANDE: 'Nouvelle commande',
      PAIEMENT: 'Paiement reçu',
      RAPPEL_LIVRAISON: 'Rappel livraison',
      STOCK_ALERTE: 'Stock critique',
      NOUVEAU_AVIS: 'Nouvel avis',
    };

    const notification = await this.prisma.notification.create({
      data: {
        userId: artisan.userId,
        type,
        title: titles[type] ?? 'Notification',
        body: `Commande #${orderId.slice(0, 8)} - ${titles[type]}`,
        data: { orderId, artisanId },
      },
    });

    // Envoi push Firebase
    if (artisan.user.fcmToken) {
      await this.sendPushNotification(
        artisan.user.fcmToken,
        notification.title,
        notification.body,
        { orderId, type },
      );
    }

    // Notification temps réel WebSocket
    this.gateway.sendToUser(artisan.userId, 'notification', notification);
  }

  async sendDeliveryReminder(artisanId: string, customerName: string, orderId: string) {
    const artisan = await this.prisma.artisan.findUnique({
      where: { id: artisanId },
      include: { user: true, autoReminders: true },
    });
    if (!artisan) return;

    const reminder = artisan.autoReminders;
    const message = (reminder?.messageTemplate ?? 'Bonjour [Nom Client], votre commande est prête. Livraison prévue.')
      .replace('[Nom Client]', customerName);

    // WhatsApp (via API tiers ou Twilio)
    if (reminder?.whatsappEnabled) {
      this.logger.log(`Rappel WhatsApp envoyé à ${customerName}`);
      // Intégration WhatsApp Business API ici
    }

    await this.prisma.notification.create({
      data: {
        userId: artisan.userId,
        type: 'RAPPEL_LIVRAISON',
        title: `Rappel envoyé à ${customerName}`,
        body: message,
        data: { orderId, customerName },
        sentAt: new Date(),
      },
    });
  }

  private async sendPushNotification(
    token: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ) {
    try {
      await admin.messaging().send({
        token,
        notification: { title, body },
        data,
        android: {
          priority: 'high',
          notification: { sound: 'default', channelId: 'ndokete_orders' },
        },
      });
    } catch (error) {
      this.logger.error('Erreur push notification Firebase', error);
    }
  }
}
