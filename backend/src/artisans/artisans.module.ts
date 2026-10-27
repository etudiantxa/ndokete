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
import { AiMeasurementsController } from './ai/ai-measurements.controller';
import { AiMeasurementsService } from './ai/ai-measurements.service';
import { TeamController } from './team/team.controller';
import { TeamService } from './team/team.service';

@Module({
  controllers: [
    ArtisansController,
    OrdersController,
    ClientsController,
    StockController,
    TransactionsController,
    AiMeasurementsController,
    TeamController,
  ],
  providers: [
    ArtisansService,
    OrdersService,
    ClientsService,
    StockService,
    TransactionsService,
    AiMeasurementsService,
    TeamService,
  ],
  exports: [ArtisansService],
})
export class ArtisansModule {}
