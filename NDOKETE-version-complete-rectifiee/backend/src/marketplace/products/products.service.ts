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
  @IsOptional() @IsString()
  status?: 'ACTIF' | 'INACTIF' | 'EN_RUPTURE';
}

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  // Accueil marketplace public (clients & diaspora)
  async getMarketplace(search?: string, category?: string, page = 1, limit = 20) {
    try {
      const skip = (page - 1) * limit;
      
      // Construire la clause where
      const where: any = {
        status: ProductStatus.ACTIF,
      };

      if (category) {
        where.category = category;
      }

      if (search) {
        where.OR = [
          { name: { contains: search, mode: 'insensitive' } },
          { artisan: { businessName: { contains: search, mode: 'insensitive' } } },
        ];
      }

      const [products, total] = await Promise.all([
        this.prisma.product.findMany({
          where,
          include: {
            artisan: {
              select: { id: true, businessName: true, quarter: true, rating: true, profilePhoto: true },
            },
          },
          orderBy: [{ isVitrine: 'desc' }, { viewCount: 'desc' }],
          skip: skip,  // Explicitly provide skip parameter
          take: limit,
        }),
        this.prisma.product.count({ where }),
      ]);

      return { data: products, meta: { total, page, limit, totalPages: Math.ceil(total / limit) } };
    } catch (error) {
      console.error('❌ Error in getMarketplace:', error);
      console.error('Error details:', {
        message: error.message,
        stack: error.stack,
        code: error.code,
      });
      throw error;
    }
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
      where: { id: productId, status: ProductStatus.ACTIF },
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
        status: ProductStatus.ACTIF, // Produit actif par défaut
      },
    });

    return { data: product, message: 'Produit créé' };
  }

  async update(artisanId: string, productId: string, dto: Partial<CreateProductDto>) {
    const product = await this.prisma.product.findFirst({ where: { id: productId, artisanId } });
    if (!product) throw new NotFoundException('Produit non trouvé');

    // Convertir le statut de chaîne vers enum Prisma si nécessaire
    const dataToUpdate: any = { ...dto };
    if (dto.status && typeof dto.status === 'string') {
      dataToUpdate.status = ProductStatus[dto.status as keyof typeof ProductStatus];
    }

    const updated = await this.prisma.product.update({
      where: { id: productId },
      data: dataToUpdate,
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
