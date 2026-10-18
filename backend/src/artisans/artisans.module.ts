import { Module } from '@nestjs/common';
import { ArtisansController } from './artisans.controller';
import { ArtisansService } from './artisans.service';
import { OrdersController } from './orders/orders.controller';
import { OrdersService } from './orders/orders.service';
import { ClientsController } from './clients/clients.controller';
import { ClientsService } from './clients/clients.service';
import { StockController } from './stock/stock.controller';
import { StockService } from './stock/stock.service';
import { TransactionsController } from './transactions/transactions.controller';
import { TransactionsService } from './transactions/transactions.service';

@Module({
  controllers: [
    ArtisansController,
    OrdersController,
    ClientsController,
    StockController,
    TransactionsController,
  ],
  providers: [
    ArtisansService,
    OrdersService,
    ClientsService,
    StockService,
    TransactionsService,
  ],
  exports: [ArtisansService],
})
export class ArtisansModule {}
