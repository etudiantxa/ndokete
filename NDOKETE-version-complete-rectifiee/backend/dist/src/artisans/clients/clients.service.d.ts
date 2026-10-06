import { PrismaService } from '../../common/prisma/prisma.service';
export declare class CreateCustomerDto {
    name: string;
    phone: string;
    email?: string;
    address?: string;
    notes?: string;
    isVip?: boolean;
    measurements?: Record<string, any>;
    localId?: string;
}
export declare class ClientsService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(artisanId: string, search?: string): Promise<Record<string, unknown>[]>;
    findOne(artisanId: string, customerId: string): Promise<{
        totalOrders: number;
        orders: ({
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
        })[];
        id: string;
        email: string | null;
        phone: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        artisanId: string;
        address: string | null;
        notes: string | null;
        isVip: boolean;
        totalSpent: number;
        lastOrderAt: Date | null;
        measurements: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
    create(artisanId: string, dto: CreateCustomerDto): Promise<{
        data: {
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
        message: string;
    }>;
    update(artisanId: string, customerId: string, dto: Partial<CreateCustomerDto>): Promise<{
        data: {
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
        message: string;
    }>;
    updateMeasurements(artisanId: string, customerId: string, measurements: Record<string, any>): Promise<{
        data: {
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
        message: string;
    }>;
    remove(artisanId: string, customerId: string): Promise<{
        message: string;
        deletedOrders: number;
    }>;
}
