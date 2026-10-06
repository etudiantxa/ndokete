"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MarketplaceModule = void 0;
const common_1 = require("@nestjs/common");
const products_controller_1 = require("./products/products.controller");
const products_service_1 = require("./products/products.service");
const marketplace_orders_controller_1 = require("./orders/marketplace-orders.controller");
const marketplace_orders_service_1 = require("./orders/marketplace-orders.service");
let MarketplaceModule = class MarketplaceModule {
};
exports.MarketplaceModule = MarketplaceModule;
exports.MarketplaceModule = MarketplaceModule = __decorate([
    (0, common_1.Module)({
        controllers: [products_controller_1.ProductsController, marketplace_orders_controller_1.MarketplaceOrdersController],
        providers: [products_service_1.ProductsService, marketplace_orders_service_1.MarketplaceOrdersService],
    })
], MarketplaceModule);
//# sourceMappingURL=marketplace.module.js.map