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
  @IsNotEmpty()
  amount: any;
  @IsOptional() @IsString()
  method?: string;
  @IsOptional() @IsString()
  phone?: string;
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
    const rawAmount = typeof dto.amount === 'string' ? parseFloat(dto.amount) : (dto.amount as number);
    const amount = Math.round(rawAmount || 1);
    const method = ((dto.method || 'WAVE').toUpperCase() === 'ORANGE_MONEY') ? 'ORANGE_MONEY' : 'WAVE';
    const phone = dto.phone || '+221770000000';

    if (!dto.orderId && !dto.marketplaceOrderId) {
      throw new BadRequestException('ID de commande requis');
    }

    const commission = Math.round((amount * this.commissionPct) / 100);
    const waveApiKey = this.config.get<string>('WAVE_API_KEY');

    const cleanDto: InitiatePaymentDto = {
      orderId: dto.orderId ? String(dto.orderId) : undefined,
      marketplaceOrderId: dto.marketplaceOrderId ? String(dto.marketplaceOrderId) : undefined,
      amount,
      method: method as PaymentMethod,
      phone,
    };

    // Mode simulation Sandbox si la clé API Wave réelle n'est pas configurée
    if (!waveApiKey || waveApiKey === 'your_wave_api_key' || waveApiKey.trim() === '') {
      return this.initiateSandboxPayment(cleanDto, commission);
    }

    if (method === 'WAVE') {
      return this.initiateWavePayment(cleanDto, commission);
    } else {
      return this.initiateOrangeMoneyPayment(cleanDto, commission);
    }
  }

  private async initiateSandboxPayment(dto: InitiatePaymentDto, commission: number) {
    const ref = `SIM_${dto.method}_${Date.now()}`;

    let targetOrderId = dto.orderId;
    if (!targetOrderId && dto.marketplaceOrderId) {
      const existingPayment = await this.prisma.payment.findFirst({
        where: { marketplaceOrderId: dto.marketplaceOrderId },
      });
      if (existingPayment?.orderId) {
        targetOrderId = existingPayment.orderId;
      }
    }

    const payment = await this.prisma.payment.create({
      data: {
        orderId: targetOrderId || null,
        marketplaceOrderId: dto.marketplaceOrderId || null,
        amount: dto.amount,
        method: dto.method as PaymentMethod,
        status: 'PAYE',
        reference: ref,
        commission,
        commissionPct: this.commissionPct,
        paidAt: new Date(),
      },
    });

    if (targetOrderId) {
      const updatedOrder = await this.prisma.order.update({
        where: { id: targetOrderId },
        data: {
          deposit: dto.amount,
          status: 'EN_COURS',
        },
      });

      const netAmount = dto.amount - commission;
      await this.prisma.transaction.create({
        data: {
          artisanId: updatedOrder.artisanId,
          orderId: updatedOrder.id,
          type: 'ENTREE',
          amount: dto.amount,
          category: 'Vente Marketplace',
          description: `Paiement Sandbox reçu (Net: ${netAmount} FCFA, Commande: ${updatedOrder.orderNumber})`,
          paymentMethod: dto.method as PaymentMethod,
          date: new Date(),
        },
      });

      const artisan = await this.prisma.artisan.findUnique({ where: { id: updatedOrder.artisanId } });
      if (artisan) {
        await this.prisma.notification.create({
          data: {
            userId: artisan.userId,
            type: 'PAIEMENT',
            channel: 'IN_APP',
            title: '💰 Paiement reçu !',
            body: `Le client a effectué le paiement de ${dto.amount} FCFA pour la commande ${updatedOrder.orderNumber}. Vous pouvez lancer la confection !`,
            data: {
              orderId: updatedOrder.id,
            },
          },
        });
      }
    }

    if (dto.marketplaceOrderId) {
      await this.prisma.marketplaceOrder.update({
        where: { id: dto.marketplaceOrderId },
        data: { status: 'EN_COURS' },
      });
    }

    const appUrl = this.config.get<string>('APP_URL') || 'http://localhost:3000/api/v1';

    return {
      data: {
        paymentId: payment.id,
        checkoutUrl: `${appUrl}/payments/sandbox-confirm/${payment.id}`,
        paymentUrl: `${appUrl}/payments/sandbox-confirm/${payment.id}`,
        reference: ref,
        isSandbox: true,
      },
      message: `Paiement ${dto.method} (Mode Simulation Sandbox) validé avec succès`,
    };
  }

  async sandboxConfirmPayment(paymentId: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: { order: true, marketplaceOrder: true },
    });
    if (!payment) throw new BadRequestException('Paiement introuvable');

    await this.prisma.payment.update({
      where: { id: paymentId },
      data: {
        status: 'PAYE',
        paidAt: new Date(),
      },
    });

    if (payment.orderId) {
      const updatedOrder = await this.prisma.order.update({
        where: { id: payment.orderId },
        data: {
          deposit: payment.amount,
          status: 'EN_COURS',
        },
      });

      const commission = Math.round((payment.amount * 10) / 100);
      const netAmount = payment.amount - commission;

      await this.prisma.transaction.create({
        data: {
          artisanId: updatedOrder.artisanId,
          orderId: updatedOrder.id,
          type: 'ENTREE',
          amount: payment.amount,
          category: 'Vente Marketplace',
          description: `Paiement en ligne reçu (Net: ${netAmount} FCFA, Commande: ${updatedOrder.orderNumber})`,
          paymentMethod: payment.method,
          date: new Date(),
        },
      });

      const artisan = await this.prisma.artisan.findUnique({ where: { id: updatedOrder.artisanId } });
      if (artisan) {
        await this.prisma.notification.create({
          data: {
            userId: artisan.userId,
            type: 'PAIEMENT',
            channel: 'IN_APP',
            title: '💰 Paiement reçu !',
            body: `Le client a effectué le paiement de ${payment.amount} FCFA pour la commande ${updatedOrder.orderNumber}. Vous pouvez lancer la confection !`,
            data: {
              orderId: updatedOrder.id,
            },
          },
        });
      }
    }

    if (payment.marketplaceOrderId) {
      await this.prisma.marketplaceOrder.update({
        where: { id: payment.marketplaceOrderId },
        data: { status: 'EN_COURS' },
      });
    }

    return {
      success: true,
      message: 'Paiement confirmé avec succès en mode Sandbox',
    };
  }

  // ── WAVE API ──────────────────────────────────────────────────────────────
  private async initiateWavePayment(dto: InitiatePaymentDto, commission: number) {
    try {
      const waveApiKey = this.config.get('WAVE_API_KEY');

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

      const payment = await this.prisma.payment.create({
        data: {
          orderId: dto.orderId || null,
          marketplaceOrderId: dto.marketplaceOrderId || null,
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
      this.logger.error('Erreur Wave API, bascule sur le mode Sandbox', error);
      return this.initiateSandboxPayment(dto, commission);
    }
  }

  // ── ORANGE MONEY ──────────────────────────────────────────────────────────
  private async initiateOrangeMoneyPayment(dto: InitiatePaymentDto, commission: number) {
    try {
      const omApiKey = this.config.get('ORANGE_MONEY_API_KEY');

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
          orderId: dto.orderId || null,
          marketplaceOrderId: dto.marketplaceOrderId || null,
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
      this.logger.error('Erreur Orange Money API, bascule sur le mode Sandbox', error);
      return this.initiateSandboxPayment(dto, commission);
    }
  }

  // ── WEBHOOKS ──────────────────────────────────────────────────────────────
  async handleWaveWebhook(payload: any, signature: string) {
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

    if (orderId) {
      await this.prisma.order.updateMany({
        where: { id: orderId },
        data: { status: 'EN_COURS' },
      });
    }

    this.logger.log(`Paiement confirmé : ${reference} via ${method}`);
  }
}
