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
exports.TransactionsService = exports.CreateTransactionDto = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../common/prisma/prisma.service");
const client_1 = require("@prisma/client");
const class_validator_1 = require("class-validator");
class CreateTransactionDto {
}
exports.CreateTransactionDto = CreateTransactionDto;
__decorate([
    (0, class_validator_1.IsEnum)(client_1.TransactionType),
    __metadata("design:type", String)
], CreateTransactionDto.prototype, "type", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateTransactionDto.prototype, "amount", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateTransactionDto.prototype, "category", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateTransactionDto.prototype, "description", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsISO8601)(),
    __metadata("design:type", String)
], CreateTransactionDto.prototype, "date", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateTransactionDto.prototype, "orderId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateTransactionDto.prototype, "receipt", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(client_1.PaymentMethod),
    __metadata("design:type", String)
], CreateTransactionDto.prototype, "paymentMethod", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateTransactionDto.prototype, "localId", void 0);
let TransactionsService = class TransactionsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(artisanId, period) {
        const dateFilter = this.getPeriodFilter(period);
        return this.prisma.transaction.findMany({
            where: { artisanId, ...dateFilter },
            orderBy: { date: 'desc' },
            include: { order: { select: { orderNumber: true, title: true } } },
        });
    }
    async getTreasurySummary(artisanId, period = 'month') {
        const dateFilter = this.getPeriodFilter(period);
        const [income, expenses, recentTransactions] = await Promise.all([
            this.prisma.transaction.aggregate({
                where: { artisanId, type: 'ENTREE', ...dateFilter },
                _sum: { amount: true },
            }),
            this.prisma.transaction.aggregate({
                where: { artisanId, type: 'DEPENSE', ...dateFilter },
                _sum: { amount: true },
            }),
            this.prisma.transaction.findMany({
                where: { artisanId },
                orderBy: { date: 'desc' },
                take: 10,
                include: { order: { select: { orderNumber: true } } },
            }),
        ]);
        const totalIncome = income._sum.amount ?? 0;
        const totalExpenses = expenses._sum.amount ?? 0;
        const expenseByCategory = await this.prisma.transaction.groupBy({
            by: ['category'],
            where: { artisanId, type: 'DEPENSE', ...dateFilter },
            _sum: { amount: true },
        });
        const categoryBreakdown = expenseByCategory.map((e) => ({
            category: e.category,
            amount: e._sum.amount ?? 0,
            percentage: totalExpenses > 0
                ? Math.round(((e._sum.amount ?? 0) / totalExpenses) * 100)
                : 0,
        }));
        return {
            income: totalIncome,
            expenses: totalExpenses,
            netProfit: totalIncome - totalExpenses,
            categoryBreakdown,
            recentTransactions,
            healthScore: this.getFinancialHealth(totalIncome, totalExpenses),
        };
    }
    async getWeeklyEvolution(artisanId) {
        const fourWeeksAgo = new Date();
        fourWeeksAgo.setDate(fourWeeksAgo.getDate() - 28);
        const transactions = await this.prisma.transaction.findMany({
            where: { artisanId, date: { gte: fourWeeksAgo } },
            select: { type: true, amount: true, date: true },
        });
        const weeks = {};
        transactions.forEach((t) => {
            const weekKey = this.getWeekKey(t.date);
            if (!weeks[weekKey])
                weeks[weekKey] = { income: 0, expenses: 0 };
            if (t.type === 'ENTREE')
                weeks[weekKey].income += t.amount;
            else
                weeks[weekKey].expenses += t.amount;
        });
        return Object.entries(weeks).map(([week, data]) => ({ week, ...data }));
    }
    async create(artisanId, dto) {
        if (dto.orderId) {
            const order = await this.prisma.order.findFirst({
                where: { id: dto.orderId, artisanId },
                select: { id: true },
            });
            if (!order)
                throw new common_1.NotFoundException('Commande non trouvée');
            const existingTransaction = await this.prisma.transaction.findUnique({
                where: { orderId: dto.orderId },
                select: { id: true },
            });
            if (existingTransaction) {
                throw new common_1.ConflictException('Cette commande est déjà liée à une transaction');
            }
        }
        if (dto.date && Number.isNaN(new Date(dto.date).getTime())) {
            throw new common_1.BadRequestException('Date de transaction invalide');
        }
        const transaction = await this.prisma.transaction.create({
            data: {
                artisanId,
                type: dto.type,
                amount: dto.amount,
                category: dto.category,
                description: dto.description,
                date: dto.date ? new Date(dto.date) : new Date(),
                orderId: dto.orderId,
                receipt: dto.receipt,
                paymentMethod: dto.paymentMethod,
                localId: dto.localId,
                syncStatus: 'SYNCED',
            },
        });
        return { data: transaction, message: 'Transaction enregistrée' };
    }
    async getMonthlyReport(artisanId, month, year) {
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 1);
        const [income, expenses] = await Promise.all([
            this.prisma.transaction.aggregate({
                where: { artisanId, type: 'ENTREE', date: { gte: startDate, lt: endDate } },
                _sum: { amount: true },
            }),
            this.prisma.transaction.aggregate({
                where: { artisanId, type: 'DEPENSE', date: { gte: startDate, lt: endDate } },
                _sum: { amount: true },
            }),
        ]);
        const artisan = await this.prisma.artisan.findUnique({
            where: { id: artisanId },
            select: { businessName: true },
        });
        return {
            artisanName: artisan?.businessName,
            period: `${month}/${year}`,
            totalIncome: income._sum.amount ?? 0,
            totalExpenses: expenses._sum.amount ?? 0,
            netProfit: (income._sum.amount ?? 0) - (expenses._sum.amount ?? 0),
        };
    }
    async remove(artisanId, id) {
        const transaction = await this.prisma.transaction.findFirst({ where: { id, artisanId } });
        if (!transaction)
            throw new common_1.NotFoundException('Transaction non trouvée');
        await this.prisma.transaction.delete({ where: { id } });
        return { message: 'Transaction supprimée' };
    }
    getPeriodFilter(period) {
        const now = new Date();
        if (period === 'today') {
            const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            return { date: { gte: today } };
        }
        if (period === 'week') {
            const weekAgo = new Date(now);
            weekAgo.setDate(weekAgo.getDate() - 7);
            return { date: { gte: weekAgo } };
        }
        if (period === 'month') {
            const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
            return { date: { gte: monthStart } };
        }
        return {};
    }
    getWeekKey(date) {
        const d = new Date(date);
        const day = d.getDay();
        const diff = d.getDate() - day + (day === 0 ? -6 : 1);
        d.setDate(diff);
        return `SEM${Math.ceil(d.getDate() / 7)}`;
    }
    getFinancialHealth(income, expenses) {
        if (income === 0)
            return 'NEUTRE';
        const ratio = expenses / income;
        if (ratio < 0.5)
            return 'EXCELLENTE';
        if (ratio < 0.75)
            return 'BONNE';
        if (ratio < 1)
            return 'CORRECTE';
        return 'CRITIQUE';
    }
};
exports.TransactionsService = TransactionsService;
exports.TransactionsService = TransactionsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], TransactionsService);
//# sourceMappingURL=transactions.service.js.map