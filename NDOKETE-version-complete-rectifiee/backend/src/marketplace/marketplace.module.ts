import { Module } from '@nestjs/common';
import { ProductsController } from './products/products.controller';
import { ProductsService } from './products/products.service';
import { MarketplaceOrdersController } from './orders/marketplace-orders.controller';
import { MarketplaceOrdersService } from './orders/marketplace-orders.service';

@Module({
  controllers: [ProductsController, MarketplaceOrdersController],
  providers: [ProductsService, MarketplaceOrdersService],
})
export class MarketplaceModule {}
