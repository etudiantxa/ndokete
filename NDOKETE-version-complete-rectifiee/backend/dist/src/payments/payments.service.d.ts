import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../common/prisma/prisma.service';
import { PaymentMethod } from '@prisma/client';
export declare class InitiatePaymentDto {
    orderId?: string;
    marketplaceOrderId?: string;
    amount: number;
    method: PaymentMethod;
    phone: string;
}
export declare class PaymentsService {
    private prisma;
    private config;
    private readonly logger;
    private readonly commissionPct;
    constructor(prisma: PrismaService, config: ConfigService);
    initiatePayment(dto: InitiatePaymentDto): Promise<{
        data: {
            paymentId: string;
            checkoutUrl: any;
            reference: any;
        };
        message: string;
    } | {
        data: {
            paymentId: string;
            paymentUrl: any;
            token: any;
        };
        message: string;
    }>;
    private initiateWavePayment;
    private initiateOrangeMoneyPayment;
    handleWaveWebhook(payload: any, signature: string): Promise<{
        received: boolean;
    }>;
    handleOrangeMoneyWebhook(payload: any): Promise<{
        received: boolean;
    }>;
    private confirmPayment;
}
