import { IsEnum, IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PaymentMethod, SubscriptionPlan } from '@prisma/client';

export class UpgradeSubscriptionDto {
  @ApiProperty({ enum: SubscriptionPlan, example: 'PREMIUM' })
  @IsEnum(SubscriptionPlan)
  plan: SubscriptionPlan;

  @ApiProperty({ enum: PaymentMethod, example: 'WAVE' })
  @IsEnum(PaymentMethod)
  method: PaymentMethod;

  @ApiProperty({ example: '+221771234567' })
  @IsString()
  @IsNotEmpty()
  phone: string;
}
