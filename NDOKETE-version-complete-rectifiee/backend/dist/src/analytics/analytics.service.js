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
exports.AnalyticsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../common/prisma/prisma.service");
let AnalyticsService = class AnalyticsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getArtisanKPIs(artisanId) {
        const now = new Date();
        const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
        const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0);
        const [currentRevenue, lastRevenue, totalOrders, activeCustomers, avgOrderValue] = await Promise.all([
            this.prisma.transaction.aggregate({
                where: { artisanId, type: 'ENTREE', date: { gte: monthStart } },
                _sum: { amount: true },
            }),
            this.prisma.transaction.aggregate({
                where: {
                    artisanId,
                    type: 'ENTREE',
                    date: { gte: lastMonthStart, lte: lastMonthEnd },
                },
                _sum: { amount: true },
            }),
            this.prisma.order.count({
                where: { artisanId, status: { in: ['EN_COURS', 'EN_ATTENTE'] } },
            }),
            this.prisma.customer.count({
                where: { artisanId, lastOrderAt: { gte: monthStart } },
            }),
            this.prisma.order.aggregate({
                where: { artisanId },
                _avg: { amount: true },
            }),
        ]);
        const currentRev = currentRevenue._sum.amount ?? 0;
        const lastRev = lastRevenue._sum.amount ?? 1;
        const growth = Math.round(((currentRev - lastRev) / lastRev) * 100);
        return {
            monthlyRevenue: currentRev,
            revenueGrowth: growth,
            activeOrders: totalOrders,
            activeCustomers,
            avgOrderValue: Math.round(avgOrderValue._avg.amount ?? 0),
        };
    }
    async getAdminKPIs() {
        const [totalArtisans, premiumArtisans, totalRevenue, churnRisk] = await Promise.all([
            this.prisma.artisan.count(),
            this.prisma.subscription.count({
                where: { plan: { in: ['PREMIUM', 'PREMIUM_PLUS'] }, status: 'ACTIVE' },
            }),
            this.prisma.payment.aggregate({
                where: { status: 'PAYE' },
                _sum: { commission: true },
            }),
            this.prisma.artisan.count({
                where: {
                    orders: {
                        none: {
                            createdAt: { gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
                        },
                    },
                },
            }),
        ]);
        const mrr = await this.prisma.subscription.aggregate({
            where: { status: 'ACTIVE' },
            _sum: { price: true },
        });
        return {
            totalArtisans,
            premiumArtisans,
            freePct: Math.round(((totalArtisans - premiumArtisans) / totalArtisans) * 100),
            totalCommissions: totalRevenue._sum.commission ?? 0,
            mrr: mrr._sum.price ?? 0,
            churnRisk,
        };
    }
};
exports.AnalyticsService = AnalyticsService;
exports.AnalyticsService = AnalyticsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AnalyticsService);
//# sourceMappingURL=analytics.service.js.map