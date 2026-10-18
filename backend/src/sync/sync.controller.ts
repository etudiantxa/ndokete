import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SyncService, SyncPayloadDto } from './sync.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('sync')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ARTISAN')
@Controller('sync')
export class SyncController {
  constructor(private syncService: SyncService) {}

  @Post('batch')
  @ApiOperation({
    summary: 'Synchroniser les opérations offline (Hive → PostgreSQL)',
    description: 'Reçoit un lot d\'opérations effectuées hors-ligne et les applique au serveur.',
  })
  processBatch(
    @CurrentUser('artisanId') artisanId: string,
    @Body() dto: SyncPayloadDto,
  ) {
    return this.syncService.processSyncBatch(artisanId, dto);
  }

  @Get('conflicts')
  @ApiOperation({ summary: 'Lister les conflits de synchronisation' })
  getConflicts(@CurrentUser('artisanId') artisanId: string) {
    return this.syncService.getPendingConflicts(artisanId);
  }
}
