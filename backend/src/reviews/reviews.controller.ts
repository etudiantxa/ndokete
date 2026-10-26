import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('reviews')
@Controller('reviews')
export class ReviewsController {
  constructor(private reviewsService: ReviewsService) {}

  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard)
  @Post()
  @ApiOperation({ summary: 'Laisser un avis (1-5 étoiles) pour un artisan' })
  createReview(@CurrentUser('id') userId: string, @Body() dto: CreateReviewDto) {
    return this.reviewsService.createReview(userId, dto);
  }

  @Public()
  @Get('artisan/:artisanId')
  @ApiOperation({ summary: 'Récupérer les avis d’un artisan' })
  getArtisanReviews(@Param('artisanId') artisanId: string) {
    return this.reviewsService.getArtisanReviews(artisanId);
  }
}
