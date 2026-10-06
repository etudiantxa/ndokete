import { Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../common/prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async updateFcmToken(userId: string, fcmToken: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
    return { message: 'Token FCM mis à jour' };
  }

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true, email: true, phone: true, role: true, isVerified: true, createdAt: true,
        artisan: {
          select: {
            id: true, businessName: true, specialty: true, quarter: true,
            description: true, profilePhoto: true, subscription: true,
            _count: { select: { customers: true, products: true } },
          },
        },
        client: { select: { id: true, createdAt: true } },
      },
    });
    if (!user) throw new NotFoundException('Utilisateur non trouvé');
    return user;
  }

  async updateMe(userId: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true, artisan: { select: { id: true } } },
    });
    if (!user) throw new NotFoundException('Utilisateur non trouvé');

    if (dto.phone) {
      const phoneOwner = await this.prisma.user.findFirst({
        where: { phone: dto.phone, NOT: { id: userId } },
      });
      if (phoneOwner) throw new UnauthorizedException('Ce numéro est déjà utilisé');
    }

    if (user.role === 'ARTISAN' && user.artisan) {
      await this.prisma.$transaction([
        this.prisma.user.update({
          where: { id: userId },
          data: dto.phone ? { phone: dto.phone } : {},
        }),
        this.prisma.artisan.update({
          where: { id: user.artisan.id },
          data: {
            ...(dto.businessName !== undefined ? { businessName: dto.businessName } : {}),
            ...(dto.bio !== undefined ? { description: dto.bio } : {}),
            ...(dto.location !== undefined ? { quarter: dto.location } : {}),
          },
        }),
      ]);
    } else {
      await this.prisma.user.update({
        where: { id: userId },
        data: dto.phone ? { phone: dto.phone } : {},
      });
    }

    return this.getMe(userId);
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { passwordHash: true },
    });
    if (!user) throw new NotFoundException('Utilisateur non trouvé');
    const valid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Mot de passe actuel incorrect');
    const passwordHash = await bcrypt.hash(dto.newPassword, 12);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
    return { message: 'Mot de passe modifié' };
  }
}
