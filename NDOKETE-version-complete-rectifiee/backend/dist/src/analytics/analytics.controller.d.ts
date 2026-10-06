import { AnalyticsService } from './analytics.service';
export declare class AnalyticsController {
    private analyticsService;
    constructor(analyticsService: AnalyticsService);
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
