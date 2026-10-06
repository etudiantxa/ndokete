import { ProductsService, CreateProductDto } from './products.service';
export declare class ProductsController {
    private productsService;
    constructor(productsService: ProductsService);
    getMarketplace(search?: string, category?: string, page?: number): Promise<{
        data: ({
            artisan: {
                id: string;
                businessName: string;
                quarter: string;
                profilePhoto: string | null;
                rating: number;
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
        })[];
        meta: {
            total: number;
            page: number;
            limit: number;
            totalPages: number;
        };
    }>;
    getMyShop(artisanId: string): Promise<{
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
    }[]>;
    getStats(artisanId: string): Promise<{
        products: {
            id: string;
            status: import(".prisma/client").$Enums.ProductStatus;
            price: number;
            name: string;
            viewCount: number;
            orderCount: number;
        }[];
        totalRevenue: number;
        conversionRate: number;
    }>;
    create(artisanId: string, dto: CreateProductDto): Promise<{
        data: {
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
        message: string;
    }>;
    update(artisanId: string, id: string, dto: Partial<CreateProductDto>): Promise<{
        data: {
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
        message: string;
    }>;
    remove(artisanId: string, id: string): Promise<{
        message: string;
    }>;
    getProduct(id: string): Promise<{
        artisan: {
            id: string;
            businessName: string;
            quarter: string;
            profilePhoto: string | null;
            rating: number;
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
    }>;
}
