import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { WINSTON_MODULE_NEST_PROVIDER } from 'nest-winston';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  // Logger Winston
  app.useLogger(app.get(WINSTON_MODULE_NEST_PROVIDER));

  // Sécurité
  app.use(helmet());
  app.enableCors({
    origin: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000', 'http://localhost:5000'],
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    credentials: true,
  });

  // WebSocket (Socket.io pour notifications temps réel)
  app.useWebSocketAdapter(new IoAdapter(app));

  // Validation globale des DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalInterceptors(new ResponseInterceptor());
  app.useGlobalFilters(new AllExceptionsFilter());

  // Préfixe global API
  app.setGlobalPrefix('api/v1');

  // Documentation Swagger
  const config = new DocumentBuilder()
    .setTitle('NDOKETE API')
    .setDescription('API pour la plateforme NDOKETE — artisans sénégalais')
    .setVersion('1.0')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      'access-token',
    )
    .addTag('auth', 'Authentification & autorisation')
    .addTag('artisans', 'Gestion atelier artisan')
    .addTag('marketplace', 'Marketplace produits')
    .addTag('payments', 'Paiements Wave & Orange Money')
    .addTag('notifications', 'Notifications push & SMS')
    .addTag('analytics', 'KPIs & rapports')
    .addTag('sync', 'Synchronisation offline')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 NDOKETE API démarrée sur http://localhost:${port}`);
  console.log(`📖 Swagger docs: http://localhost:${port}/api/docs`);
}
bootstrap();
