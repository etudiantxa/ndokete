import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? _product;
  bool _loading = true;
  int _selectedImage = 0;
  int _quantity = 1;
  final _currency = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    try {
      final client = getIt<ApiClient>();
      final response = await client.get('/marketplace/${widget.productId}');
      if (mounted) {
        setState(() {
          _product = (response.data as Map)['data'] as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        context.pop();
      }
    }
  }

  // Vérifier si l'utilisateur connecté est le propriétaire du produit
  bool _isOwner() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && _product != null) {
      final artisan = _product!['artisan'] as Map<String, dynamic>?;
      return authState.user.artisanId == artisan?['id'];
    }
    return false;
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Modifier le produit', 
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Modifier les informations',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                // Naviguer vers la page d'édition avec l'ID du produit
                context.push('/marketplace/edit/${widget.productId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Supprimer le produit',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                // Confirmer la suppression
                showDialog(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    backgroundColor: AppColors.cardDark,
                    title: const Text('Confirmer la suppression',
                        style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text('Êtes-vous sûr de vouloir supprimer ce produit ?',
                        style: TextStyle(color: AppColors.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: const Text('Annuler',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx2);
                          try {
                            final client = getIt<ApiClient>();
                            await client.delete('/marketplace/products/${widget.productId}');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Produit supprimé avec succès'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              context.pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: ${e.toString()}'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Supprimer',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final isOwner = _isOwner();
    
    // Calculer isAvailable manuellement car le backend ne le renvoie pas
    final isAvailable = product != null && 
        product['status'] == 'ACTIF' && 
        (product['stock'] == null || product['stock'] > 0);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardDark.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          // AJOUT: Bouton de modification visible uniquement pour le propriétaire
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              onPressed: () => _showEditDialog(context),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Galerie photo ────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              child: product == null
                  ? Container(
                      color: AppColors.cardDark,
                      child: const Icon(Icons.image_not_supported,
                          color: AppColors.textSecondary, size: 64),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          itemCount: product['photos'].length,
                          onPageChanged: (i) =>
                              setState(() => _selectedImage = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: product['photos'][i],
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
                        if (product['photos'].length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                product['photos'].length,
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
                    if (product != null && product['category'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product['category'],
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 11),
                        ),
                      ),
                    const Spacer(),
                    if (product != null && !isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
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
                  product?['name'] ?? '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currency.format(product?['price'] ?? 0)} FCFA',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Note & avis
                if (product != null && product['rating'] != null)
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < product['rating'].floor()
                              ? Icons.star
                              : i < product['rating']
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${product['rating'].toStringAsFixed(1)} (${product['reviewsCount']} avis)',
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
                        backgroundImage: product != null &&
                                product['artisanAvatarUrl'] != null
                            ? NetworkImage(product['artisanAvatarUrl'])
                            : null,
                        child: product == null ||
                                product['artisanAvatarUrl'] == null
                            ? const Icon(Icons.person, color: AppColors.textSecondary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product?['artisanName'] ?? '',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (product != null && product['location'] != null)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      color: AppColors.textSecondary, size: 13),
                                  const SizedBox(width: 2),
                                  Text(
                                    product['location'],
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
                if (product != null && product['description'] != null) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['description'],
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6),
                  ),
                  const SizedBox(height: 24),
                ],

                // Quantité
                if (product != null && isAvailable) ...[
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
                        max: product['stock'] ?? 99,
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
                        '${_currency.format(product['price'] * _quantity)} FCFA',
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
      bottomNavigationBar: product != null && isAvailable
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
                        onPressed: () async {
                          try {
                            final client = getIt<ApiClient>();
                            await client.post('/orders', data: {
                              'items': [
                                {
                                  'productId': product['id'],
                                  'quantity': _quantity,
                                }
                              ],
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Commande créée avec succès'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              String errorMessage = 'Erreur de commande';
                              if (e.toString().contains('Profil client non trouvé')) {
                                errorMessage = 'Vous devez avoir un profil client pour commander';
                              } else if (e.toString().contains('Stock insuffisant')) {
                                errorMessage = 'Stock insuffisant pour ce produit';
                              } else {
                                errorMessage = 'Erreur: ${e.toString()}';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Commander — ${_currency.format(product['price'] * _quantity)} FCFA',
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

// Widget pour le sélecteur de quantité
class _QuantitySelector extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: value > 1 ? () => onChanged(value - 1) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: Icon(
              Icons.remove,
              size: 18,
              color: value > 1 ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            value.toString(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: Icon(
              Icons.add,
              size: 18,
              color: value < max ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
