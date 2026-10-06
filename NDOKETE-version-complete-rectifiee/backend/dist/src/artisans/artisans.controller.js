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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ArtisansController = void 0;
const openapi = require("@nestjs/swagger");
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const artisans_service_1 = require("./artisans.service");
const jwt_auth_guard_1 = require("../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../common/guards/roles.guard");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const public_decorator_1 = require("../common/decorators/public.decorator");
let ArtisansController = class ArtisansController {
    constructor(artisansService) {
        this.artisansService = artisansService;
    }
    getProfile(artisanId) {
        return this.artisansService.getProfile(artisanId);
    }
    getDashboard(artisanId) {
        return this.artisansService.getDashboard(artisanId);
    }
    updateProfile(artisanId, body) {
        return this.artisansService.updateProfile(artisanId, body);
    }
    getPublicProfile(id) {
        return this.artisansService.getPublicProfile(id);
    }
};
exports.ArtisansController = ArtisansController;
__decorate([
    (0, roles_decorator_1.Roles)('ARTISAN'),
    (0, common_1.Get)('profile'),
    (0, swagger_1.ApiOperation)({ summary: 'Profil complet de l\'artisan connecté' }),
    openapi.ApiResponse({ status: 200, type: Object }),
    __param(0, (0, current_user_decorator_1.CurrentUser)('artisanId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ArtisansController.prototype, "getProfile", null);
__decorate([
    (0, roles_decorator_1.Roles)('ARTISAN'),
    (0, common_1.Get)('dashboard'),
    (0, swagger_1.ApiOperation)({ summary: 'Tableau de bord artisan (KPIs journaliers)' }),
    openapi.ApiResponse({ status: 200 }),
    __param(0, (0, current_user_decorator_1.CurrentUser)('artisanId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ArtisansController.prototype, "getDashboard", null);
__decorate([
    (0, roles_decorator_1.Roles)('ARTISAN'),
    (0, common_1.Patch)('profile'),
    (0, swagger_1.ApiOperation)({ summary: 'Mettre à jour le profil artisan' }),
    openapi.ApiResponse({ status: 200 }),
    __param(0, (0, current_user_decorator_1.CurrentUser)('artisanId')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], ArtisansController.prototype, "updateProfile", null);
__decorate([
    (0, public_decorator_1.Public)(),
    (0, common_1.Get)(':id/public'),
    (0, swagger_1.ApiOperation)({ summary: 'Profil public d\'un artisan (marketplace)' }),
    openapi.ApiResponse({ status: 200, type: Object }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ArtisansController.prototype, "getPublicProfile", null);
exports.ArtisansController = ArtisansController = __decorate([
    (0, swagger_1.ApiTags)('artisans'),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.Controller)('artisans'),
    __metadata("design:paramtypes", [artisans_service_1.ArtisansService])
], ArtisansController);
//# sourceMappingURL=artisans.controller.js.map