import { Controller, Get, Patch, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ArtisansService } from './artisans.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('artisans')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('artisans')
export class ArtisansController {
  constructor(private artisansService: ArtisansService) {}

  @Roles('ARTISAN')
  @Get('profile')
  @ApiOperation({ summary: 'Profil complet de l\'artisan connecté' })
  getProfile(@CurrentUser('artisanId') artisanId: string) {
    return this.artisansService.getProfile(artisanId);
  }

  @Roles('ARTISAN')
  @Get('dashboard')
  @ApiOperation({ summary: 'Tableau de bord artisan (KPIs journaliers)' })
  getDashboard(@CurrentUser('artisanId') artisanId: string) {
    return this.artisansService.getDashboard(artisanId);
  }

  @Roles('ARTISAN')
  @Patch('profile')
  @ApiOperation({ summary: 'Mettre à jour le profil artisan' })
  updateProfile(@CurrentUser('artisanId') artisanId: string, @Body() body: any) {
    return this.artisansService.updateProfile(artisanId, body);
  }

  @Public()
  @Get(':id/public')
  @ApiOperation({ summary: 'Profil public d\'un artisan (marketplace)' })
  getPublicProfile(@Param('id') id: string) {
    return this.artisansService.getPublicProfile(id);
  }
}
