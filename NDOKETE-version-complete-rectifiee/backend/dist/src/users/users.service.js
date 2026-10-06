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
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const bcrypt = require("bcryptjs");
const prisma_service_1 = require("../common/prisma/prisma.service");
let UsersService = class UsersService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async updateFcmToken(userId, fcmToken) {
        await this.prisma.user.update({
            where: { id: userId },
            data: { fcmToken },
        });
        return { message: 'Token FCM mis à jour' };
    }
    async getMe(userId) {
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
        if (!user)
            throw new common_1.NotFoundException('Utilisateur non trouvé');
        return user;
    }
    async updateMe(userId, dto) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            select: { id: true, role: true, artisan: { select: { id: true } } },
        });
        if (!user)
            throw new common_1.NotFoundException('Utilisateur non trouvé');
        if (dto.phone) {
            const phoneOwner = await this.prisma.user.findFirst({
                where: { phone: dto.phone, NOT: { id: userId } },
            });
            if (phoneOwner)
                throw new common_1.UnauthorizedException('Ce numéro est déjà utilisé');
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
        }
        else {
            await this.prisma.user.update({
                where: { id: userId },
                data: dto.phone ? { phone: dto.phone } : {},
            });
        }
        return this.getMe(userId);
    }
    async changePassword(userId, dto) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            select: { passwordHash: true },
        });
        if (!user)
            throw new common_1.NotFoundException('Utilisateur non trouvé');
        const valid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
        if (!valid)
            throw new common_1.UnauthorizedException('Mot de passe actuel incorrect');
        const passwordHash = await bcrypt.hash(dto.newPassword, 12);
        await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
        return { message: 'Mot de passe modifié' };
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], UsersService);
//# sourceMappingURL=users.service.js.map