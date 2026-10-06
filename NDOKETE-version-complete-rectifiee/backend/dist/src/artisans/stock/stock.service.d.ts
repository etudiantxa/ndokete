import { PrismaService } from '../../common/prisma/prisma.service';
import { StockMovementType } from '@prisma/client';
export declare class CreateStockItemDto {
    name: string;
    category: string;
    unit: string;
    quantity: number;
    alertThreshold?: number;
    costPerUnit?: number;
    supplier?: string;
    supplierPhone?: string;
    photo?: string;
}
export declare class AdjustStockDto {
    type: StockMovementType;
    quantity: number;
    reason?: string;
    orderId?: string;
}
export declare class StockService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(artisanId: string, category?: string, lowStock?: boolean): Promise<({
        movements: {
            id: string;
            createdAt: Date;
            type: import(".prisma/client").$Enums.StockMovementType;
            quantity: number;
            orderId: string | null;
            reason: string | null;
            stockItemId: string;
        }[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        artisanId: string;
        supplier: string | null;
        syncStatus: import(".prisma/client").$Enums.SyncStatus;
        category: string;
        unit: string;
        quantity: number;
        alertThreshold: number;
        costPerUnit: number;
        supplierPhone: string | null;
        photo: string | null;
    })[]>;
    findOne(artisanId: string, itemId: string): Promise<{
        movements: {
            id: string;
            createdAt: Date;
            type: import(".prisma/client").$Enums.StockMovementType;
            quantity: number;
            orderId: string | null;
            reason: string | null;
            stockItemId: string;
        }[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        artisanId: string;
        supplier: string | null;
        syncStatus: import(".prisma/client").$Enums.SyncStatus;
        category: string;
        unit: string;
        quantity: number;
        alertThreshold: number;
        costPerUnit: number;
        supplierPhone: string | null;
        photo: string | null;
    }>;
    create(artisanId: string, dto: CreateStockItemDto): Promise<{
        data: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            name: string;
            artisanId: string;
            supplier: string | null;
            syncStatus: import(".prisma/client").$Enums.SyncStatus;
            category: string;
            unit: string;
            quantity: number;
            alertThreshold: number;
            costPerUnit: number;
            supplierPhone: string | null;
            photo: string | null;
        };
        message: string;
    }>;
    adjustStock(artisanId: string, itemId: string, dto: AdjustStockDto): Promise<{
        data: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            name: string;
            artisanId: string;
            supplier: string | null;
            syncStatus: import(".prisma/client").$Enums.SyncStatus;
            category: string;
            unit: string;
            quantity: number;
            alertThreshold: number;
            costPerUnit: number;
            supplierPhone: string | null;
            photo: string | null;
        };
        message: string;
        alert: string | null;
    }>;
    getLowStockAlerts(artisanId: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        artisanId: string;
        supplier: string | null;
        syncStatus: import(".prisma/client").$Enums.SyncStatus;
        category: string;
        unit: string;
        quantity: number;
        alertThreshold: number;
        costPerUnit: number;
        supplierPhone: string | null;
        photo: string | null;
    }[]>;
    update(artisanId: string, itemId: string, dto: Partial<CreateStockItemDto>): Promise<{
        data: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            name: string;
            artisanId: string;
            supplier: string | null;
            syncStatus: import(".prisma/client").$Enums.SyncStatus;
            category: string;
            unit: string;
            quantity: number;
            alertThreshold: number;
            costPerUnit: number;
            supplierPhone: string | null;
            photo: string | null;
        };
        message: string;
    }>;
    remove(artisanId: string, itemId: string): Promise<{
        message: string;
    }>;
}
