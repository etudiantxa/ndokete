"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const nest_winston_1 = require("nest-winston");
const winston = require("winston");
const Joi = require("joi");
const auth_module_1 = require("./auth/auth.module");
const users_module_1 = require("./users/users.module");
const artisans_module_1 = require("./artisans/artisans.module");
const marketplace_module_1 = require("./marketplace/marketplace.module");
const payments_module_1 = require("./payments/payments.module");
const notifications_module_1 = require("./notifications/notifications.module");
const analytics_module_1 = require("./analytics/analytics.module");
const sync_module_1 = require("./sync/sync.module");
const prisma_module_1 = require("./common/prisma/prisma.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                validationSchema: Joi.object({
                    NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),
                    PORT: Joi.number().default(3000),
                    DATABASE_URL: Joi.string().required(),
                    JWT_ACCESS_SECRET: Joi.string().required(),
                    JWT_REFRESH_SECRET: Joi.string().required(),
                    JWT_ACCESS_EXPIRES: Joi.string().default('15m'),
                    JWT_REFRESH_EXPIRES: Joi.string().default('7d'),
                    REDIS_URL: Joi.string().required(),
                    CLOUDINARY_CLOUD_NAME: Joi.string().required(),
                    CLOUDINARY_API_KEY: Joi.string().required(),
                    CLOUDINARY_API_SECRET: Joi.string().required(),
                    FIREBASE_PROJECT_ID: Joi.string().required(),
                    FIREBASE_PRIVATE_KEY: Joi.string().required(),
                    FIREBASE_CLIENT_EMAIL: Joi.string().required(),
                    WAVE_API_KEY: Joi.string().optional(),
                    WAVE_WEBHOOK_SECRET: Joi.string().optional(),
                    ORANGE_MONEY_API_KEY: Joi.string().optional(),
                    NDOKETE_COMMISSION_PCT: Joi.number().default(10),
                    CORS_ORIGINS: Joi.string().default('http://localhost:3000'),
                }),
            }),
            nest_winston_1.WinstonModule.forRootAsync({
                inject: [config_1.ConfigService],
                useFactory: (config) => ({
                    transports: [
                        new winston.transports.Console({
                            format: winston.format.combine(winston.format.timestamp(), winston.format.colorize(), winston.format.printf(({ level, message, timestamp, context }) => `${timestamp} [${context || 'NDOKETE'}] ${level}: ${message}`)),
                        }),
                        new winston.transports.File({
                            filename: 'logs/error.log',
                            level: 'error',
                            format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
                        }),
                        new winston.transports.File({
                            filename: 'logs/combined.log',
                            format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
                        }),
                    ],
                }),
            }),
            prisma_module_1.PrismaModule,
            auth_module_1.AuthModule,
            users_module_1.UsersModule,
            artisans_module_1.ArtisansModule,
            marketplace_module_1.MarketplaceModule,
            payments_module_1.PaymentsModule,
            notifications_module_1.NotificationsModule,
            analytics_module_1.AnalyticsModule,
            sync_module_1.SyncModule,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map