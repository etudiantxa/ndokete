import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';

export class SyncPayloadDto {
  // Liste d'opérations en attente enregistrées sur Hive (offline)
  operations: Array<{
    entity: string;       // 'order' | 'customer' | 'transaction' | 'stock'
    action: string;       // 'create' | 'update' | 'delete'
    localId: string;      // ID Hive local
    payload: any;         // Données de l'entité
    createdAt: string;    // Timestamp de création locale
  }>;
}

@Injectable()
export class SyncService {
  private readonly logger = new Logger(SyncService.name);

  constructor(private prisma: PrismaService) {}

  // Traitement des opérations offline en attente
  async processSyncBatch(artisanId: string, dto: SyncPayloadDto) {
    const results: Array<{
      localId: string;
      serverId?: string;
      status: string;
      error?: string;
    }> = [];

    for (const op of dto.operations) {
      try {
        const serverId = await this.processOperation(artisanId, op);
        results.push({ localId: op.localId, serverId, status: 'SYNCED' });

        // Enregistrer dans la queue pour audit
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
      } catch (error) {
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

  private async processOperation(artisanId: string, op: any): Promise<string> {
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

  async getPendingConflicts(artisanId: string) {
    return this.prisma.syncQueue.findMany({
      where: { artisanId, status: 'CONFLICT' },
      orderBy: { createdAt: 'desc' },
    });
  }
}
