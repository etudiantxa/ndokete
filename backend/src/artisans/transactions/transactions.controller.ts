import { Controller, Get, Post, Delete, Body, Query, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { TransactionsService, CreateTransactionDto } from './transactions.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('artisans')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ARTISAN')
@Controller('artisans/transactions')
export class TransactionsController {
  constructor(private transactionsService: TransactionsService) {}

  @Get()
  @ApiOperation({ summary: 'Liste des transactions' })
  @ApiQuery({ name: 'period', required: false, enum: ['today', 'week', 'month', 'all'] })
  findAll(@CurrentUser('id') userId: string, @CurrentUser('artisanId') artisanId: string, @Query('period') period?: string) {
    return this.transactionsService.findAll(userId, artisanId, period);
  }

  @Get('treasury')
  @ApiOperation({ summary: 'Résumé trésorerie (recettes, dépenses, bénéfice net)' })
  @ApiQuery({ name: 'period', required: false })
  getTreasury(@CurrentUser('id') userId: string, @CurrentUser('artisanId') artisanId: string, @Query('period') period?: string) {
    return this.transactionsService.getTreasurySummary(userId, artisanId, period);
  }

  @Get('weekly')
  @ApiOperation({ summary: 'Évolution hebdomadaire sur 4 semaines' })
  getWeekly(@CurrentUser('id') userId: string, @CurrentUser('artisanId') artisanId: string) {
    return this.transactionsService.getWeeklyEvolution(userId, artisanId);
  }

  @Get('report/:year/:month')
  @ApiOperation({ summary: 'Rapport financier mensuel (exportable PDF côté Flutter)' })
  getReport(
    @CurrentUser('id') userId: string,
    @CurrentUser('artisanId') artisanId: string,
    @Param('year') year: number,
    @Param('month') month: number,
  ) {
    return this.transactionsService.getMonthlyReport(userId, artisanId, month, year);
  }

  @Post()
  @ApiOperation({ summary: 'Enregistrer une nouvelle transaction' })
  create(@CurrentUser('id') userId: string, @CurrentUser('artisanId') artisanId: string, @Body() dto: CreateTransactionDto) {
    return this.transactionsService.create(userId, artisanId, dto);
  }

  @Delete(':id')
  remove(@CurrentUser('id') userId: string, @CurrentUser('artisanId') artisanId: string, @Param('id') id: string) {
    return this.transactionsService.remove(userId, artisanId, id);
  }
}
