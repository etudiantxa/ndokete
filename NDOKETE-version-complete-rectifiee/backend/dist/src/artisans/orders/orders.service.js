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
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrdersService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../common/prisma/prisma.service");
let OrdersService = class OrdersService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(artisanId, status, search) {
        return this.prisma.order.findMany({
            where: {
                artisanId,
                ...(status && { status }),
                ...(search && {
                    OR: [
                        { title: { contains: search, mode: 'insensitive' } },
                        { customer: { name: { contains: search, mode: 'insensitive' } } },
                    ],
                }),
            },
            include: {
                customer: { select: { id: true, name: true, phone: true, isVip: true } },
                payments: { select: { id: true, amount: true, status: true, method: true } },
                transaction: { select: { id: true } },
            },
            orderBy: [{ isUrgent: 'desc' }, { dueDate: 'asc' }, { createdAt: 'desc' }],
        });
    }
    async findOne(artisanId, orderId) {
        const order = await this.prisma.order.findFirst({
            where: { id: orderId, artisanId },
            include: {
                customer: true,
                payments: true,
            },
        });
        if (!order)
            throw new common_1.NotFoundException('Commande non trouvée');
        return order;
    }
    async create(artisanId, dto) {
        const customer = await this.prisma.customer.findFirst({
            where: { id: dto.customerId, artisanId },
        });
        if (!customer)
            throw new common_1.NotFoundException('Client non trouvé');
        const count = await this.prisma.order.count({ where: { artisanId } });
        const orderNumber = `CMD-${Date.now()}-${count + 1}`;
        const order = await this.prisma.order.create({
            data: {
                artisanId,
                customerId: dto.customerId,
                title: dto.title,
                description: dto.description,
                amount: dto.amount,
                deposit: dto.deposit ?? 0,
                dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
                isUrgent: dto.isUrgent ?? false,
                notes: dto.notes,
                orderNumber,
                localId: dto.localId,
                syncStatus: 'SYNCED',
            },
            include: { customer: true },
        });
        await this.prisma.customer.update({
            where: { id: dto.customerId },
            data: { totalOrders: { increment: 1 }, lastOrderAt: new Date() },
        });
        return { data: order, message: 'Commande créée avec succès' };
    }
    async update(artisanId, orderId, dto) {
        const order = await this.prisma.order.findFirst({
            where: { id: orderId, artisanId },
        });
        if (!order)
            throw new common_1.NotFoundException('Commande non trouvée');
        const progressByStatus = {
            EN_ATTENTE: 0,
            EN_COURS: 35,
            PRET: 80,
            LIVRE: 100,
            ANNULE: 0,
        };
        const statusProgress = dto.status ? progressByStatus[dto.status] : undefined;
        const updated = await this.prisma.order.update({
            where: { id: orderId },
            data: {
                ...(dto.title && { title: dto.title }),
                ...(dto.status && { status: dto.status }),
                ...(dto.progressPct !== undefined && { progressPct: dto.progressPct }),
                ...(dto.progressPct === undefined && statusProgress !== undefined && {
                    progressPct: statusProgress,
                }),
                ...(dto.dueDate && { dueDate: new Date(dto.dueDate) }),
                ...(dto.notes !== undefined && { notes: dto.notes }),
                ...(dto.isUrgent !== undefined && { isUrgent: dto.isUrgent }),
                ...(dto.status === 'LIVRE' && { deliveredAt: new Date() }),
                ...(dto.status && dto.status !== 'LIVRE' && { deliveredAt: null }),
            },
            include: { customer: true },
        });
        return { data: updated, message: 'Commande mise à jour' };
    }
    async remove(artisanId, orderId) {
        const order = await this.prisma.order.findFirst({
            where: { id: orderId, artisanId },
            select: { id: true, customerId: true },
        });
        if (!order)
            throw new common_1.NotFoundException('Commande non trouvée');
        await this.prisma.$transaction(async (tx) => {
            await tx.transaction.updateMany({
                where: { orderId },
                data: { orderId: null },
            });
            await tx.payment.deleteMany({ where: { orderId } });
            await tx.order.delete({ where: { id: orderId } });
            await tx.customer.updateMany({
                where: { id: order.customerId, artisanId, totalOrders: { gt: 0 } },
                data: { totalOrders: { decrement: 1 } },
            });
        });
        return { message: 'Commande supprimée' };
    }
    async getUrgentOrders(artisanId) {
        const threeDaysFromNow = new Date();
        threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);
        return this.prisma.order.findMany({
            where: {
                artisanId,
                status: { in: ['EN_ATTENTE', 'EN_COURS'] },
                OR: [
                    { isUrgent: true },
                    { dueDate: { lte: threeDaysFromNow } },
                ],
            },
            include: { customer: true },
            orderBy: { dueDate: 'asc' },
        });
    }
    async sendBulkReminders(artisanId) {
        const urgentOrders = await this.getUrgentOrders(artisanId);
        return { data: urgentOrders, message: `${urgentOrders.length} rappels envoyés` };
    }
};
exports.OrdersService = OrdersService;
exports.OrdersService = OrdersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], OrdersService);
//# sourceMappingURL=orders.service.js.map