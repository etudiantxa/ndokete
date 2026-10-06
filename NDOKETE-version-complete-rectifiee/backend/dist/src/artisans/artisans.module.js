"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ArtisansModule = void 0;
const common_1 = require("@nestjs/common");
const artisans_controller_1 = require("./artisans.controller");
const artisans_service_1 = require("./artisans.service");
const orders_controller_1 = require("./orders/orders.controller");
const orders_service_1 = require("./orders/orders.service");
const clients_controller_1 = require("./clients/clients.controller");
const clients_service_1 = require("./clients/clients.service");
const stock_controller_1 = require("./stock/stock.controller");
const stock_service_1 = require("./stock/stock.service");
const transactions_controller_1 = require("./transactions/transactions.controller");
const transactions_service_1 = require("./transactions/transactions.service");
let ArtisansModule = class ArtisansModule {
};
exports.ArtisansModule = ArtisansModule;
exports.ArtisansModule = ArtisansModule = __decorate([
    (0, common_1.Module)({
        controllers: [
            artisans_controller_1.ArtisansController,
            orders_controller_1.OrdersController,
            clients_controller_1.ClientsController,
            stock_controller_1.StockController,
            transactions_controller_1.TransactionsController,
        ],
        providers: [
            artisans_service_1.ArtisansService,
            orders_service_1.OrdersService,
            clients_service_1.ClientsService,
            stock_service_1.StockService,
            transactions_service_1.TransactionsService,
        ],
        exports: [artisans_service_1.ArtisansService],
    })
], ArtisansModule);
//# sourceMappingURL=artisans.module.js.map