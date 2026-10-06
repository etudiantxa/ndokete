import { TransactionsService, CreateTransactionDto } from './transactions.service';
export declare class TransactionsController {
    private transactionsService;
    constructor(transactionsService: TransactionsService);
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
    getTreasury(artisanId: string, period?: string): Promise<{
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
    getWeekly(artisanId: string): Promise<{
        income: number;
        expenses: number;
        week: string;
    }[]>;
    getReport(artisanId: string, year: number, month: number): Promise<{
        artisanName: string | undefined;
        period: string;
        totalIncome: number;
        totalExpenses: number;
        netProfit: number;
    }>;
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
    remove(artisanId: string, id: string): Promise<{
        message: string;
    }>;
}
