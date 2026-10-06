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
exports.ArtisansService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../common/prisma/prisma.service");
let ArtisansService = class ArtisansService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getProfile(artisanId) {
        const artisan = await this.prisma.artisan.findUnique({
            where: { id: artisanId },
            include: {
                user: { select: { email: true, phone: true } },
                subscription: true,
                analytics: true,
                autoReminders: true,
                _count: { select: { customers: true, orders: true, products: true } },
            },
        });
        if (!artisan)
            throw new common_1.NotFoundException('Artisan non trouvé');
        return artisan;
    }
    async getDashboard(artisanId) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const [todaySales, activeOrders, avgRating, recentOrders, stockAlerts] = await Promise.all([
            this.prisma.transaction.aggregate({
                where: {
                    artisanId,
                    type: 'ENTREE',
                    date: { gte: today },
                },
                _sum: { amount: true },
            }),
            this.prisma.order.count({
                where: { artisanId, status: { in: ['EN_ATTENTE', 'EN_COURS'] } },
            }),
            this.prisma.review.aggregate({
                where: { artisanId },
                _avg: { rating: true },
            }),
            this.prisma.order.findMany({
                where: { artisanId },
                orderBy: { createdAt: 'desc' },
                take: 5,
                include: { customer: { select: { name: true } } },
            }),
            this.prisma.stockItem.findMany({
                where: { artisanId },
                select: { id: true, name: true, quantity: true, alertThreshold: true, unit: true },
            }).then((items) => items.filter((i) => i.quantity <= i.alertThreshold)),
        ]);
        return {
            todaySales: todaySales._sum.amount ?? 0,
            activeOrders,
            avgRating: Math.round((avgRating._avg.rating ?? 0) * 10) / 10,
            recentOrders,
            stockAlerts: stockAlerts.slice(0, 3),
        };
    }
    async updateProfile(artisanId, data) {
        const { autoReminders, ...artisanData } = data;
        const updated = await this.prisma.$transaction(async (tx) => {
            const artisan = await tx.artisan.update({
                where: { id: artisanId },
                data: artisanData,
            });
            if (autoReminders) {
                await tx.autoReminder.upsert({
                    where: { artisanId },
                    create: { artisanId, ...autoReminders },
                    update: autoReminders,
                });
            }
            return artisan;
        });
        return { data: updated, message: 'Profil mis à jour' };
    }
    async getPublicProfile(artisanId) {
        const artisan = await this.prisma.artisan.findUnique({
            where: { id: artisanId, isPublic: true },
            include: {
                products: { where: { status: 'ACTIF' }, take: 12 },
                reviews: {
                    orderBy: { createdAt: 'desc' },
                    take: 10,
                    include: { client: { include: { user: { select: { email: true } } } } },
                },
                _count: { select: { orders: true, customers: true } },
            },
        });
        if (!artisan)
            throw new common_1.NotFoundException('Artisan non trouvé');
        return artisan;
    }
};
exports.ArtisansService = ArtisansService;
exports.ArtisansService = ArtisansService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ArtisansService);
//# sourceMappingURL=artisans.service.js.map