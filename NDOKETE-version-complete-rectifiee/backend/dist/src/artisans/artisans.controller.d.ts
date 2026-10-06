import { ArtisansService } from './artisans.service';
export declare class ArtisansController {
    private artisansService;
    constructor(artisansService: ArtisansService);
    getProfile(artisanId: string): Promise<{
        analytics: {
            id: string;
            updatedAt: Date;
            totalRevenue: number;
            totalOrders: number;
            totalCustomers: number;
            totalProducts: number;
            mrr: number;
            avgOrderValue: number;
            artisanId: string;
        } | null;
        autoReminders: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            whatsappEnabled: boolean;
            smsEnabled: boolean;
            hoursBeforeDelivery: number;
            messageTemplate: string | null;
            artisanId: string;
        } | null;
        subscription: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            plan: import(".prisma/client").$Enums.SubscriptionPlan;
            status: import(".prisma/client").$Enums.SubscriptionStatus;
            startDate: Date;
            endDate: Date | null;
            price: number;
            paymentRef: string | null;
            artisanId: string;
        } | null;
        user: {
            email: string;
            phone: string;
        };
        _count: {
            customers: number;
            orders: number;
            products: number;
        };
    } & {
        id: string;
        isVerified: boolean;
        createdAt: Date;
        updatedAt: Date;
        businessName: string;
        specialty: string[];
        description: string | null;
        quarter: string;
        city: string;
        latitude: number | null;
        longitude: number | null;
        profilePhoto: string | null;
        coverPhoto: string | null;
        waveNumber: string | null;
        orangeMoneyNumber: string | null;
        rating: number;
        reviewCount: number;
        qrCode: string | null;
        shareUrl: string | null;
        isPublic: boolean;
        userId: string;
    }>;
    getDashboard(artisanId: string): Promise<{
        todaySales: number;
        activeOrders: number;
        avgRating: number;
        recentOrders: ({
            customer: {
                name: string;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            description: string | null;
            status: import(".prisma/client").$Enums.OrderStatus;
            artisanId: string;
            notes: string | null;
            isUrgent: boolean;
            title: string;
            amount: number;
            orderNumber: string;
            customerId: string;
            deposit: number;
            dueDate: Date | null;
            deliveredAt: Date | null;
            photos: string[];
            progressPct: number;
            localId: string | null;
            syncStatus: import(".prisma/client").$Enums.SyncStatus;
        })[];
        stockAlerts: {
            id: string;
            name: string;
            unit: string;
            quantity: number;
            alertThreshold: number;
        }[];
    }>;
    updateProfile(artisanId: string, body: any): Promise<{
        data: {
            id: string;
            isVerified: boolean;
            createdAt: Date;
            updatedAt: Date;
            businessName: string;
            specialty: string[];
            description: string | null;
            quarter: string;
            city: string;
            latitude: number | null;
            longitude: number | null;
            profilePhoto: string | null;
            coverPhoto: string | null;
            waveNumber: string | null;
            orangeMoneyNumber: string | null;
            rating: number;
            reviewCount: number;
            qrCode: string | null;
            shareUrl: string | null;
            isPublic: boolean;
            userId: string;
        };
        message: string;
    }>;
    getPublicProfile(id: string): Promise<{
        products: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            description: string | null;
            status: import(".prisma/client").$Enums.ProductStatus;
            price: number;
            name: string;
            artisanId: string;
            tags: string[];
            photos: string[];
            category: string;
            stock: number;
            isVitrine: boolean;
            viewCount: number;
            orderCount: number;
        }[];
        reviews: ({
            client: {
                user: {
                    email: string;
                };
            } & {
                id: string;
                createdAt: Date;
                userId: string;
            };
        } & {
            id: string;
            createdAt: Date;
            rating: number;
            artisanId: string;
            marketplaceOrderId: string | null;
            clientId: string;
            comment: string | null;
            isVisible: boolean;
        })[];
        _count: {
            customers: number;
            orders: number;
        };
    } & {
        id: string;
        isVerified: boolean;
        createdAt: Date;
        updatedAt: Date;
        businessName: string;
        specialty: string[];
        description: string | null;
        quarter: string;
        city: string;
        latitude: number | null;
        longitude: number | null;
        profilePhoto: string | null;
        coverPhoto: string | null;
        waveNumber: string | null;
        orangeMoneyNumber: string | null;
        rating: number;
        reviewCount: number;
        qrCode: string | null;
        shareUrl: string | null;
        isPublic: boolean;
        userId: string;
    }>;
}
