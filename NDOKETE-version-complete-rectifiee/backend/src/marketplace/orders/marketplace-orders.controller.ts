import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { MarketplaceOrdersService, CreateMarketplaceOrderDto } from './marketplace-orders.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('marketplace')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('CLIENT')
@Controller('marketplace/orders')
export class MarketplaceOrdersController {
  constructor(private ordersService: MarketplaceOrdersService) {}

  @Get()
  @ApiOperation({ summary: 'Mes commandes marketplace' })
  getMyOrders(@CurrentUser('id') userId: string) {
    return this.ordersService.getClientOrders(userId);
  }

  @Post()
  @ApiOperation({ summary: 'Passer une commande marketplace' })
  create(@CurrentUser('id') userId: string, @Body() dto: CreateMarketplaceOrderDto) {
    return this.ordersService.createOrder(userId, dto);
  }
}
