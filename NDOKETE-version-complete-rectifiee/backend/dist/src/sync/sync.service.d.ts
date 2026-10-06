import { PrismaService } from '../common/prisma/prisma.service';
export declare class SyncPayloadDto {
    operations: Array<{
        entity: string;
        action: string;
        localId: string;
        payload: any;
        createdAt: string;
    }>;
}
export declare class SyncService {
    private prisma;
    private readonly logger;
    constructor(prisma: PrismaService);
    processSyncBatch(artisanId: string, dto: SyncPayloadDto): Promise<{
        data: {
            localId: string;
            serverId?: string;
            status: string;
            error?: string;
        }[];
        message: string;
    }>;
    private processOperation;
    getPendingConflicts(artisanId: string): Promise<{
        error: string | null;
        id: string;
        createdAt: Date;
        status: import(".prisma/client").$Enums.SyncStatus;
        artisanId: string;
        localId: string;
        entity: string;
        action: string;
        payload: import("@prisma/client/runtime/library").JsonValue;
        retries: number;
        processedAt: Date | null;
    }[]>;
}
