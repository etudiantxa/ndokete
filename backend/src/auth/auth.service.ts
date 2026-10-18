import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../common/prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { Role } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    // Vérifier unicité email + téléphone
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ email: dto.email }, { phone: dto.phone }] },
    });
    if (existing) {
      throw new ConflictException('Email ou téléphone déjà utilisé');
    }

    // Hash du mot de passe
    const passwordHash = await bcrypt.hash(dto.password, 12);

    // Créer l'utilisateur
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        phone: dto.phone,
        passwordHash,
        role: dto.role,
      },
    });

    // Créer le profil artisan si besoin
    if (dto.role === Role.ARTISAN) {
      if (!dto.businessName || !dto.quarter) {
        throw new BadRequestException('businessName et quarter requis pour un artisan');
      }
      await this.prisma.artisan.create({
        data: {
          userId: user.id,
          businessName: dto.businessName,
          specialty: dto.specialty ? [dto.specialty] : [],
          quarter: dto.quarter,
          subscription: {
            create: { plan: 'FREE' },
          },
          analytics: { create: {} },
          autoReminders: { create: {} },
        },
      });
    } else if (dto.role === Role.CLIENT) {
      await this.prisma.client.create({
        data: { userId: user.id },
      });
    }

    const tokens = await this.generateTokens(
      user.id,
      user.email,
      user.role,
      undefined,
    );
    return {
      message: 'Compte créé avec succès',
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
      ...tokens,
    };
  }

  async login(dto: LoginDto) {
    // Chercher par email ou téléphone
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ email: dto.identifier }, { phone: dto.identifier }],
        isActive: true,
      },
      include: { artisan: { select: { id: true } } },
    });

    if (!user) throw new UnauthorizedException('Identifiants incorrects');

    const passwordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordValid) throw new UnauthorizedException('Identifiants incorrects');

    const tokens = await this.generateTokens(user.id, user.email, user.role, user.artisan?.id);
    return {
      message: 'Connexion réussie',
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        role: user.role,
        artisanId: user.artisan?.id,
      },
      ...tokens,
    };
  }

  async refreshTokens(refreshToken: string) {
    const stored = await this.prisma.refreshToken.findFirst({
      where: {
        token: refreshToken,
        isRevoked: false,
        expiresAt: { gt: new Date() },
      },
    });
    if (!stored) throw new UnauthorizedException('Token de rafraîchissement invalide');

    // Rotation : révoquer l'ancien token (sécurité)
    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { isRevoked: true },
    });

    const user = await this.prisma.user.findUnique({
      where: { id: stored.userId },
      include: { artisan: { select: { id: true } } },
    });
    if (!user) throw new UnauthorizedException();

    return this.generateTokens(user.id, user.email, user.role, user.artisan?.id);
  }

  async logout(userId: string, refreshToken: string) {
    await this.prisma.refreshToken.updateMany({
      where: { userId, token: refreshToken },
      data: { isRevoked: true },
    });
    return { message: 'Déconnexion réussie' };
  }

  private async generateTokens(
    userId: string,
    email: string,
    role: string,
    artisanId?: string,
  ) {
    const payload = { sub: userId, email, role, artisanId };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync(payload, {
        secret: this.config.get('JWT_ACCESS_SECRET'),
        expiresIn: this.config.get('JWT_ACCESS_EXPIRES', '15m'),
      }),
      this.jwt.signAsync(payload, {
        secret: this.config.get('JWT_REFRESH_SECRET'),
        expiresIn: this.config.get('JWT_REFRESH_EXPIRES', '7d'),
      }),
    ]);

    // Stocker le refresh token en base
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await this.prisma.refreshToken.create({
      data: { userId, token: refreshToken, expiresAt },
    });

    return { accessToken, refreshToken };
  }
}
