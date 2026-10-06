import { StockService, CreateStockItemDto, AdjustStockDto } from './stock.service';
export declare class StockController {
    private stockService;
    constructor(stockService: StockService);
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
    findOne(artisanId: string, id: string): Promise<{
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
    adjust(artisanId: string, id: string, dto: AdjustStockDto): Promise<{
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
    update(artisanId: string, id: string, dto: Partial<CreateStockItemDto>): Promise<{
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
    remove(artisanId: string, id: string): Promise<{
        message: string;
    }>;
}
