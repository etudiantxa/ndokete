import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { ProductStatus } from '@prisma/client';
import { IsArray, IsBoolean, IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';

export class CreateProductDto {
  @IsString() @IsNotEmpty()
  name: string;
  @IsOptional() @IsString()
  description?: string;
  @IsInt() @Min(0)
  price: number;
  @IsString() @IsNotEmpty()
  category: string;
  @IsArray() @IsString({ each: true })
  photos: string[];
  @IsInt() @Min(0)
  stock: number;
  @IsOptional() @IsArray() @IsString({ each: true })
  tags?: string[];
  @IsOptional() @IsBoolean()
  isVitrine?: boolean;
}

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  // Accueil marketplace public (clients & diaspora)
  async getMarketplace(search?: string, category?: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const where = {
      status: 'ACTIF' as ProductStatus,
      ...(category && { category }),
      ...(search && {
        OR: [
          { name: { contains: search, mode: 'insensitive' as const } },
          { artisan: { businessName: { contains: search, mode: 'insensitive' as const } } },
        ],
      }),
    };

    const [products, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        include: {
          artisan: {
            select: { id: true, businessName: true, quarter: true, rating: true, profilePhoto: true },
          },
        },
        orderBy: [{ isVitrine: 'desc' }, { viewCount: 'desc' }],
        skip,
        take: limit,
      }),
      this.prisma.product.count({ where }),
    ]);

    return { data: products, meta: { total, page, limit, totalPages: Math.ceil(total / limit) } };
  }

  // Boutique de l'artisan (ses propres produits)
  async getArtisanProducts(artisanId: string) {
    return this.prisma.product.findMany({
      where: { artisanId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getProductById(productId: string) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, status: 'ACTIF' },
      include: {
        artisan: {
          select: { id: true, businessName: true, quarter: true, rating: true, profilePhoto: true },
        },
      },
    });
    if (!product) throw new NotFoundException('Produit non trouvé');
    await this.prisma.product.update({
      where: { id: productId },
      data: { viewCount: { increment: 1 } },
    });
    return product;
  }

  async create(artisanId: string, dto: CreateProductDto) {
    // Vérifier limite plan FREE (5 produits max)
    const artisan = await this.prisma.artisan.findUnique({
      where: { id: artisanId },
      include: { subscription: true },
    });

    if (artisan?.subscription?.plan === 'FREE') {
      const count = await this.prisma.product.count({ where: { artisanId } });
      if (count >= 5) {
        throw new ForbiddenException(
          'Limite de 5 produits atteinte sur le plan gratuit. Passez au Premium !',
        );
      }
    }

    const product = await this.prisma.product.create({
      data: {
        artisanId,
        name: dto.name,
        description: dto.description,
        price: dto.price,
        category: dto.category,
        photos: dto.photos,
        stock: dto.stock,
        tags: dto.tags ?? [],
        isVitrine: dto.isVitrine ?? false,
      },
    });

    return { data: product, message: 'Produit créé' };
  }

  async update(artisanId: string, productId: string, dto: Partial<CreateProductDto>) {
    const product = await this.prisma.product.findFirst({ where: { id: productId, artisanId } });
    if (!product) throw new NotFoundException('Produit non trouvé');

    const updated = await this.prisma.product.update({
      where: { id: productId },
      data: dto as any,
    });
    return { data: updated, message: 'Produit mis à jour' };
  }

  async remove(artisanId: string, productId: string) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, artisanId },
    });
    if (!product) throw new NotFoundException('Produit non trouvé');
    await this.prisma.product.delete({ where: { id: productId } });
    return { message: 'Produit supprimé' };
  }

  async getProductStats(artisanId: string) {
    const products = await this.prisma.product.findMany({
      where: { artisanId },
      select: {
        id: true, name: true, viewCount: true, orderCount: true, price: true, status: true,
      },
    });

    const totalRevenue = await this.prisma.marketplaceOrderItem.aggregate({
      where: { artisanId },
      _sum: { unitPrice: true, quantity: true },
    });

    return {
      products,
      totalRevenue: (totalRevenue._sum.unitPrice ?? 0) *
        (totalRevenue._sum.quantity ?? 0),
      conversionRate: products.length > 0
        ? Math.round((products.reduce((a, p) => a + p.orderCount, 0) /
            Math.max(products.reduce((a, p) => a + p.viewCount, 0), 1)) * 100)
        : 0,
    };
  }
}
