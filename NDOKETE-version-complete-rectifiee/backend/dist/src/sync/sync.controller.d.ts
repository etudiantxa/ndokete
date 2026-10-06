import { SyncService, SyncPayloadDto } from './sync.service';
export declare class SyncController {
    private syncService;
    constructor(syncService: SyncService);
    processBatch(artisanId: string, dto: SyncPayloadDto): Promise<{
        data: {
            localId: string;
            serverId?: string;
            status: string;
            error?: string;
        }[];
        message: string;
    }>;
    getConflicts(artisanId: string): Promise<{
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
