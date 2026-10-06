import { PrismaService } from '../../common/prisma/prisma.service';
import { CreateOrderDto, UpdateOrderDto } from '../dto/create-order.dto';
import { OrderStatus } from '@prisma/client';
export declare class OrdersService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(artisanId: string, status?: OrderStatus, search?: string): Promise<({
        customer: {
            id: string;
            phone: string;
            name: string;
            isVip: boolean;
        };
        transaction: {
            id: string;
        } | null;
        payments: {
            id: string;
            status: import(".prisma/client").$Enums.PaymentStatus;
            amount: number;
            method: import(".prisma/client").$Enums.PaymentMethod;
        }[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        description: string | null;
        status: import(".prisma/client").$Enums.OrderStatus;
        artisanId: string;
        notes: string | null;
        isUrgent: boolean;
        title: string;
        amount: number;
        orderNumber: string;
        customerId: string;
        deposit: number;
        dueDate: Date | null;
        deliveredAt: Date | null;
        photos: string[];
        progressPct: number;
        localId: string | null;
        syncStatus: import(".prisma/client").$Enums.SyncStatus;
    })[]>;
    findOne(artisanId: string, orderId: string): Promise<{
        customer: {
            id: string;
            email: string | null;
            phone: string;
            createdAt: Date;
            updatedAt: Date;
            totalOrders: number;
            name: string;
            artisanId: string;
            address: string | null;
            notes: string | null;
            isVip: boolean;
            totalSpent: number;
            lastOrderAt: Date | null;
            measurements: import("@prisma/client/runtime/library").JsonValue | null;
        };
        payments: {
            id: string;
            createdAt: Date;
            status: import(".prisma/client").$Enums.PaymentStatus;
            amount: number;
            orderId: string | null;
            marketplaceOrderId: string | null;
            method: import(".prisma/client").$Enums.PaymentMethod;
            reference: string | null;
            webhookData: import("@prisma/client/runtime/library").JsonValue | null;
            commission: number;
            commissionPct: number;
            paidAt: Date | null;
        }[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        description: string | null;
        status: import(".prisma/client").$Enums.OrderStatus;
        artisanId: string;
        notes: string | null;
        isUrgent: boolean;
        title: string;
        amount: number;
        orderNumber: string;
        customerId: string;
        deposit: number;
        dueDate: Date | null;
        deliveredAt: Date | null;
        photos: string[];
        progressPct: number;
        localId: string | null;
        syncStatus: import(".prisma/client").$Enums.SyncStatus;
    }>;
    create(artisanId: string, dto: CreateOrderDto): Promise<{
        data: {
            customer: {
                id: string;
                email: string | null;
                phone: string;
                createdAt: Date;
                updatedAt: Date;
                totalOrders: number;
                name: string;
                artisanId: string;
                address: string | null;
                notes: string | null;
                isVip: boolean;
                totalSpent: number;
                lastOrderAt: Date | null;
                measurements: import("@prisma/client/runtime/library").JsonValue | null;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            description: string | null;
            status: import(".prisma/client").$Enums.OrderStatus;
            artisanId: string;
            notes: string | null;
            isUrgent: boolean;
            title: string;
            amount: number;
            orderNumber: string;
            customerId: string;
            deposit: number;
            dueDate: Date | null;
            deliveredAt: Date | null;
            photos: string[];
            progressPct: number;
            localId: string | null;
            syncStatus: import(".prisma/client").$Enums.SyncStatus;
        };
        message: string;
    }>;
    update(artisanId: string, orderId: string, dto: UpdateOrderDto): Promise<{
        data: {
            customer: {
                id: string;
                email: string | null;
                phone: string;
                createdAt: Date;
                updatedAt: Date;
                totalOrders: number;
                name: string;
                artisanId: string;
                address: string | null;
                notes: string | null;
                isVip: boolean;
                totalSpent: number;
                lastOrderAt: Date | null;
                measurements: import("@prisma/client/runtime/library").JsonValue | null;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            description: string | null;
            status: import(".prisma/client").$Enums.OrderStatus;
            artisanId: string;
            notes: string | null;
            isUrgent: boolean;
            title: string;
            amount: number;
            orderNumber: string;
            customerId: string;
            deposit: number;
            dueDate: Date | null;
            deliveredAt: Date | null;
            photos: string[];
            progressPct: number;
            localId: string | null;
            syncStatus: import(".prisma/client").$Enums.SyncStatus;
        };
        message: string;
    }>;
    remove(artisanId: string, orderId: string): Promise<{
        message: string;
    }>;
    getUrgentOrders(artisanId: string): Promise<({
        customer: {
            id: string;
            email: string | null;
            phone: string;
            createdAt: Date;
            updatedAt: Date;
            totalOrders: number;
            name: string;
            artisanId: string;
            address: string | null;
            notes: string | null;
            isVip: boolean;
            totalSpent: number;
            lastOrderAt: Date | null;
            measurements: import("@prisma/client/runtime/library").JsonValue | null;
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        description: string | null;
        status: import(".prisma/client").$Enums.OrderStatus;
        artisanId: string;
        notes: string | null;
        isUrgent: boolean;
        title: string;
        amount: number;
        orderNumber: string;
        customerId: string;
        deposit: number;
        dueDate: Date | null;
        deliveredAt: Date | null;
        photos: string[];
        progressPct: number;
        localId: string | null;
        syncStatus: import(".prisma/client").$Enums.SyncStatus;
    })[]>;
    sendBulkReminders(artisanId: string): Promise<{
        data: ({
            customer: {
                id: string;
                email: string | null;
                phone: string;
                createdAt: Date;
                updatedAt: Date;
                totalOrders: number;
                name: string;
                artisanId: string;
                address: string | null;
                notes: string | null;
                isVip: boolean;
                totalSpent: number;
                lastOrderAt: Date | null;
                measurements: import("@prisma/client/runtime/library").JsonValue | null;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            description: string | null;
            status: import(".prisma/client").$Enums.OrderStatus;
            artisanId: string;
            notes: string | null;
            isUrgent: boolean;
            title: string;
            amount: number;
            orderNumber: string;
            customerId: string;
            deposit: number;
            dueDate: Date | null;
            deliveredAt: Date | null;
            photos: string[];
            progressPct: number;
            localId: string | null;
            syncStatus: import(".prisma/client").$Enums.SyncStatus;
        })[];
        message: string;
    }>;
}
