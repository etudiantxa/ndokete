import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { ProductsController } from './products.controller';
import { ProductsService } from './products.service';

describe('ProductsController (Integration)', () => {
  let app: INestApplication;

  const mockProductsService = {
    getMarketplace: jest.fn().mockResolvedValue({
      success: true,
      data: [
        { id: 'prod-1', name: 'Boubou en basin', price: 45000, status: 'ACTIF' },
      ],
      total: 1,
    }),
  };

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [ProductsController],
      providers: [
        { provide: ProductsService, useValue: mockProductsService },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('/api/v1/marketplace (GET) should return public products list', () => {
    return request(app.getHttpServer())
      .get('/api/v1/marketplace')
      .expect(200)
      .expect((res) => {
        expect(res.body.success).toBe(true);
        expect(res.body.data).toHaveLength(1);
        expect(res.body.data[0].name).toEqual('Boubou en basin');
      });
  });
});
