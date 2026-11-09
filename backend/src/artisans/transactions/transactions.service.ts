import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
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

  async getAuthorName(userId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { artisan: { select: { businessName: true } }, client: { select: { name: true } } },
    });
    if (!user) return 'Atelier';

    if (user.phone) {
      const cleanPhone = user.phone.replace(/[^0-9]/g, '');
      const allMembers = await this.prisma.teamMember.findMany();
      const matchedMember = allMembers.find(
        (m) => m.phone.replace(/[^0-9]/g, '').endsWith(cleanPhone.slice(-9)),
      );
      if (matchedMember) {
        return matchedMember.name;
      }
    }

    if (user.artisan?.businessName) {
      return user.artisan.businessName;
    }

    if (user.client?.name) {
      return user.client.name;
    }

    return user.email.split('@')[0] || 'Atelier';
  }

  async resolveArtisanId(userId: string, artisanId?: string): Promise<string> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { artisan: { select: { id: true } } },
    });
    if (!user) throw new ForbiddenException('Utilisateur non trouvé');

    // 1. Si l'utilisateur est le propriétaire de l'atelier
    if (user.artisan?.id) {
      return user.artisan.id;
    }

    // 2. Si c'est un membre d'équipe (Apprenti / Employé)
    if (user.phone) {
      const cleanPhone = user.phone.replace(/[^0-9]/g, '');
      const allMembers = await this.prisma.teamMember.findMany();
      const matchedMember = allMembers.find(
        (m) => m.phone.replace(/[^0-9]/g, '').endsWith(cleanPhone.slice(-9)),
      );

      if (matchedMember) {
        if (!matchedMember.canManageFinances) {
          throw new ForbiddenException(
            'Accès refusé : vous n’avez pas les droits d’accès à la trésorerie.',
          );
        }
        return matchedMember.artisanId;
      }
    }

    throw new ForbiddenException('Accès refusé : vous n’avez pas les droits d’accès à cet atelier.');
  }

  async findAll(userId: string, artisanId?: string, period?: string) {
    const realArtisanId = await this.resolveArtisanId(userId, artisanId);
    const dateFilter = this.getPeriodFilter(period);
    return this.prisma.transaction.findMany({
      where: { artisanId: realArtisanId, ...dateFilter },
      orderBy: { date: 'desc' },
      include: { order: { select: { orderNumber: true, title: true } } },
    });
  }

  async getTreasurySummary(userId: string, artisanId?: string, period = 'month') {
    const realArtisanId = await this.resolveArtisanId(userId, artisanId);
    const dateFilter = this.getPeriodFilter(period);

    const [income, expenses, recentTransactions] = await Promise.all([
      this.prisma.transaction.aggregate({
        where: { artisanId: realArtisanId, type: 'ENTREE', ...dateFilter },
        _sum: { amount: true },
      }),
      this.prisma.transaction.aggregate({
        where: { artisanId: realArtisanId, type: 'DEPENSE', ...dateFilter },
        _sum: { amount: true },
      }),
      this.prisma.transaction.findMany({
        where: { artisanId: realArtisanId },
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

  async getWeeklyEvolution(userId: string, artisanId?: string) {
    await this.resolveArtisanId(userId, artisanId);
    return { success: true, data: [] };
  }

  async getMonthlyReport(userId: string, artisanId: string, month: number, year: number) {
    const realArtisanId = await this.resolveArtisanId(userId, artisanId);

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const [artisan, income, expenses, transactions] = await Promise.all([
      this.prisma.artisan.findUnique({ where: { id: realArtisanId }, select: { businessName: true } }),
      this.prisma.transaction.aggregate({
        where: {
          artisanId: realArtisanId,
          type: 'ENTREE',
          date: { gte: startDate, lte: endDate },
        },
        _sum: { amount: true },
      }),
      this.prisma.transaction.aggregate({
        where: {
          artisanId: realArtisanId,
          type: 'DEPENSE',
          date: { gte: startDate, lte: endDate },
        },
        _sum: { amount: true },
      }),
      this.prisma.transaction.findMany({
        where: {
          artisanId: realArtisanId,
          date: { gte: startDate, lte: endDate },
        },
        orderBy: { date: 'desc' },
        include: { order: { select: { orderNumber: true, title: true } } },
      }),
    ]);

    const totalIncome = income._sum.amount || 0;
    const totalExpenses = expenses._sum.amount || 0;
    const netProfit = totalIncome - totalExpenses;

    return {
      success: true,
      data: {
        artisanName: artisan?.businessName || 'Atelier NDOKETE',
        month,
        year,
        totalIncome,
        totalExpenses,
        netProfit,
        transactions,
      },
      message: 'Rapport mensuel récupéré avec succès',
    };
  }

  async create(userId: string, artisanId: string, dto: CreateTransactionDto) {
    const realArtisanId = await this.resolveArtisanId(userId, artisanId);
    const validOrderId = dto.orderId && dto.orderId.trim() !== '' ? dto.orderId : undefined;
    const authorName = await this.getAuthorName(userId);

    const transaction = await this.prisma.transaction.create({
      data: {
        artisanId: realArtisanId,
        type: dto.type,
        amount: dto.amount,
        category: dto.category,
        description: dto.description,
        authorName,
        date: dto.date ? new Date(dto.date) : new Date(),
        orderId: validOrderId,
        paymentMethod: dto.paymentMethod,
        localId: dto.localId,
      },
    });

    // Si la transaction est liée à une commande valide et de type ENTREE, incrémenter l'acompte de la commande avec vérification de dépassement
    if (validOrderId && dto.type === 'ENTREE') {
      const order = await this.prisma.order.findFirst({
        where: { id: validOrderId, artisanId: realArtisanId },
      });
      if (order) {
        const potentialDeposit = order.deposit + dto.amount;
        if (potentialDeposit > order.amount) {
          throw new BadRequestException(
            `Le montant versé (${dto.amount} FCFA) dépasse le solde restant dû (${order.amount - order.deposit} FCFA). Total commande : ${order.amount} FCFA.`
          );
        }
        await this.prisma.order.update({
          where: { id: validOrderId },
          data: { deposit: potentialDeposit },
        });
      }
    }

    return { success: true, data: transaction, message: 'Transaction enregistrée' };
  }

  async remove(userId: string, artisanId: string, id: string) {
    const realArtisanId = await this.resolveArtisanId(userId, artisanId);
    const tx = await this.prisma.transaction.findFirst({ where: { id, artisanId: realArtisanId } });
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
