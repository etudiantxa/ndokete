import { Controller, Get, Patch, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('analytics')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('analytics')
export class AnalyticsController {
  constructor(private analyticsService: AnalyticsService) {}

  @Roles('ARTISAN')
  @Get('artisan')
  @ApiOperation({ summary: 'KPIs artisan (revenus, croissance, commandes actives)' })
  getArtisanKPIs(@CurrentUser('artisanId') artisanId: string) {
    return this.analyticsService.getArtisanKPIs(artisanId);
  }

  @Roles('ADMIN')
  @Get('admin')
  @ApiOperation({ summary: 'KPIs admin (MRR, churn, artisans premium)' })
  getAdminKPIs() {
    return this.analyticsService.getAdminKPIs();
  }

  @Roles('ADMIN')
  @Get('admin/artisans')
  @ApiOperation({ summary: 'Liste de tous les artisans pour l\'admin' })
  getAdminArtisans() {
    return this.analyticsService.getAdminArtisans();
  }

  @Roles('ADMIN')
  @Patch('admin/artisans/:artisanId/plan')
  @ApiOperation({ summary: 'Changer manuellement le plan d\'un artisan' })
  updateArtisanPlan(
    @Param('artisanId') artisanId: string,
    @Body('plan') plan: 'FREE' | 'PREMIUM' | 'PREMIUM_PLUS',
  ) {
    return this.analyticsService.updateArtisanPlan(artisanId, plan);
  }
}
