import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: '+221771234567 ou email' })
  @IsString()
  @IsNotEmpty()
  identifier: string; // email ou téléphone

  @ApiProperty({ example: 'MonMotDePasse123!' })
  @IsString()
  @IsNotEmpty()
  password: string;
}

export class RefreshTokenDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}
