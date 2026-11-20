import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

describe('AuthController Login (Integration)', () => {
  let app: INestApplication;

  const mockAuthService = {
    login: jest.fn().mockResolvedValue({
      accessToken: 'mock-jwt-token-123',
      refreshToken: 'mock-refresh-token-123',
      user: { id: 'user-1', email: 'moussa@ndokete.sn', role: 'ARTISAN' },
    }),
  };

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        { provide: AuthService, useValue: mockAuthService },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ transform: true }));
    app.setGlobalPrefix('api/v1');
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('/api/v1/auth/login (POST) should return JWT token on valid credentials', () => {
    return request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ identifier: 'moussa@ndokete.sn', password: 'Demo1234!' })
      .expect(200)
      .expect((res) => {
        expect(res.body.accessToken).toEqual('mock-jwt-token-123');
        expect(res.body.user.role).toEqual('ARTISAN');
      });
  });
});
