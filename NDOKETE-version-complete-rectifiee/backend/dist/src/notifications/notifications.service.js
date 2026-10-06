"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var NotificationsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../common/prisma/prisma.service");
const config_1 = require("@nestjs/config");
const notifications_gateway_1 = require("./notifications.gateway");
const admin = require("firebase-admin");
let NotificationsService = NotificationsService_1 = class NotificationsService {
    constructor(prisma, config, gateway) {
        this.prisma = prisma;
        this.config = config;
        this.gateway = gateway;
        this.logger = new common_1.Logger(NotificationsService_1.name);
        if (!admin.apps.length) {
            admin.initializeApp({
                credential: admin.credential.cert({
                    projectId: config.get('FIREBASE_PROJECT_ID'),
                    privateKey: config.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
                    clientEmail: config.get('FIREBASE_CLIENT_EMAIL'),
                }),
            });
        }
    }
    async getAll(userId, unreadOnly = false) {
        return this.prisma.notification.findMany({
            where: { userId, ...(unreadOnly && { isRead: false }) },
            orderBy: { createdAt: 'desc' },
            take: 50,
        });
    }
    async markAsRead(userId, notificationId) {
        await this.prisma.notification.updateMany({
            where: { id: notificationId, userId },
            data: { isRead: true },
        });
        return { message: 'Notification marquée comme lue' };
    }
    async markAllAsRead(userId) {
        await this.prisma.notification.updateMany({
            where: { userId, isRead: false },
            data: { isRead: true },
        });
        return { message: 'Toutes les notifications marquées comme lues' };
    }
    async sendOrderNotification(artisanId, orderId, type) {
        const artisan = await this.prisma.artisan.findUnique({
            where: { id: artisanId },
            include: { user: true },
        });
        if (!artisan)
            return;
        const titles = {
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
        if (artisan.user.fcmToken) {
            await this.sendPushNotification(artisan.user.fcmToken, notification.title, notification.body, { orderId, type });
        }
        this.gateway.sendToUser(artisan.userId, 'notification', notification);
    }
    async sendDeliveryReminder(artisanId, customerName, orderId) {
        const artisan = await this.prisma.artisan.findUnique({
            where: { id: artisanId },
            include: { user: true, autoReminders: true },
        });
        if (!artisan)
            return;
        const reminder = artisan.autoReminders;
        const message = (reminder?.messageTemplate ?? 'Bonjour [Nom Client], votre commande est prête. Livraison prévue.')
            .replace('[Nom Client]', customerName);
        if (reminder?.whatsappEnabled) {
            this.logger.log(`Rappel WhatsApp envoyé à ${customerName}`);
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
    async sendPushNotification(token, title, body, data) {
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
        }
        catch (error) {
            this.logger.error('Erreur push notification Firebase', error);
        }
    }
};
exports.NotificationsService = NotificationsService;
exports.NotificationsService = NotificationsService = NotificationsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        config_1.ConfigService,
        notifications_gateway_1.NotificationsGateway])
], NotificationsService);
//# sourceMappingURL=notifications.service.js.map