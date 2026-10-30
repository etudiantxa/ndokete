import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
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

  async checkFinancePermission(userId?: string, artisanId?: string) {
    if (!userId || !artisanId) return;
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) return;
    const teamMember = await this.prisma.teamMember.findFirst({
      where: { phone: user.phone, artisanId },
    });
    if (teamMember && !teamMember.canManageFinances) {
      throw new ForbiddenException('Accès refusé : vous n’avez pas les droits d’accès à la trésorerie.');
    }
  }

  async findAll(userId: string, artisanId: string, period?: string) {
    await this.checkFinancePermission(userId, artisanId);
    const dateFilter = this.getPeriodFilter(period);
    return this.prisma.transaction.findMany({
      where: { artisanId, ...dateFilter },
      orderBy: { date: 'desc' },
      include: { order: { select: { orderNumber: true, title: true } } },
    });
  }

  async getTreasurySummary(userId: string, artisanId: string, period = 'month') {
    await this.checkFinancePermission(userId, artisanId);
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
        include: { order: { select: { orderNumber: true, title: true } } },
      }),
    ]);

    const totalIncome = income._sum.amount || 0;
    const totalExpenses = expenses._sum.amount || 0;
    const netProfit = totalIncome - totalExpenses;

    let healthScore = 'EXCELLENT';
    if (totalExpenses > totalIncome) {
      healthScore = 'ATTENTION (Déficit)';
    } else if (netProfit < 50000) {
      healthScore = 'MOYEN';
    }

    return {
      success: true,
      data: {
        totalIncome,
        totalExpenses,
        netProfit,
        healthScore,
        recentTransactions,
      },
      message: 'Résumé trésorerie récupéré',
    };
  }

  async getWeeklyEvolution(userId: string, artisanId: string) {
    await this.checkFinancePermission(userId, artisanId);
    return { success: true, data: [] };
  }

  async getMonthlyReport(userId: string, artisanId: string, month: number, year: number) {
    await this.checkFinancePermission(userId, artisanId);
    return { success: true, data: {} };
  }

  async create(userId: string, artisanId: string, dto: CreateTransactionDto) {
    await this.checkFinancePermission(userId, artisanId);
    const transaction = await this.prisma.transaction.create({
      data: {
        artisanId,
        type: dto.type,
        amount: dto.amount,
        category: dto.category,
        description: dto.description,
        date: dto.date ? new Date(dto.date) : new Date(),
        orderId: dto.orderId,
        paymentMethod: dto.paymentMethod,
        localId: dto.localId,
      },
    });
    return { success: true, data: transaction, message: 'Transaction enregistrée' };
  }

  async remove(userId: string, artisanId: string, id: string) {
    await this.checkFinancePermission(userId, artisanId);
    const tx = await this.prisma.transaction.findFirst({ where: { id, artisanId } });
    if (!tx) throw new NotFoundException('Transaction non trouvée');
    await this.prisma.transaction.delete({ where: { id } });
    return { success: true, message: 'Transaction supprimée' };
  }

  private getPeriodFilter(period?: string) {
    const now = new Date();
    if (period === 'today') {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      return { date: { gte: start } };
    }
    if (period === 'week') {
      const start = new Date(now.setDate(now.getDate() - 7));
      return { date: { gte: start } };
    }
    if (period === 'month') {
      const start = new Date(now.getFullYear(), now.getMonth(), 1);
      return { date: { gte: start } };
    }
    return {};
  }
}
