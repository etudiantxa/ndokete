import { PaymentsService, InitiatePaymentDto } from './payments.service';
export declare class PaymentsController {
    private paymentsService;
    constructor(paymentsService: PaymentsService);
    initiate(dto: InitiatePaymentDto): Promise<{
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
    waveWebhook(payload: any, signature: string): Promise<{
        received: boolean;
    }>;
    orangeMoneyWebhook(payload: any): Promise<{
        received: boolean;
    }>;
}
