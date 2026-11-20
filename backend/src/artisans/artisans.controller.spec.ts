import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, UnauthorizedException, ExecutionContext } from '@nestjs/common';
import * as request from 'supertest';
import { ArtisansController } from './artisans.controller';
import { ArtisansService } from './artisans.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';

describe('ArtisansController Access Control (Integration)', () => {
  let app: INestApplication;

  const mockArtisansService = {
    getDashboard: jest.fn().mockResolvedValue({ todaySales: 50000, activeOrders: 3 }),
  };

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [ArtisansController],
      providers: [
        { provide: ArtisansService, useValue: mockArtisansService },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => {
          const req = context.switchToHttp().getRequest();
          const authHeader = req.headers['authorization'];
          if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new UnauthorizedException();
          }
          req.user = { id: 'user-1', role: 'ARTISAN', artisanId: 'artisan-1' };
          return true;
        },
      })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('/api/v1/artisans/dashboard (GET) should return 401 if token is absent', () => {
    return request(app.getHttpServer())
      .get('/api/v1/artisans/dashboard')
      .expect(401);
  });

  it('/api/v1/artisans/dashboard (GET) should allow access and return dashboard data when valid bearer token is provided', () => {
    return request(app.getHttpServer())
      .get('/api/v1/artisans/dashboard')
      .set('Authorization', 'Bearer valid-jwt-token')
      .expect(200)
      .expect((res) => {
        expect(res.body.todaySales).toEqual(50000);
        expect(res.body.activeOrders).toEqual(3);
      });
  });
});
