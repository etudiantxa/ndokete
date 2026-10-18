import {
  Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { CreateOrderDto, UpdateOrderDto } from '../dto/create-order.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { OrderStatus } from '@prisma/client';

@ApiTags('artisans')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ARTISAN')
@Controller('artisans/orders')
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  @Get()
  @ApiOperation({ summary: 'Lister les commandes de l\'atelier' })
  @ApiQuery({ name: 'status', required: false, enum: OrderStatus })
  @ApiQuery({ name: 'search', required: false })
  findAll(
    @CurrentUser('artisanId') artisanId: string,
    @Query('status') status?: OrderStatus,
    @Query('search') search?: string,
  ) {
    return this.ordersService.findAll(artisanId, status, search);
  }

  @Get('urgent')
  @ApiOperation({ summary: 'Commandes urgentes (3 jours ou marquées urgentes)' })
  getUrgent(@CurrentUser('artisanId') artisanId: string) {
    return this.ordersService.getUrgentOrders(artisanId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail d\'une commande' })
  findOne(@CurrentUser('artisanId') artisanId: string, @Param('id') id: string) {
    return this.ordersService.findOne(artisanId, id);
  }

  @Post()
  @ApiOperation({ summary: 'Créer une nouvelle commande' })
  create(@CurrentUser('artisanId') artisanId: string, @Body() dto: CreateOrderDto) {
    return this.ordersService.create(artisanId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Mettre à jour une commande (statut, progression, etc.)' })
  update(
    @CurrentUser('artisanId') artisanId: string,
    @Param('id') id: string,
    @Body() dto: UpdateOrderDto,
  ) {
    return this.ordersService.update(artisanId, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer une commande' })
  remove(@CurrentUser('artisanId') artisanId: string, @Param('id') id: string) {
    return this.ordersService.remove(artisanId, id);
  }

  @Post('reminders/bulk')
  @ApiOperation({ summary: 'Envoyer des rappels groupés pour commandes urgentes' })
  sendBulkReminders(@CurrentUser('artisanId') artisanId: string) {
    return this.ordersService.sendBulkReminders(artisanId);
  }
}
