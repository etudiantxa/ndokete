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
exports.ClientsService = exports.CreateCustomerDto = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../common/prisma/prisma.service");
const class_validator_1 = require("class-validator");
class CreateCustomerDto {
}
exports.CreateCustomerDto = CreateCustomerDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    __metadata("design:type", String)
], CreateCustomerDto.prototype, "name", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    __metadata("design:type", String)
], CreateCustomerDto.prototype, "phone", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEmail)(),
    __metadata("design:type", String)
], CreateCustomerDto.prototype, "email", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateCustomerDto.prototype, "address", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateCustomerDto.prototype, "notes", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], CreateCustomerDto.prototype, "isVip", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Object)
], CreateCustomerDto.prototype, "measurements", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateCustomerDto.prototype, "localId", void 0);
let ClientsService = class ClientsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(artisanId, search) {
        const customers = await this.prisma.customer.findMany({
            where: {
                artisanId,
                ...(search && {
                    OR: [
                        { name: { contains: search, mode: 'insensitive' } },
                        { phone: { contains: search } },
                    ],
                }),
            },
            orderBy: [{ isVip: 'desc' }, { lastOrderAt: 'desc' }],
            include: { _count: { select: { orders: true } } },
        });
        return customers.map((customer) => {
            const summary = { ...customer };
            delete summary.measurements;
            delete summary._count;
            summary.totalOrders = customer._count.orders;
            return summary;
        });
    }
    async findOne(artisanId, customerId) {
        const customer = await this.prisma.customer.findFirst({
            where: { id: customerId, artisanId },
            include: {
                _count: { select: { orders: true } },
                orders: {
                    orderBy: { createdAt: 'desc' },
                    take: 10,
                    include: { payments: true },
                },
            },
        });
        if (!customer)
            throw new common_1.NotFoundException('Client non trouvé');
        const { _count, ...details } = customer;
        return { ...details, totalOrders: _count.orders };
    }
    async create(artisanId, dto) {
        const name = dto.name?.trim();
        const phone = dto.phone?.trim();
        if (!name || !phone) {
            throw new common_1.BadRequestException('Le nom et le téléphone du client sont obligatoires');
        }
        const artisan = await this.prisma.artisan.findUnique({
            where: { id: artisanId },
            include: { subscription: true },
        });
        if (artisan?.subscription?.plan === 'FREE') {
            const count = await this.prisma.customer.count({ where: { artisanId } });
            if (count >= 20) {
                throw new common_1.ForbiddenException('Limite de 20 clients atteinte sur le plan gratuit. Passez au Premium !');
            }
        }
        const customer = await this.prisma.customer.create({
            data: {
                artisanId,
                name,
                phone,
                email: dto.email,
                address: dto.address,
                notes: dto.notes,
                isVip: dto.isVip ?? false,
                measurements: dto.measurements ?? {},
            },
        });
        return { data: customer, message: 'Client ajouté avec succès' };
    }
    async update(artisanId, customerId, dto) {
        const customer = await this.prisma.customer.findFirst({
            where: { id: customerId, artisanId },
        });
        if (!customer)
            throw new common_1.NotFoundException('Client non trouvé');
        if (dto.name !== undefined && !dto.name.trim()) {
            throw new common_1.BadRequestException('Le nom du client est obligatoire');
        }
        if (dto.phone !== undefined && !dto.phone.trim()) {
            throw new common_1.BadRequestException('Le téléphone du client est obligatoire');
        }
        const updated = await this.prisma.customer.update({
            where: { id: customerId },
            data: {
                ...(dto.name !== undefined && { name: dto.name.trim() }),
                ...(dto.phone !== undefined && { phone: dto.phone.trim() }),
                ...(dto.email !== undefined && { email: dto.email }),
                ...(dto.address !== undefined && { address: dto.address }),
                ...(dto.notes !== undefined && { notes: dto.notes }),
                ...(dto.isVip !== undefined && { isVip: dto.isVip }),
                ...(dto.measurements && { measurements: dto.measurements }),
            },
        });
        return { data: updated, message: 'Client mis à jour' };
    }
    async updateMeasurements(artisanId, customerId, measurements) {
        const customer = await this.prisma.customer.findFirst({
            where: { id: customerId, artisanId },
        });
        if (!customer)
            throw new common_1.NotFoundException('Client non trouvé');
        const updated = await this.prisma.customer.update({
            where: { id: customerId },
            data: { measurements },
        });
        return { data: updated, message: 'Mesures mises à jour' };
    }
    async remove(artisanId, customerId) {
        const customer = await this.prisma.customer.findFirst({
            where: { id: customerId, artisanId },
            select: { id: true },
        });
        if (!customer)
            throw new common_1.NotFoundException('Client non trouvé');
        const orders = await this.prisma.order.findMany({
            where: { customerId, artisanId },
            select: { id: true },
        });
        const orderIds = orders.map((order) => order.id);
        await this.prisma.$transaction(async (tx) => {
            if (orderIds.length) {
                await tx.transaction.updateMany({
                    where: { orderId: { in: orderIds } },
                    data: { orderId: null },
                });
                await tx.payment.deleteMany({ where: { orderId: { in: orderIds } } });
                await tx.order.deleteMany({ where: { id: { in: orderIds }, artisanId } });
            }
            await tx.customer.delete({ where: { id: customerId } });
        });
        return {
            message: `Client supprimé${orderIds.length ? ` avec ${orderIds.length} commande(s)` : ''}`,
            deletedOrders: orderIds.length,
        };
    }
};
exports.ClientsService = ClientsService;
exports.ClientsService = ClientsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ClientsService);
//# sourceMappingURL=clients.service.js.map