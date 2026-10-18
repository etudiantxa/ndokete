import {
  Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { StockService, CreateStockItemDto, AdjustStockDto } from './stock.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('artisans')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ARTISAN')
@Controller('artisans/stock')
export class StockController {
  constructor(private stockService: StockService) {}

  @Get()
  @ApiOperation({ summary: 'Inventaire des matières premières' })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'lowStock', required: false, type: Boolean })
  findAll(
    @CurrentUser('artisanId') artisanId: string,
    @Query('category') category?: string,
    @Query('lowStock') lowStock?: boolean,
  ) {
    return this.stockService.findAll(artisanId, category, lowStock);
  }

  @Get('alerts')
  @ApiOperation({ summary: 'Articles en stock critique' })
  getLowStockAlerts(@CurrentUser('artisanId') artisanId: string) {
    return this.stockService.getLowStockAlerts(artisanId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détails d\'un article + historique mouvements' })
  findOne(@CurrentUser('artisanId') artisanId: string, @Param('id') id: string) {
    return this.stockService.findOne(artisanId, id);
  }

  @Post()
  @ApiOperation({ summary: 'Ajouter un article de stock' })
  create(@CurrentUser('artisanId') artisanId: string, @Body() dto: CreateStockItemDto) {
    return this.stockService.create(artisanId, dto);
  }

  @Patch(':id/adjust')
  @ApiOperation({ summary: 'Ajuster le stock (entrée, sortie, ajustement)' })
  adjust(
    @CurrentUser('artisanId') artisanId: string,
    @Param('id') id: string,
    @Body() dto: AdjustStockDto,
  ) {
    return this.stockService.adjustStock(artisanId, id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser('artisanId') artisanId: string,
    @Param('id') id: string,
    @Body() dto: Partial<CreateStockItemDto>,
  ) {
    return this.stockService.update(artisanId, id, dto);
  }

  @Delete(':id')
  remove(@CurrentUser('artisanId') artisanId: string, @Param('id') id: string) {
    return this.stockService.remove(artisanId, id);
  }
}
