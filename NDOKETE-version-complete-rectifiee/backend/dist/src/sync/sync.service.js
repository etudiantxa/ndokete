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
var SyncService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SyncService = exports.SyncPayloadDto = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../common/prisma/prisma.service");
class SyncPayloadDto {
}
exports.SyncPayloadDto = SyncPayloadDto;
let SyncService = SyncService_1 = class SyncService {
    constructor(prisma) {
        this.prisma = prisma;
        this.logger = new common_1.Logger(SyncService_1.name);
    }
    async processSyncBatch(artisanId, dto) {
        const results = [];
        for (const op of dto.operations) {
            try {
                const serverId = await this.processOperation(artisanId, op);
                results.push({ localId: op.localId, serverId, status: 'SYNCED' });
                await this.prisma.syncQueue.create({
                    data: {
                        artisanId,
                        entity: op.entity,
                        localId: op.localId,
                        action: op.action,
                        payload: op.payload,
                        status: 'SYNCED',
                        processedAt: new Date(),
                    },
                });
            }
            catch (error) {
                this.logger.error(`Erreur sync ${op.entity}/${op.localId}:`, error);
                results.push({
                    localId: op.localId,
                    status: 'FAILED',
                    error: error instanceof Error ? error.message : 'Erreur inconnue',
                });
                await this.prisma.syncQueue.create({
                    data: {
                        artisanId,
                        entity: op.entity,
                        localId: op.localId,
                        action: op.action,
                        payload: op.payload,
                        status: 'FAILED',
                        error: error instanceof Error ? error.message : 'Erreur inconnue',
                        retries: 1,
                    },
                });
            }
        }
        return {
            data: results,
            message: `${results.filter((r) => r.status === 'SYNCED').length}/${dto.operations.length} opérations synchronisées`,
        };
    }
    async processOperation(artisanId, op) {
        switch (`${op.entity}:${op.action}`) {
            case 'order:create': {
                const count = await this.prisma.order.count({ where: { artisanId } });
                const order = await this.prisma.order.create({
                    data: {
                        ...op.payload,
                        artisanId,
                        orderNumber: `CMD-${Date.now()}-${count + 1}`,
                        localId: op.localId,
                        syncStatus: 'SYNCED',
                        dueDate: op.payload.dueDate ? new Date(op.payload.dueDate) : undefined,
                    },
                });
                return order.id;
            }
            case 'order:update': {
                const order = await this.prisma.order.findFirst({
                    where: { localId: op.localId, artisanId },
                });
                if (order) {
                    await this.prisma.order.update({
                        where: { id: order.id },
                        data: { ...op.payload, syncStatus: 'SYNCED' },
                    });
                    return order.id;
                }
                throw new Error('Commande introuvable pour synchronisation');
            }
            case 'customer:create': {
                const customer = await this.prisma.customer.create({
                    data: { ...op.payload, artisanId },
                });
                return customer.id;
            }
            case 'transaction:create': {
                const transaction = await this.prisma.transaction.create({
                    data: {
                        ...op.payload,
                        artisanId,
                        localId: op.localId,
                        date: op.payload.date ? new Date(op.payload.date) : new Date(),
                        syncStatus: 'SYNCED',
                    },
                });
                return transaction.id;
            }
            case 'stock:adjust': {
                const item = await this.prisma.stockItem.findFirst({
                    where: { id: op.payload.stockItemId, artisanId },
                });
                if (item) {
                    await this.prisma.stockItem.update({
                        where: { id: item.id },
                        data: { quantity: op.payload.newQuantity },
                    });
                    return item.id;
                }
                throw new Error('Article de stock introuvable');
            }
            default:
                throw new Error(`Opération inconnue : ${op.entity}:${op.action}`);
        }
    }
    async getPendingConflicts(artisanId) {
        return this.prisma.syncQueue.findMany({
            where: { artisanId, status: 'CONFLICT' },
            orderBy: { createdAt: 'desc' },
        });
    }
};
exports.SyncService = SyncService;
exports.SyncService = SyncService = SyncService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SyncService);
//# sourceMappingURL=sync.service.js.map