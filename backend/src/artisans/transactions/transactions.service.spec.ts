import { Test, TestingModule } from '@nestjs/testing';
import { TransactionsService } from './transactions.service';
import { PrismaService } from '../../common/prisma/prisma.service';
import { ForbiddenException } from '@nestjs/common';

describe('TransactionsService', () => {
  let service: TransactionsService;

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
    },
    teamMember: {
      findMany: jest.fn(),
    },
    transaction: {
      findMany: jest.fn(),
      aggregate: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      findFirst: jest.fn(),
      delete: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TransactionsService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<TransactionsService>(TransactionsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('resolveArtisanId', () => {
    it('should throw ForbiddenException if user not found', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      await expect(service.resolveArtisanId('user-999')).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should return artisanId directly if user is ADMIN and inspection ID is provided', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: 'admin-1',
        role: 'ADMIN',
      });

      const result = await service.resolveArtisanId('admin-1', 'inspected-artisan-123');
      expect(result).toEqual('inspected-artisan-123');
    });

    it('should return artisan.id if user is artisan owner', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: 'user-1',
        role: 'ARTISAN',
        artisan: { id: 'artisan-owner-123' },
      });

      const result = await service.resolveArtisanId('user-1');
      expect(result).toEqual('artisan-owner-123');
    });
  });
});
