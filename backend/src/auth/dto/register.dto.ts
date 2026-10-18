import {
  IsEmail,
  IsString,
  MinLength,
  IsEnum,
  IsOptional,
  Matches,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Role } from '@prisma/client';

export class RegisterDto {
  @ApiProperty({ example: 'moussa@example.com' })
  @IsEmail({}, { message: 'Email invalide' })
  email: string;

  @ApiProperty({ example: '+221771234567' })
  @IsString()
  @Matches(/^\+?[0-9]{8,15}$/, { message: 'Numéro de téléphone invalide' })
  phone: string;

  @ApiProperty({ example: 'MonMotDePasse123!' })
  @IsString()
  @MinLength(8, { message: 'Mot de passe minimum 8 caractères' })
  password: string;

  @ApiProperty({ enum: Role, example: Role.ARTISAN })
  @IsEnum(Role)
  role: Role;

  // Artisan uniquement
  @ApiProperty({ example: 'Atelier Moussa', required: false })
  @IsOptional()
  @IsString()
  businessName?: string;

  @ApiProperty({ example: 'Tailleur', required: false })
  @IsOptional()
  @IsString()
  specialty?: string;

  @ApiProperty({ example: 'Médina', required: false })
  @IsOptional()
  @IsString()
  quarter?: string;
}
