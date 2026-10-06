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
exports.MarketplaceOrdersService = exports.MarketplaceOrderItemDto = exports.CreateMarketplaceOrderDto = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../common/prisma/prisma.service");
const class_validator_1 = require("class-validator");
const class_transformer_1 = require("class-transformer");
class CreateMarketplaceOrderDto {
}
exports.CreateMarketplaceOrderDto = CreateMarketplaceOrderDto;
__decorate([
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.ValidateNested)({ each: true }),
    (0, class_transformer_1.Type)(() => MarketplaceOrderItemDto),
    __metadata("design:type", Array)
], CreateMarketplaceOrderDto.prototype, "items", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateMarketplaceOrderDto.prototype, "address", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateMarketplaceOrderDto.prototype, "notes", void 0);
class MarketplaceOrderItemDto {
}
exports.MarketplaceOrderItemDto = MarketplaceOrderItemDto;
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], MarketplaceOrderItemDto.prototype, "productId", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], MarketplaceOrderItemDto.prototype, "quantity", void 0);
let MarketplaceOrdersService = class MarketplaceOrdersService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createOrder(userId, dto) {
        const client = await this.prisma.client.findUnique({ where: { userId } });
        if (!client)
            throw new common_1.NotFoundException('Profil client non trouvé');
        if (dto.items.length === 0) {
            throw new common_1.BadRequestException('La commande doit contenir au moins un produit');
        }
        const uniqueProductIds = new Set(dto.items.map((item) => item.productId));
        if (uniqueProductIds.size !== dto.items.length) {
            throw new common_1.BadRequestException('Un produit ne peut apparaître qu’une seule fois');
        }
        const productIds = dto.items.map((i) => i.productId);
        const products = await this.prisma.product.findMany({
            where: { id: { in: productIds }, status: 'ACTIF' },
        });
        let totalAmount = 0;
        const orderItems = dto.items.map((item) => {
            const product = products.find((p) => p.id === item.productId);
            if (!product)
                throw new common_1.BadRequestException(`Produit ${item.productId} non disponible`);
            if (product.stock < item.quantity) {
                throw new common_1.BadRequestException(`Stock insuffisant pour ${product.name}`);
            }
            const lineTotal = product.price * item.quantity;
            totalAmount += lineTotal;
            return {
                productId: item.productId,
                quantity: item.quantity,
                unitPrice: product.price,
                artisanId: product.artisanId,
            };
        });
        const orderNumber = `MKT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
        const order = await this.prisma.$transaction(async (tx) => {
            for (const item of dto.items) {
                const reserved = await tx.product.updateMany({
                    where: { id: item.productId, status: 'ACTIF', stock: { gte: item.quantity } },
                    data: { stock: { decrement: item.quantity }, orderCount: { increment: 1 } },
                });
                if (reserved.count !== 1) {
                    throw new common_1.BadRequestException('Le stock a changé, veuillez réessayer');
                }
            }
            return tx.marketplaceOrder.create({
                data: {
                    clientId: client.id,
                    orderNumber,
                    totalAmount,
                    address: dto.address,
                    notes: dto.notes,
                    items: { createMany: { data: orderItems } },
                },
                include: { items: { include: { product: true } } },
            });
        });
        return { data: order, message: 'Commande marketplace créée', totalAmount };
    }
    async getClientOrders(userId) {
        const client = await this.prisma.client.findUnique({ where: { userId } });
        if (!client)
            throw new common_1.NotFoundException('Profil client non trouvé');
        return this.prisma.marketplaceOrder.findMany({
            where: { clientId: client.id },
            include: {
                items: {
                    include: {
                        product: {
                            include: { artisan: { select: { businessName: true } } },
                        },
                    },
                },
            },
            orderBy: { createdAt: 'desc' },
        });
    }
};
exports.MarketplaceOrdersService = MarketplaceOrdersService;
exports.MarketplaceOrdersService = MarketplaceOrdersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], MarketplaceOrdersService);
//# sourceMappingURL=marketplace-orders.service.js.map