import {
  IsString, IsInt, IsOptional, IsBoolean, IsDateString, Min, Max, IsEnum, MinLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { OrderStatus } from '@prisma/client';

export class CreateOrderDto {
  @ApiProperty({ example: 'cust_uuid' })
  @IsString()
  customerId: string;

  @ApiProperty({ example: 'Boubou 3 pièces en soie' })
  @IsString()
  @MinLength(1)
  title: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 45000 })
  @IsInt()
  @Min(0)
  amount: number;

  @ApiProperty({ example: 10000 })
  @IsOptional()
  @IsInt()
  @Min(0)
  deposit?: number;

  @ApiProperty({ example: '2025-11-28T00:00:00Z', required: false })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsBoolean()
  isUrgent?: boolean;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  notes?: string;

  // Pour la synchronisation offline
  @ApiProperty({ required: false, description: 'ID local Hive pour la sync offline' })
  @IsOptional()
  @IsString()
  localId?: string;
}

export class UpdateOrderDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @IsEnum(OrderStatus)
  status?: OrderStatus;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  progressPct?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsBoolean()
  isUrgent?: boolean;
}
