import {
  Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ProductsService, CreateProductDto } from './products.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('marketplace')
@Controller('marketplace')
export class ProductsController {
  constructor(private productsService: ProductsService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Accueil marketplace public (artisans + produits vedettes)' })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  getMarketplace(
    @Query('search') search?: string,
    @Query('category') category?: string,
    @Query('page') page?: number,
  ) {
    return this.productsService.getMarketplace(search, category, page);
  }

  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ARTISAN')
  @Get('my-shop')
  @ApiOperation({ summary: 'Boutique de l\'artisan connecté' })
  getMyShop(@CurrentUser('artisanId') artisanId: string) {
    return this.productsService.getArtisanProducts(artisanId);
  }

  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ARTISAN')
  @Get('my-shop/stats')
  @ApiOperation({ summary: 'Stats boutique (vues, conversions, revenus)' })
  getStats(@CurrentUser('artisanId') artisanId: string) {
    return this.productsService.getProductStats(artisanId);
  }

  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ARTISAN')
  @Post('products')
  @ApiOperation({ summary: 'Ajouter un produit à la boutique' })
  create(@CurrentUser('artisanId') artisanId: string, @Body() dto: CreateProductDto) {
    return this.productsService.create(artisanId, dto);
  }

  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ARTISAN')
  @Patch('products/:id')
  @ApiOperation({ summary: 'Modifier un produit' })
  update(
    @CurrentUser('artisanId') artisanId: string,
    @Param('id') id: string,
    @Body() dto: Partial<CreateProductDto>,
  ) {
    return this.productsService.update(artisanId, id, dto);
  }

  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ARTISAN')
  @Delete('products/:id')
  remove(@CurrentUser('artisanId') artisanId: string, @Param('id') id: string) {
    return this.productsService.remove(artisanId, id);
  }

  @Public()
  @Get(':id')
  getProduct(@Param('id') id: string) {
    return this.productsService.getProductById(id);
  }
}
