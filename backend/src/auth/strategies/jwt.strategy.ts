import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../common/prisma/prisma.service';

export interface JwtPayload {
  sub: string;
  email: string;
  role: string;
  artisanId?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    config: ConfigService,
    private prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_ACCESS_SECRET'),
    });
  }

  async validate(payload: JwtPayload) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { artisan: { select: { id: true } } },
    });
    if (!user || !user.isActive) throw new UnauthorizedException();

    let artisanId = user.artisan?.id;
    let isOwner = true;
    let canManageFinances = true;

    if (user.phone) {
      const cleanPhone = user.phone.replace(/[^0-9]/g, '');
      const allMembers = await this.prisma.teamMember.findMany();
      const matchedMember = allMembers.find(
        (m) => m.phone.replace(/[^0-9]/g, '').endsWith(cleanPhone.slice(-9)),
      );
      if (matchedMember) {
        artisanId = matchedMember.artisanId;
        isOwner = false;
        canManageFinances = matchedMember.canManageFinances;
      }
    }

    return {
      id: user.id,
      email: user.email,
      phone: user.phone,
      role: user.role,
      artisanId,
      isOwner,
      canManageFinances,
    };
  }
}
