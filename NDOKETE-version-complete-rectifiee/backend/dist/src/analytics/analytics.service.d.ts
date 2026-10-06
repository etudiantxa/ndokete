import { PrismaService } from '../common/prisma/prisma.service';
export declare class AnalyticsService {
    private prisma;
    constructor(prisma: PrismaService);
    getArtisanKPIs(artisanId: string): Promise<{
        monthlyRevenue: number;
        revenueGrowth: number;
        activeOrders: number;
        activeCustomers: number;
        avgOrderValue: number;
    }>;
    getAdminKPIs(): Promise<{
        totalArtisans: number;
        premiumArtisans: number;
        freePct: number;
        totalCommissions: number;
        mrr: number;
        churnRisk: number;
    }>;
}
