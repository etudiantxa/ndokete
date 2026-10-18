import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../common/prisma/prisma.service';
import axios from 'axios';
import { IsEnum, IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';
import { PaymentMethod } from '@prisma/client';

export class InitiatePaymentDto {
  @IsOptional() @IsString()
  orderId?: string;
  @IsOptional() @IsString()
  marketplaceOrderId?: string;
  @IsInt() @Min(1)
  amount: number;
  @IsEnum(PaymentMethod)
  method: PaymentMethod;
  @IsString() @IsNotEmpty()
  phone: string;
}

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);
  private readonly commissionPct: number;

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
  ) {
    this.commissionPct = config.get<number>('NDOKETE_COMMISSION_PCT', 10);
  }

  async initiatePayment(dto: InitiatePaymentDto) {
    if ((!dto.orderId && !dto.marketplaceOrderId) ||
        (dto.orderId && dto.marketplaceOrderId)) {
      throw new BadRequestException('orderId ou marketplaceOrderId requis');
    }

    // Calcul commission NDOKETE (10-12%)
    const commission = Math.round((dto.amount * this.commissionPct) / 100);
    const artisanAmount = dto.amount - commission;

    if (dto.method === 'WAVE') {
      return this.initiateWavePayment(dto, commission);
    } else {
      return this.initiateOrangeMoneyPayment(dto, commission);
    }
  }

  // ── WAVE API ──────────────────────────────────────────────────────────────
  private async initiateWavePayment(dto: InitiatePaymentDto, commission: number) {
    try {
      const waveApiKey = this.config.get('WAVE_API_KEY');

      // Appel API Wave CI/Sénégal
      // Documentation : https://www.wave.com/en/api/
      const response = await axios.post(
        'https://api.wave.com/v1/checkout/sessions',
        {
          amount: String(dto.amount),
          currency: 'XOF',
          client_reference: dto.orderId ?? dto.marketplaceOrderId,
          success_url: `${this.config.get('APP_URL')}/payment/success`,
          error_url: `${this.config.get('APP_URL')}/payment/error`,
        },
        {
          headers: {
            Authorization: `Bearer ${waveApiKey}`,
            'Content-Type': 'application/json',
          },
        },
      );

      // Enregistrer le paiement en attente
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
    } catch (error) {
      this.logger.error('Erreur Wave API', error);
      throw new BadRequestException('Impossible d\'initier le paiement Wave');
    }
  }

  // ── ORANGE MONEY ──────────────────────────────────────────────────────────
  private async initiateOrangeMoneyPayment(dto: InitiatePaymentDto, commission: number) {
    try {
      const omApiKey = this.config.get('ORANGE_MONEY_API_KEY');

      // Orange Money Sénégal API
      const response = await axios.post(
        'https://api.orange.com/orange-money-webpay/sn/v1/webpayment',
        {
          merchant_key: omApiKey,
          currency: 'OUV',
          order_id: dto.orderId ?? dto.marketplaceOrderId,
          amount: dto.amount,
          return_url: `${this.config.get('APP_URL')}/payment/success`,
          cancel_url: `${this.config.get('APP_URL')}/payment/cancel`,
          notif_url: `${this.config.get('APP_URL')}/api/v1/payments/webhook/orange-money`,
          lang: 'fr',
          reference: dto.orderId ?? dto.marketplaceOrderId,
        },
        {
          headers: { Authorization: `Bearer ${omApiKey}` },
        },
      );

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
    } catch (error) {
      this.logger.error('Erreur Orange Money API', error);
      throw new BadRequestException('Impossible d\'initier le paiement Orange Money');
    }
  }

  // ── WEBHOOKS ──────────────────────────────────────────────────────────────
  async handleWaveWebhook(payload: any, signature: string) {
    // Vérifier la signature Wave
    const webhookSecret = this.config.get('WAVE_WEBHOOK_SECRET');
    // TODO: implémenter la vérification HMAC-SHA256

    this.logger.log(`Webhook Wave reçu : ${payload.type}`);

    if (payload.type === 'checkout.session.completed') {
      await this.confirmPayment(payload.data.client_reference, payload.data.id, 'WAVE', payload);
    }

    return { received: true };
  }

  async handleOrangeMoneyWebhook(payload: any) {
    this.logger.log(`Webhook Orange Money reçu : ${payload.status}`);

    if (payload.status === 'SUCCESS') {
      await this.confirmPayment(payload.order_id, payload.pay_token, 'ORANGE_MONEY', payload);
    }

    return { received: true };
  }

  private async confirmPayment(
    orderId: string,
    reference: string,
    method: string,
    webhookData: any,
  ) {
    await this.prisma.payment.updateMany({
      where: { reference },
      data: {
        status: 'PAYE',
        paidAt: new Date(),
        webhookData,
      },
    });

    // Mettre à jour la commande
    if (orderId) {
      await this.prisma.order.updateMany({
        where: { id: orderId },
        data: { status: 'EN_COURS' },
      });
    }

    this.logger.log(`Paiement confirmé : ${reference} via ${method}`);
  }
}
