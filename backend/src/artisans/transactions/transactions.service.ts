import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { PaymentMethod, TransactionType } from '@prisma/client';
import { IsEnum, IsInt, IsISO8601, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';

export class CreateTransactionDto {
  @IsEnum(TransactionType)
  type: TransactionType;
  @IsInt() @Min(0)
  amount: number;
  @IsString() @IsNotEmpty()
  category: string;
  @IsOptional() @IsString()
  description?: string;
  @IsOptional() @IsISO8601()
  date?: string;
  @IsOptional() @IsString()
  orderId?: string;
  @IsOptional() @IsString()
  receipt?: string;
  @IsOptional() @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;
  @IsOptional() @IsString()
  localId?: string;
}

@Injectable()
export class TransactionsService {
  constructor(private prisma: PrismaService) {}

  async findAll(artisanId: string, period?: string) {
    const dateFilter = this.getPeriodFilter(period);
    return this.prisma.transaction.findMany({
      where: { artisanId, ...dateFilter },
      orderBy: { date: 'desc' },
      include: { order: { select: { orderNumber: true, title: true } } },
    });
  }

  async getTreasurySummary(artisanId: string, period = 'month') {
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

    // Répartition des dépenses par catégorie
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

  async getWeeklyEvolution(artisanId: string) {
    const fourWeeksAgo = new Date();
    fourWeeksAgo.setDate(fourWeeksAgo.getDate() - 28);

    const transactions = await this.prisma.transaction.findMany({
      where: { artisanId, date: { gte: fourWeeksAgo } },
      select: { type: true, amount: true, date: true },
    });

    // Grouper par semaine
    const weeks: Record<string, { income: number; expenses: number }> = {};
    transactions.forEach((t) => {
      const weekKey = this.getWeekKey(t.date);
      if (!weeks[weekKey]) weeks[weekKey] = { income: 0, expenses: 0 };
      if (t.type === 'ENTREE') weeks[weekKey].income += t.amount;
      else weeks[weekKey].expenses += t.amount;
    });

    return Object.entries(weeks).map(([week, data]) => ({ week, ...data }));
  }

  async create(artisanId: string, dto: CreateTransactionDto) {
    if (dto.orderId) {
      const order = await this.prisma.order.findFirst({
        where: { id: dto.orderId, artisanId },
        select: { id: true },
      });
      if (!order) throw new NotFoundException('Commande non trouvée');
      const existingTransaction = await this.prisma.transaction.findUnique({
        where: { orderId: dto.orderId },
        select: { id: true },
      });
      if (existingTransaction) {
        throw new ConflictException('Cette commande est déjà liée à une transaction');
      }
    }
    if (dto.date && Number.isNaN(new Date(dto.date).getTime())) {
      throw new BadRequestException('Date de transaction invalide');
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

  async getMonthlyReport(artisanId: string, month: number, year: number) {
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

  async remove(artisanId: string, id: string) {
    const transaction = await this.prisma.transaction.findFirst({ where: { id, artisanId } });
    if (!transaction) throw new NotFoundException('Transaction non trouvée');
    await this.prisma.transaction.delete({ where: { id } });
    return { message: 'Transaction supprimée' };
  }

  private getPeriodFilter(period?: string) {
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

  private getWeekKey(date: Date): string {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);
    d.setDate(diff);
    return `SEM${Math.ceil(d.getDate() / 7)}`;
  }

  private getFinancialHealth(income: number, expenses: number): string {
    if (income === 0) return 'NEUTRE';
    const ratio = expenses / income;
    if (ratio < 0.5) return 'EXCELLENTE';
    if (ratio < 0.75) return 'BONNE';
    if (ratio < 1) return 'CORRECTE';
    return 'CRITIQUE';
  }
}
