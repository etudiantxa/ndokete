"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const bcrypt = require("bcryptjs");
const prisma_service_1 = require("../common/prisma/prisma.service");
const client_1 = require("@prisma/client");
let AuthService = class AuthService {
    constructor(prisma, jwt, config) {
        this.prisma = prisma;
        this.jwt = jwt;
        this.config = config;
    }
    async register(dto) {
        const existing = await this.prisma.user.findFirst({
            where: { OR: [{ email: dto.email }, { phone: dto.phone }] },
        });
        if (existing) {
            throw new common_1.ConflictException('Email ou téléphone déjà utilisé');
        }
        const passwordHash = await bcrypt.hash(dto.password, 12);
        const user = await this.prisma.user.create({
            data: {
                email: dto.email,
                phone: dto.phone,
                passwordHash,
                role: dto.role,
            },
        });
        if (dto.role === client_1.Role.ARTISAN) {
            if (!dto.businessName || !dto.quarter) {
                throw new common_1.BadRequestException('businessName et quarter requis pour un artisan');
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
        }
        else if (dto.role === client_1.Role.CLIENT) {
            await this.prisma.client.create({
                data: { userId: user.id },
            });
        }
        const tokens = await this.generateTokens(user.id, user.email, user.role, undefined);
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
    async login(dto) {
        const user = await this.prisma.user.findFirst({
            where: {
                OR: [{ email: dto.identifier }, { phone: dto.identifier }],
                isActive: true,
            },
            include: { artisan: { select: { id: true } } },
        });
        if (!user)
            throw new common_1.UnauthorizedException('Identifiants incorrects');
        const passwordValid = await bcrypt.compare(dto.password, user.passwordHash);
        if (!passwordValid)
            throw new common_1.UnauthorizedException('Identifiants incorrects');
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
    async refreshTokens(refreshToken) {
        const stored = await this.prisma.refreshToken.findFirst({
            where: {
                token: refreshToken,
                isRevoked: false,
                expiresAt: { gt: new Date() },
            },
        });
        if (!stored)
            throw new common_1.UnauthorizedException('Token de rafraîchissement invalide');
        await this.prisma.refreshToken.update({
            where: { id: stored.id },
            data: { isRevoked: true },
        });
        const user = await this.prisma.user.findUnique({
            where: { id: stored.userId },
            include: { artisan: { select: { id: true } } },
        });
        if (!user)
            throw new common_1.UnauthorizedException();
        return this.generateTokens(user.id, user.email, user.role, user.artisan?.id);
    }
    async logout(userId, refreshToken) {
        await this.prisma.refreshToken.updateMany({
            where: { userId, token: refreshToken },
            data: { isRevoked: true },
        });
        return { message: 'Déconnexion réussie' };
    }
    async generateTokens(userId, email, role, artisanId) {
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
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7);
        await this.prisma.refreshToken.create({
            data: { userId, token: refreshToken, expiresAt },
        });
        return { accessToken, refreshToken };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        jwt_1.JwtService,
        config_1.ConfigService])
], AuthService);
//# sourceMappingURL=auth.service.js.map