import { Test, TestingModule } from '@nestjs/testing';
import { SubscriptionsService } from './subscriptions.service';
import { PrismaService } from '../common/prisma/prisma.service';
import { SubscriptionPlan, PaymentMethod } from '@prisma/client';
import { NotFoundException, BadRequestException } from '@nestjs/common';

describe('SubscriptionsService', () => {
  let service: SubscriptionsService;

  const mockPrismaService = {
    artisan: {
      findUnique: jest.fn(),
    },
    subscription: {
      upsert: jest.fn(),
    },
    payment: {
      create: jest.fn(),
    },
    notification: {
      create: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SubscriptionsService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<SubscriptionsService>(SubscriptionsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('upgradePlan', () => {
    it('should throw NotFoundException if artisan profile not found', async () => {
      mockPrismaService.artisan.findUnique.mockResolvedValue(null);

      await expect(
        service.upgradePlan('user-123', {
          plan: SubscriptionPlan.PREMIUM,
          method: PaymentMethod.WAVE,
          phone: '+221771234567',
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException if plan is FREE', async () => {
      mockPrismaService.artisan.findUnique.mockResolvedValue({ id: 'artisan-123' });

      await expect(
        service.upgradePlan('user-123', {
          plan: SubscriptionPlan.FREE,
          method: PaymentMethod.WAVE,
          phone: '+221771234567',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should successfully upgrade plan to PREMIUM and record payment', async () => {
      mockPrismaService.artisan.findUnique.mockResolvedValue({ id: 'artisan-123' });
      mockPrismaService.subscription.upsert.mockResolvedValue({
        id: 'sub-123',
        plan: SubscriptionPlan.PREMIUM,
        status: 'ACTIVE',
      });
      mockPrismaService.payment.create.mockResolvedValue({ id: 'pay-123' });
      mockPrismaService.notification.create.mockResolvedValue({ id: 'notif-123' });

      const result = await service.upgradePlan('user-123', {
        plan: SubscriptionPlan.PREMIUM,
        method: PaymentMethod.WAVE,
        phone: '+221771234567',
      });

      expect(result).toBeDefined();
      expect(mockPrismaService.subscription.upsert).toHaveBeenCalled();
      expect(mockPrismaService.payment.create).toHaveBeenCalled();
    });
  });
});
