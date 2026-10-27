import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { IsBoolean, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import * as bcrypt from 'bcryptjs';

export class CreateTeamMemberDto {
  @IsString() @IsNotEmpty()
  name: string;

  @IsString() @IsNotEmpty()
  phone: string;

  @IsOptional() @IsString()
  role?: string;

  @IsOptional() @IsBoolean()
  canManageFinances?: boolean;
}

@Injectable()
export class TeamService {
  constructor(private prisma: PrismaService) {}

  async getTeam(artisanId: string) {
    const members = await this.prisma.teamMember.findMany({
      where: { artisanId },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data: members, message: 'Équipe récupérée avec succès' };
  }

  async addMember(artisanId: string, dto: CreateTeamMemberDto) {
    let user = await this.prisma.user.findFirst({ where: { phone: dto.phone } });
    if (!user) {
      const passwordHash = await bcrypt.hash('Demo1234!', 12);
      user = await this.prisma.user.create({
        data: {
          email: `${dto.phone.replace(/[^0-9]/g, '')}@ndokete.sn`,
          phone: dto.phone,
          passwordHash,
          role: 'ARTISAN',
          isVerified: true,
        },
      });
    }

    const member = await this.prisma.teamMember.create({
      data: {
        artisanId,
        name: dto.name,
        phone: dto.phone,
        role: dto.role || 'Apprenti',
        canManageFinances: dto.canManageFinances ?? false,
      },
    });

    return {
      success: true,
      data: { member, temporaryPassword: 'Demo1234!' },
      message: 'Membre ajouté et accès généré (Mot de passe provisoire: Demo1234!)',
    };
  }

  async removeMember(artisanId: string, memberId: string) {
    const member = await this.prisma.teamMember.findFirst({
      where: { id: memberId, artisanId },
    });
    if (!member) throw new NotFoundException('Membre non trouvé');

    await this.prisma.teamMember.delete({ where: { id: memberId } });
    return { success: true, message: 'Membre supprimé avec succès' };
  }
}
