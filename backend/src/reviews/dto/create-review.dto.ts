import { IsInt, IsNotEmpty, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateReviewDto {
  @IsString() @IsNotEmpty()
  artisanId: string;

  @IsOptional() @IsString()
  marketplaceOrderId?: string;

  @IsInt() @Min(1) @Max(5)
  rating: number;

  @IsOptional() @IsString()
  comment?: string;
}
