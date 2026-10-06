import { PrismaService } from '../common/prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { NotificationsGateway } from './notifications.gateway';
import { NotificationType } from '@prisma/client';
export declare class NotificationsService {
    private prisma;
    private config;
    private gateway;
    private readonly logger;
    constructor(prisma: PrismaService, config: ConfigService, gateway: NotificationsGateway);
    getAll(userId: string, unreadOnly?: boolean): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        data: import("@prisma/client/runtime/library").JsonValue | null;
        type: import(".prisma/client").$Enums.NotificationType;
        title: string;
        channel: import(".prisma/client").$Enums.NotificationChannel;
        body: string;
        isRead: boolean;
        sentAt: Date | null;
    }[]>;
    markAsRead(userId: string, notificationId: string): Promise<{
        message: string;
    }>;
    markAllAsRead(userId: string): Promise<{
        message: string;
    }>;
    sendOrderNotification(artisanId: string, orderId: string, type: NotificationType): Promise<void>;
    sendDeliveryReminder(artisanId: string, customerName: string, orderId: string): Promise<void>;
    private sendPushNotification;
}
