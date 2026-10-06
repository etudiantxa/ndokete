import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { StockMovementType } from '@prisma/client';
import { IsEnum, IsNumber, IsOptional, IsString, Min, IsNotEmpty } from 'class-validator';

export class CreateStockItemDto {
  @IsString() @IsNotEmpty()
  name: string;
  @IsString() @IsNotEmpty()
  category: string;
  @IsString() @IsNotEmpty()
  unit: string;
  @IsNumber() @Min(0)
  quantity: number;
  @IsOptional() @IsNumber() @Min(0)
  alertThreshold?: number;
  @IsOptional() @IsNumber() @Min(0)
  costPerUnit?: number;
  @IsOptional() @IsString()
  supplier?: string;
  @IsOptional() @IsString()
  supplierPhone?: string;
  @IsOptional() @IsString()
  photo?: string;
}

export class AdjustStockDto {
  @IsEnum(StockMovementType)
  type: StockMovementType;
  @IsNumber() @Min(0)
  quantity: number;
  @IsOptional() @IsString()
  reason?: string;
  @IsOptional() @IsString()
  orderId?: string;
}

@Injectable()
export class StockService {
  constructor(private prisma: PrismaService) {}

  async findAll(artisanId: string, category?: string, lowStock?: boolean) {
    const items = await this.prisma.stockItem.findMany({
      where: {
        artisanId,
        ...(category && { category }),
      },
      include: {
        movements: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    // Filtrer les stocks faibles si demandé
    if (lowStock) {
      return items.filter((item) => item.quantity <= item.alertThreshold);
    }
    return items;
  }

  async findOne(artisanId: string, itemId: string) {
    const item = await this.prisma.stockItem.findFirst({
      where: { id: itemId, artisanId },
      include: {
        movements: {
          orderBy: { createdAt: 'desc' },
          take: 20,
        },
      },
    });
    if (!item) throw new NotFoundException('Article non trouvé');
    return item;
  }

  async create(artisanId: string, dto: CreateStockItemDto) {
    const item = await this.prisma.stockItem.create({
      data: {
        artisanId,
        name: dto.name,
        category: dto.category,
        unit: dto.unit,
        quantity: dto.quantity,
        alertThreshold: dto.alertThreshold ?? 5,
        costPerUnit: dto.costPerUnit ?? 0,
        supplier: dto.supplier,
        supplierPhone: dto.supplierPhone,
        photo: dto.photo,
      },
    });

    // Enregistrer le mouvement initial
    if (dto.quantity > 0) {
      await this.prisma.stockMovement.create({
        data: {
          stockItemId: item.id,
          type: 'ENTREE',
          quantity: dto.quantity,
          reason: 'Stock initial',
        },
      });
    }

    return { data: item, message: 'Article de stock créé' };
  }

  async adjustStock(artisanId: string, itemId: string, dto: AdjustStockDto) {
    const item = await this.prisma.stockItem.findFirst({
      where: { id: itemId, artisanId },
    });
    if (!item) throw new NotFoundException('Article non trouvé');
    if (dto.type === 'SORTIE' && dto.quantity > item.quantity) {
      throw new BadRequestException('Stock insuffisant pour cette sortie');
    }

    // Calculer la nouvelle quantité
    let newQuantity = item.quantity;
    if (dto.type === 'ENTREE') {
      newQuantity += dto.quantity;
    } else if (dto.type === 'SORTIE') {
      newQuantity = Math.max(0, newQuantity - dto.quantity);
    } else {
      newQuantity = dto.quantity; // AJUSTEMENT direct
    }

    const [updatedItem] = await this.prisma.$transaction([
      this.prisma.stockItem.update({
        where: { id: itemId },
        data: { quantity: newQuantity },
      }),
      this.prisma.stockMovement.create({
        data: {
          stockItemId: itemId,
          type: dto.type,
          quantity: dto.quantity,
          reason: dto.reason,
          orderId: dto.orderId,
        },
      }),
    ]);

    // Alerte si stock critique
    const isAlert = updatedItem.quantity <= updatedItem.alertThreshold;

    return {
      data: updatedItem,
      message: 'Stock ajusté',
      alert: isAlert ? `Stock critique : ${updatedItem.quantity} ${updatedItem.unit}` : null,
    };
  }

  async getLowStockAlerts(artisanId: string) {
    const items = await this.prisma.stockItem.findMany({ where: { artisanId } });
    return items.filter((item) => item.quantity <= item.alertThreshold);
  }

  async update(artisanId: string, itemId: string, dto: Partial<CreateStockItemDto>) {
    const item = await this.prisma.stockItem.findFirst({ where: { id: itemId, artisanId } });
    if (!item) throw new NotFoundException('Article non trouvé');
    const updated = await this.prisma.stockItem.update({
      where: { id: itemId },
      data: dto,
    });
    return { data: updated, message: 'Article de stock mis à jour' };
  }

  async remove(artisanId: string, itemId: string) {
    const item = await this.prisma.stockItem.findFirst({ where: { id: itemId, artisanId } });
    if (!item) throw new NotFoundException('Article non trouvé');
    await this.prisma.stockItem.delete({ where: { id: itemId } });
    return { message: 'Article de stock supprimé' };
  }
}
