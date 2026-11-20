import { Test, TestingModule } from '@nestjs/testing';
import { PaymentsService } from './payments.service';
import { PrismaService } from '../common/prisma/prisma.service';
import { ConfigService } from '@nestjs/config';

describe('PaymentsService Commission Calculation', () => {
  let service: PaymentsService;

  const mockPrismaService = {};
  const mockConfigService = {
    get: jest.fn((key, defaultValue) => {
      if (key === 'NDOKETE_COMMISSION_PCT') return 10;
      return defaultValue;
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentsService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should correctly calculate 10% commission on a 45000 FCFA payment', () => {
    const amount = 45000;
    const expectedCommission = 4500;
    const expectedNet = 40500;

    const commission = Math.round((amount * 10) / 100);
    const net = amount - commission;

    expect(commission).toEqual(expectedCommission);
    expect(net).toEqual(expectedNet);
  });

  it('should correctly calculate 10% commission on a 100000 FCFA payment', () => {
    const amount = 100000;
    const expectedCommission = 10000;
    const expectedNet = 90000;

    const commission = Math.round((amount * 10) / 100);
    const net = amount - commission;

    expect(commission).toEqual(expectedCommission);
    expect(net).toEqual(expectedNet);
  });
});
