import { Controller, Post, Body, Headers, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService, InitiatePaymentDto } from './payments.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('payments')
@ApiBearerAuth('access-token')
@Controller('payments')
export class PaymentsController {
  constructor(private paymentsService: PaymentsService) {}

  @UseGuards(JwtAuthGuard)
  @Post('initiate')
  @ApiOperation({ summary: 'Initier un paiement Wave ou Orange Money' })
  initiate(@Body() dto: InitiatePaymentDto) {
    return this.paymentsService.initiatePayment(dto);
  }

  @Public()
  @Post('webhook/wave')
  @ApiOperation({ summary: 'Webhook Wave (confirmations de paiement)' })
  waveWebhook(
    @Body() payload: any,
    @Headers('wave-signature') signature: string,
  ) {
    return this.paymentsService.handleWaveWebhook(payload, signature);
  }

  @Public()
  @Post('webhook/orange-money')
  @ApiOperation({ summary: 'Webhook Orange Money (confirmations de paiement)' })
  orangeMoneyWebhook(@Body() payload: any) {
    return this.paymentsService.handleOrangeMoneyWebhook(payload);
  }
}
