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
exports.ProductsService = exports.CreateProductDto = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../common/prisma/prisma.service");
const class_validator_1 = require("class-validator");
class CreateProductDto {
}
exports.CreateProductDto = CreateProductDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateProductDto.prototype, "name", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateProductDto.prototype, "description", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateProductDto.prototype, "price", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateProductDto.prototype, "category", void 0);
__decorate([
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], CreateProductDto.prototype, "photos", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateProductDto.prototype, "stock", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], CreateProductDto.prototype, "tags", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], CreateProductDto.prototype, "isVitrine", void 0);
let ProductsService = class ProductsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getMarketplace(search, category, page = 1, limit = 20) {
        const skip = (page - 1) * limit;
        const where = {
            status: 'ACTIF',
            ...(category && { category }),
            ...(search && {
                OR: [
                    { name: { contains: search, mode: 'insensitive' } },
                    { artisan: { businessName: { contains: search, mode: 'insensitive' } } },
                ],
            }),
        };
        const [products, total] = await Promise.all([
            this.prisma.product.findMany({
                where,
                include: {
                    artisan: {
                        select: { id: true, businessName: true, quarter: true, rating: true, profilePhoto: true },
                    },
                },
                orderBy: [{ isVitrine: 'desc' }, { viewCount: 'desc' }],
                skip,
                take: limit,
            }),
            this.prisma.product.count({ where }),
        ]);
        return { data: products, meta: { total, page, limit, totalPages: Math.ceil(total / limit) } };
    }
    async getArtisanProducts(artisanId) {
        return this.prisma.product.findMany({
            where: { artisanId },
            orderBy: { createdAt: 'desc' },
        });
    }
    async getProductById(productId) {
        const product = await this.prisma.product.findFirst({
            where: { id: productId, status: 'ACTIF' },
            include: {
                artisan: {
                    select: { id: true, businessName: true, quarter: true, rating: true, profilePhoto: true },
                },
            },
        });
        if (!product)
            throw new common_1.NotFoundException('Produit non trouvé');
        await this.prisma.product.update({
            where: { id: productId },
            data: { viewCount: { increment: 1 } },
        });
        return product;
    }
    async create(artisanId, dto) {
        const artisan = await this.prisma.artisan.findUnique({
            where: { id: artisanId },
            include: { subscription: true },
        });
        if (artisan?.subscription?.plan === 'FREE') {
            const count = await this.prisma.product.count({ where: { artisanId } });
            if (count >= 5) {
                throw new common_1.ForbiddenException('Limite de 5 produits atteinte sur le plan gratuit. Passez au Premium !');
            }
        }
        const product = await this.prisma.product.create({
            data: {
                artisanId,
                name: dto.name,
                description: dto.description,
                price: dto.price,
                category: dto.category,
                photos: dto.photos,
                stock: dto.stock,
                tags: dto.tags ?? [],
                isVitrine: dto.isVitrine ?? false,
            },
        });
        return { data: product, message: 'Produit créé' };
    }
    async update(artisanId, productId, dto) {
        const product = await this.prisma.product.findFirst({ where: { id: productId, artisanId } });
        if (!product)
            throw new common_1.NotFoundException('Produit non trouvé');
        const updated = await this.prisma.product.update({
            where: { id: productId },
            data: dto,
        });
        return { data: updated, message: 'Produit mis à jour' };
    }
    async remove(artisanId, productId) {
        const product = await this.prisma.product.findFirst({
            where: { id: productId, artisanId },
        });
        if (!product)
            throw new common_1.NotFoundException('Produit non trouvé');
        await this.prisma.product.delete({ where: { id: productId } });
        return { message: 'Produit supprimé' };
    }
    async getProductStats(artisanId) {
        const products = await this.prisma.product.findMany({
            where: { artisanId },
            select: {
                id: true, name: true, viewCount: true, orderCount: true, price: true, status: true,
            },
        });
        const totalRevenue = await this.prisma.marketplaceOrderItem.aggregate({
            where: { artisanId },
            _sum: { unitPrice: true, quantity: true },
        });
        return {
            products,
            totalRevenue: (totalRevenue._sum.unitPrice ?? 0) *
                (totalRevenue._sum.quantity ?? 0),
            conversionRate: products.length > 0
                ? Math.round((products.reduce((a, p) => a + p.orderCount, 0) /
                    Math.max(products.reduce((a, p) => a + p.viewCount, 0), 1)) * 100)
                : 0,
        };
    }
};
exports.ProductsService = ProductsService;
exports.ProductsService = ProductsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ProductsService);
//# sourceMappingURL=products.service.js.map