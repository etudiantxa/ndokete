import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../bloc/marketplace_bloc.dart';
import '../../domain/entities/product_entity.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MarketplaceBloc>()
        ..add(ProductDetailRequested(productId)),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MarketplaceBloc, MarketplaceState>(
      listener: (ctx, state) {
        if (state is MarketplaceActionSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        }
        if (state is MarketplaceError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (ctx, state) {
        if (state is MarketplaceLoading) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (state is ProductDetailLoaded) {
          return _ProductContent(product: state.product);
        }
        if (state is MarketplaceError) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(
              child: Text(state.message,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ProductContent extends StatefulWidget {
  final ProductEntity product;
  const _ProductContent({required this.product});

  @override
  State<_ProductContent> createState() => _ProductContentState();
}

class _ProductContentState extends State<_ProductContent> {
  int _selectedImage = 0;
  int _quantity = 1;
  final _currency = NumberFormat('#,###', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // ── AppBar avec galerie photo ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.surfaceDark,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardDark.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrls.isEmpty
                  ? Container(
                      color: AppColors.cardDark,
                      child: const Icon(Icons.image_not_supported,
                          color: AppColors.textSecondary, size: 64),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          itemCount: product.imageUrls.length,
                          onPageChanged: (i) =>
                              setState(() => _selectedImage = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: product.imageUrls[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.cardDark,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.cardDark,
                              child: const Icon(Icons.broken_image,
                                  color: AppColors.textSecondary, size: 64),
                            ),
                          ),
                        ),
                        if (product.imageUrls.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                product.imageUrls.length,
                                (i) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _selectedImage ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _selectedImage
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // ── Contenu ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Catégorie + badge
                Row(
                  children: [
                    if (product.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category!,
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 11),
                        ),
                      ),
                    const Spacer(),
                    if (!product.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ÉPUISÉ',
                          style:
                              TextStyle(color: AppColors.error, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Titre & prix
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currency.format(product.price)} FCFA',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Note & avis
                if (product.rating != null)
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < product.rating!.floor()
                              ? Icons.star
                              : i < product.rating!
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${product.rating!.toStringAsFixed(1)} (${product.reviewsCount} avis)',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Artisan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surfaceDark,
                        backgroundImage: product.artisanAvatarUrl != null
                            ? NetworkImage(product.artisanAvatarUrl!)
                            : null,
                        child: product.artisanAvatarUrl == null
                            ? const Icon(Icons.person, color: AppColors.textSecondary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.artisanName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (product.location != null)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      color: AppColors.textSecondary, size: 13),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.location!,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Voir boutique',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                if (product.description != null) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6),
                  ),
                  const SizedBox(height: 24),
                ],

                // Quantité
                if (product.isAvailable) ...[
                  Row(
                    children: [
                      const Text(
                        'Quantité',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      _QuantitySelector(
                        value: _quantity,
                        max: product.stockQuantity ?? 99,
                        onChanged: (v) => setState(() => _quantity = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                      Text(
                        '${_currency.format(product.price * _quantity)} FCFA',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: product.isAvailable
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Contacter artisan
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          context.read<MarketplaceBloc>().add(
                                MarketplaceOrderRequested(
                                    product.id, _quantity),
                              );
                        },
                        child: Text(
                          'Commander — ${_currency.format(product.price * _quantity)} FCFA',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const _QuantitySelector(
      {required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
            color: AppColors.primary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$value',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
