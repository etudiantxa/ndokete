import { PrismaService } from '../../common/prisma/prisma.service';
export declare class CreateMarketplaceOrderDto {
    items: Array<{
        productId: string;
        quantity: number;
    }>;
    address?: string;
    notes?: string;
}
export declare class MarketplaceOrderItemDto {
    productId: string;
    quantity: number;
}
export declare class MarketplaceOrdersService {
    private prisma;
    constructor(prisma: PrismaService);
    createOrder(userId: string, dto: CreateMarketplaceOrderDto): Promise<{
        data: {
            items: ({
                product: {
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
                };
            } & {
                id: string;
                artisanId: string;
                quantity: number;
                marketplaceOrderId: string;
                unitPrice: number;
                productId: string;
            })[];
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            status: import(".prisma/client").$Enums.OrderStatus;
            address: string | null;
            notes: string | null;
            orderNumber: string;
            clientId: string;
            totalAmount: number;
        };
        message: string;
        totalAmount: number;
    }>;
    getClientOrders(userId: string): Promise<({
        items: ({
            product: {
                artisan: {
                    businessName: string;
                };
            } & {
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
            };
        } & {
            id: string;
            artisanId: string;
            quantity: number;
            marketplaceOrderId: string;
            unitPrice: number;
            productId: string;
        })[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.OrderStatus;
        address: string | null;
        notes: string | null;
        orderNumber: string;
        clientId: string;
        totalAmount: number;
    })[]>;
}
