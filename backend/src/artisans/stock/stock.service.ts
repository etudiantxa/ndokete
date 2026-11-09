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

  async getAuthorName(userId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { artisan: { select: { businessName: true } }, client: { select: { name: true } } },
    });
    if (!user) return 'Atelier';

    // 1. Si c'est un membre d'équipe / apprenti
    if (user.phone) {
      const cleanPhone = user.phone.replace(/[^0-9]/g, '');
      const allMembers = await this.prisma.teamMember.findMany();
      const matchedMember = allMembers.find(
        (m) => m.phone.replace(/[^0-9]/g, '').endsWith(cleanPhone.slice(-9)),
      );
      if (matchedMember) {
        return matchedMember.name;
      }
    }

    // 2. Si c'est le propriétaire de l'atelier
    if (user.artisan?.businessName) {
      return user.artisan.businessName;
    }

    if (user.client?.name) {
      return user.client.name;
    }

    return user.email.split('@')[0] || 'Atelier';
  }

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

  async create(userId: string, artisanId: string, dto: CreateStockItemDto) {
    const authorName = await this.getAuthorName(userId);
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
        authorName,
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
          authorName,
        },
      });
    }

    return { data: item, message: 'Article de stock créé' };
  }

  async adjustStock(userId: string, artisanId: string, itemId: string, dto: AdjustStockDto) {
    const authorName = await this.getAuthorName(userId);
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
          authorName,
        },
      }),
    ]);

    // Récupérer l'article à jour avec son historique de mouvements
    const fullItem = await this.findOne(artisanId, itemId);
    const isAlert = fullItem.quantity <= fullItem.alertThreshold;

    return {
      data: fullItem,
      message: 'Stock ajusté',
      alert: isAlert ? `Stock critique : ${fullItem.quantity} ${fullItem.unit}` : null,
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
