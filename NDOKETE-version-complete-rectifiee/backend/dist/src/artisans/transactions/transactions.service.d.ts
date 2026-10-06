import { PrismaService } from '../../common/prisma/prisma.service';
import { PaymentMethod, TransactionType } from '@prisma/client';
export declare class CreateTransactionDto {
    type: TransactionType;
    amount: number;
    category: string;
    description?: string;
    date?: string;
    orderId?: string;
    receipt?: string;
    paymentMethod?: PaymentMethod;
    localId?: string;
}
export declare class TransactionsService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(artisanId: string, period?: string): Promise<({
        order: {
            title: string;
            orderNumber: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        description: string | null;
        artisanId: string;
        type: import(".prisma/client").$Enums.TransactionType;
        amount: number;
        localId: string | null;
        syncStatus: import(".prisma/client").$Enums.SyncStatus;
        category: string;
        orderId: string | null;
        date: Date;
        receipt: string | null;
        paymentMethod: import(".prisma/client").$Enums.PaymentMethod | null;
    })[]>;
    getTreasurySummary(artisanId: string, period?: string): Promise<{
        income: number;
        expenses: number;
        netProfit: number;
        categoryBreakdown: {
            category: string;
            amount: number;
            percentage: number;
        }[];
        recentTransactions: ({
            order: {
                orderNumber: string;
            } | null;
        } & {
            id: string;
            createdAt: Date;
            description: string | null;
            artisanId: string;
            type: import(".prisma/client").$Enums.TransactionType;
            amount: number;
            localId: string | null;
            syncStatus: import(".prisma/client").$Enums.SyncStatus;
            category: string;
            orderId: string | null;
            date: Date;
            receipt: string | null;
            paymentMethod: import(".prisma/client").$Enums.PaymentMethod | null;
        })[];
        healthScore: string;
    }>;
    getWeeklyEvolution(artisanId: string): Promise<{
        income: number;
        expenses: number;
        week: string;
    }[]>;
    create(artisanId: string, dto: CreateTransactionDto): Promise<{
        data: {
            id: string;
            createdAt: Date;
            description: string | null;
            artisanId: string;
            type: import(".prisma/client").$Enums.TransactionType;
            amount: number;
            localId: string | null;
            syncStatus: import(".prisma/client").$Enums.SyncStatus;
            category: string;
            orderId: string | null;
            date: Date;
            receipt: string | null;
            paymentMethod: import(".prisma/client").$Enums.PaymentMethod | null;
        };
        message: string;
    }>;
    getMonthlyReport(artisanId: string, month: number, year: number): Promise<{
        artisanName: string | undefined;
        period: string;
        totalIncome: number;
        totalExpenses: number;
        netProfit: number;
    }>;
    remove(artisanId: string, id: string): Promise<{
        message: string;
    }>;
    private getPeriodFilter;
    private getWeekKey;
    private getFinancialHealth;
}
