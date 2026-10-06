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
var PaymentsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsService = exports.InitiatePaymentDto = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const prisma_service_1 = require("../common/prisma/prisma.service");
const axios_1 = require("axios");
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
class InitiatePaymentDto {
}
exports.InitiatePaymentDto = InitiatePaymentDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], InitiatePaymentDto.prototype, "orderId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], InitiatePaymentDto.prototype, "marketplaceOrderId", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], InitiatePaymentDto.prototype, "amount", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.PaymentMethod),
    __metadata("design:type", String)
], InitiatePaymentDto.prototype, "method", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], InitiatePaymentDto.prototype, "phone", void 0);
let PaymentsService = PaymentsService_1 = class PaymentsService {
    constructor(prisma, config) {
        this.prisma = prisma;
        this.config = config;
        this.logger = new common_1.Logger(PaymentsService_1.name);
        this.commissionPct = config.get('NDOKETE_COMMISSION_PCT', 10);
    }
    async initiatePayment(dto) {
        if ((!dto.orderId && !dto.marketplaceOrderId) ||
            (dto.orderId && dto.marketplaceOrderId)) {
            throw new common_1.BadRequestException('orderId ou marketplaceOrderId requis');
        }
        const commission = Math.round((dto.amount * this.commissionPct) / 100);
        const artisanAmount = dto.amount - commission;
        if (dto.method === 'WAVE') {
            return this.initiateWavePayment(dto, commission);
        }
        else {
            return this.initiateOrangeMoneyPayment(dto, commission);
        }
    }
    async initiateWavePayment(dto, commission) {
        try {
            const waveApiKey = this.config.get('WAVE_API_KEY');
            const response = await axios_1.default.post('https://api.wave.com/v1/checkout/sessions', {
                amount: String(dto.amount),
                currency: 'XOF',
                client_reference: dto.orderId ?? dto.marketplaceOrderId,
                success_url: `${this.config.get('APP_URL')}/payment/success`,
                error_url: `${this.config.get('APP_URL')}/payment/error`,
            }, {
                headers: {
                    Authorization: `Bearer ${waveApiKey}`,
                    'Content-Type': 'application/json',
                },
            });
            const payment = await this.prisma.payment.create({
                data: {
                    orderId: dto.orderId,
                    marketplaceOrderId: dto.marketplaceOrderId,
                    amount: dto.amount,
                    method: 'WAVE',
                    status: 'EN_ATTENTE',
                    reference: response.data.id,
                    commission,
                    commissionPct: this.commissionPct,
                },
            });
            return {
                data: {
                    paymentId: payment.id,
                    checkoutUrl: response.data.wave_launch_url,
                    reference: response.data.id,
                },
                message: 'Paiement Wave initié',
            };
        }
        catch (error) {
            this.logger.error('Erreur Wave API', error);
            throw new common_1.BadRequestException('Impossible d\'initier le paiement Wave');
        }
    }
    async initiateOrangeMoneyPayment(dto, commission) {
        try {
            const omApiKey = this.config.get('ORANGE_MONEY_API_KEY');
            const response = await axios_1.default.post('https://api.orange.com/orange-money-webpay/sn/v1/webpayment', {
                merchant_key: omApiKey,
                currency: 'OUV',
                order_id: dto.orderId ?? dto.marketplaceOrderId,
                amount: dto.amount,
                return_url: `${this.config.get('APP_URL')}/payment/success`,
                cancel_url: `${this.config.get('APP_URL')}/payment/cancel`,
                notif_url: `${this.config.get('APP_URL')}/api/v1/payments/webhook/orange-money`,
                lang: 'fr',
                reference: dto.orderId ?? dto.marketplaceOrderId,
            }, {
                headers: { Authorization: `Bearer ${omApiKey}` },
            });
            const payment = await this.prisma.payment.create({
                data: {
                    orderId: dto.orderId,
                    marketplaceOrderId: dto.marketplaceOrderId,
                    amount: dto.amount,
                    method: 'ORANGE_MONEY',
                    status: 'EN_ATTENTE',
                    reference: response.data.pay_token,
                    commission,
                    commissionPct: this.commissionPct,
                },
            });
            return {
                data: {
                    paymentId: payment.id,
                    paymentUrl: response.data.payment_url,
                    token: response.data.pay_token,
                },
                message: 'Paiement Orange Money initié',
            };
        }
        catch (error) {
            this.logger.error('Erreur Orange Money API', error);
            throw new common_1.BadRequestException('Impossible d\'initier le paiement Orange Money');
        }
    }
    async handleWaveWebhook(payload, signature) {
        const webhookSecret = this.config.get('WAVE_WEBHOOK_SECRET');
        this.logger.log(`Webhook Wave reçu : ${payload.type}`);
        if (payload.type === 'checkout.session.completed') {
            await this.confirmPayment(payload.data.client_reference, payload.data.id, 'WAVE', payload);
        }
        return { received: true };
    }
    async handleOrangeMoneyWebhook(payload) {
        this.logger.log(`Webhook Orange Money reçu : ${payload.status}`);
        if (payload.status === 'SUCCESS') {
            await this.confirmPayment(payload.order_id, payload.pay_token, 'ORANGE_MONEY', payload);
        }
        return { received: true };
    }
    async confirmPayment(orderId, reference, method, webhookData) {
        await this.prisma.payment.updateMany({
            where: { reference },
            data: {
                status: 'PAYE',
                paidAt: new Date(),
                webhookData,
            },
        });
        if (orderId) {
            await this.prisma.order.updateMany({
                where: { id: orderId },
                data: { status: 'EN_COURS' },
            });
        }
        this.logger.log(`Paiement confirmé : ${reference} via ${method}`);
    }
};
exports.PaymentsService = PaymentsService;
exports.PaymentsService = PaymentsService = PaymentsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        config_1.ConfigService])
], PaymentsService);
//# sourceMappingURL=payments.service.js.map