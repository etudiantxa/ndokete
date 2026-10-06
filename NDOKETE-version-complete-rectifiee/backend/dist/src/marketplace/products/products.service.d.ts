import { PrismaService } from '../../common/prisma/prisma.service';
export declare class CreateProductDto {
    name: string;
    description?: string;
    price: number;
    category: string;
    photos: string[];
    stock: number;
    tags?: string[];
    isVitrine?: boolean;
}
export declare class ProductsService {
    private prisma;
    constructor(prisma: PrismaService);
    getMarketplace(search?: string, category?: string, page?: number, limit?: number): Promise<{
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
    getArtisanProducts(artisanId: string): Promise<{
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
    getProductById(productId: string): Promise<{
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
    update(artisanId: string, productId: string, dto: Partial<CreateProductDto>): Promise<{
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
    remove(artisanId: string, productId: string): Promise<{
        message: string;
    }>;
    getProductStats(artisanId: string): Promise<{
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
}
