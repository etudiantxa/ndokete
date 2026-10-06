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
exports.StockService = exports.AdjustStockDto = exports.CreateStockItemDto = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../common/prisma/prisma.service");
const client_1 = require("@prisma/client");
const class_validator_1 = require("class-validator");
class CreateStockItemDto {
}
exports.CreateStockItemDto = CreateStockItemDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateStockItemDto.prototype, "name", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateStockItemDto.prototype, "category", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateStockItemDto.prototype, "unit", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateStockItemDto.prototype, "quantity", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateStockItemDto.prototype, "alertThreshold", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateStockItemDto.prototype, "costPerUnit", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateStockItemDto.prototype, "supplier", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateStockItemDto.prototype, "supplierPhone", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateStockItemDto.prototype, "photo", void 0);
class AdjustStockDto {
}
exports.AdjustStockDto = AdjustStockDto;
__decorate([
    (0, class_validator_1.IsEnum)(client_1.StockMovementType),
    __metadata("design:type", String)
], AdjustStockDto.prototype, "type", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], AdjustStockDto.prototype, "quantity", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], AdjustStockDto.prototype, "reason", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], AdjustStockDto.prototype, "orderId", void 0);
let StockService = class StockService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(artisanId, category, lowStock) {
        const items = await this.prisma.stockItem.findMany({
            where: {
                artisanId,
                ...(category && { category }),
            },
            include: {
                movements: {
                    orderBy: { createdAt: 'desc' },
                    take: 5,
                },
            },
            orderBy: { updatedAt: 'desc' },
        });
        if (lowStock) {
            return items.filter((item) => item.quantity <= item.alertThreshold);
        }
        return items;
    }
    async findOne(artisanId, itemId) {
        const item = await this.prisma.stockItem.findFirst({
            where: { id: itemId, artisanId },
            include: {
                movements: {
                    orderBy: { createdAt: 'desc' },
                    take: 20,
                },
            },
        });
        if (!item)
            throw new common_1.NotFoundException('Article non trouvé');
        return item;
    }
    async create(artisanId, dto) {
        const item = await this.prisma.stockItem.create({
            data: {
                artisanId,
                name: dto.name,
                category: dto.category,
                unit: dto.unit,
                quantity: dto.quantity,
                alertThreshold: dto.alertThreshold ?? 5,
                costPerUnit: dto.costPerUnit ?? 0,
                supplier: dto.supplier,
                supplierPhone: dto.supplierPhone,
                photo: dto.photo,
            },
        });
        if (dto.quantity > 0) {
            await this.prisma.stockMovement.create({
                data: {
                    stockItemId: item.id,
                    type: 'ENTREE',
                    quantity: dto.quantity,
                    reason: 'Stock initial',
                },
            });
        }
        return { data: item, message: 'Article de stock créé' };
    }
    async adjustStock(artisanId, itemId, dto) {
        const item = await this.prisma.stockItem.findFirst({
            where: { id: itemId, artisanId },
        });
        if (!item)
            throw new common_1.NotFoundException('Article non trouvé');
        if (dto.type === 'SORTIE' && dto.quantity > item.quantity) {
            throw new common_1.BadRequestException('Stock insuffisant pour cette sortie');
        }
        let newQuantity = item.quantity;
        if (dto.type === 'ENTREE') {
            newQuantity += dto.quantity;
        }
        else if (dto.type === 'SORTIE') {
            newQuantity = Math.max(0, newQuantity - dto.quantity);
        }
        else {
            newQuantity = dto.quantity;
        }
        const [updatedItem] = await this.prisma.$transaction([
            this.prisma.stockItem.update({
                where: { id: itemId },
                data: { quantity: newQuantity },
            }),
            this.prisma.stockMovement.create({
                data: {
                    stockItemId: itemId,
                    type: dto.type,
                    quantity: dto.quantity,
                    reason: dto.reason,
                    orderId: dto.orderId,
                },
            }),
        ]);
        const isAlert = updatedItem.quantity <= updatedItem.alertThreshold;
        return {
            data: updatedItem,
            message: 'Stock ajusté',
            alert: isAlert ? `Stock critique : ${updatedItem.quantity} ${updatedItem.unit}` : null,
        };
    }
    async getLowStockAlerts(artisanId) {
        const items = await this.prisma.stockItem.findMany({ where: { artisanId } });
        return items.filter((item) => item.quantity <= item.alertThreshold);
    }
    async update(artisanId, itemId, dto) {
        const item = await this.prisma.stockItem.findFirst({ where: { id: itemId, artisanId } });
        if (!item)
            throw new common_1.NotFoundException('Article non trouvé');
        const updated = await this.prisma.stockItem.update({
            where: { id: itemId },
            data: dto,
        });
        return { data: updated, message: 'Article de stock mis à jour' };
    }
    async remove(artisanId, itemId) {
        const item = await this.prisma.stockItem.findFirst({ where: { id: itemId, artisanId } });
        if (!item)
            throw new common_1.NotFoundException('Article non trouvé');
        await this.prisma.stockItem.delete({ where: { id: itemId } });
        return { message: 'Article de stock supprimé' };
    }
};
exports.StockService = StockService;
exports.StockService = StockService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], StockService);
//# sourceMappingURL=stock.service.js.map