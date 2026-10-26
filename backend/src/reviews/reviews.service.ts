import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async createReview(userId: string, dto: CreateReviewDto) {
    const client = await this.prisma.client.findUnique({ where: { userId } });
    if (!client) throw new NotFoundException('Profil client non trouvé');

    const artisan = await this.prisma.artisan.findUnique({ where: { id: dto.artisanId } });
    if (!artisan) throw new NotFoundException('Artisan non trouvé');

    const review = await this.prisma.review.create({
      data: {
        artisanId: dto.artisanId,
        clientId: client.id,
        marketplaceOrderId: dto.marketplaceOrderId,
        rating: dto.rating,
        comment: dto.comment,
      },
      include: { client: true },
    });

    await this.prisma.notification.create({
      data: {
        userId: artisan.userId,
        type: 'NOUVEAU_AVIS',
        channel: 'IN_APP',
        title: '⭐ Nouvel avis reçu !',
        body: `Un client vous a attribué ${dto.rating}/5 étoiles : "${dto.comment || 'Aucun commentaire'}"`,
        data: { reviewId: review.id },
      },
    });

    return { success: true, data: review, message: 'Avis enregistré avec succès' };
  }

  async getArtisanReviews(artisanId: string) {
    const reviews = await this.prisma.review.findMany({
      where: { artisanId, isVisible: true },
      include: {
        client: {
          include: {
            user: { select: { email: true, phone: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const totalRatings = reviews.reduce((sum, r) => sum + r.rating, 0);
    const avgRating = reviews.length > 0 ? Number((totalRatings / reviews.length).toFixed(1)) : 0;

    return {
      success: true,
      data: {
        reviews,
        totalReviews: reviews.length,
        avgRating,
      },
      message: 'Avis récupérés',
    };
  }
}
