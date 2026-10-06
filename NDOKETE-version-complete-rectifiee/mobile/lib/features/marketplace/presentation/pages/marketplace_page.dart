import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  List<dynamic> _products = [];
  bool _loading = true;
  bool _ordersLoading = false;
  bool _isArtisan = false;
  List<dynamic> _marketplaceOrders = [];
  String _selectedCategory = 'Tout';
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat('#,###', 'fr_FR');
  int _selectedNav = 0;

  final _categories = [
    'Tout',
    'Tissage',
    'Bijouterie',
    'Maroquin',
    'Couture',
    'Poterie'
  ];

  @override
  void initState() {
    super.initState();
    _initializeMarketplace();
  }

  Future<void> _initializeMarketplace() async {
    try {
      final response = await getIt<ApiClient>().get('/users/me');
      final user = (response.data as Map)['data'] as Map<String, dynamic>;
      if (mounted) setState(() => _isArtisan = user['role'] == 'ARTISAN');
    } catch (_) {
      // Public discovery remains available without a signed-in artisan profile.
    }
    _loadProducts();
  }

  Future<void> _loadProducts([String? search]) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final client = getIt<ApiClient>();
      final response = _isArtisan && _selectedNav == 0
          ? await client.get('/marketplace/my-shop')
          : await client.get(
              '/marketplace',
              params: {
                if (_selectedCategory != 'Tout') 'category': _selectedCategory,
                if (search != null && search.isNotEmpty) 'search': search,
              },
            );
      if (!mounted) return;
      setState(() {
        _products = ((response.data as Map)['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMarketplaceOrders() async {
    setState(() {
      _ordersLoading = true;
      _selectedNav = 2;
    });
    try {
      final response = await getIt<ApiClient>().get('/marketplace/orders');
      if (!mounted) return;
      setState(() {
        _marketplaceOrders = (response.data as Map)['data'] as List? ?? [];
        _ordersLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _ordersLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger vos commandes : $error')),
      );
    }
  }

  Future<void> _selectNavigation(int index) async {
    if (index == 3) {
      await context.push('/profile');
      return;
    }
    if (index == 2 && _isArtisan) {
      await context.push('/orders');
      return;
    }
    if (index == 2) {
      await _loadMarketplaceOrders();
      return;
    }
    setState(() => _selectedNav = index);
    await _loadProducts(_searchCtrl.text);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(_isArtisan && _selectedNav == 0
            ? 'Ma boutique'
            : 'Boutique NDOKETE'),
        actions: [
          if (_selectedNav == 2)
            IconButton(
              tooltip: 'Actualiser les commandes',
              onPressed: _loadMarketplaceOrders,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextFormField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Trouvez l\'artisanat unique...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      tooltip: 'Mes commandes',
                      onPressed: _isArtisan
                          ? () => _selectNavigation(2)
                          : () => _selectNavigation(2),
                      icon: const Icon(Icons.shopping_cart_outlined,
                          color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                ),
                onChanged: _loadProducts,
              ),
            ),

            // Filtres catégories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _categories
                    .map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              _loadProducts();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedCategory == cat
                                    ? AppColors.primary
                                    : AppColors.cardDark,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: _selectedCategory == cat
                                      ? Colors.black
                                      : AppColors.textSecondary,
                                  fontWeight: _selectedCategory == cat
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            Expanded(
              child: _selectedNav == 2
                  ? _buildMarketplaceOrders()
                  : _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _products.isEmpty
                          ? const Center(
                              child: Text('Aucun produit trouvé',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)))
                          : CustomScrollView(
                              slivers: [
                                // Section artisans vedettes
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Artisans Vedettes',
                                            style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600)),
                                        const Text('Voir tout',
                                            style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),

                                // Artisans vedettes (avatars)
                                SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: 80,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      itemCount: 5,
                                      itemBuilder: (_, i) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 16),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 28,
                                              backgroundColor: AppColors.primary
                                                  .withOpacity(0.2),
                                              child: Text(
                                                ['S', 'O', 'F', 'M', 'A'][i],
                                                style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                'Sokhna',
                                                'Ousmane',
                                                'Fatou',
                                                'Moussa',
                                                'Awa'
                                              ][i],
                                              style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 20, 16, 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Nouveautés',
                                            style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardDark,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.tune,
                                                  color:
                                                      AppColors.textSecondary,
                                                  size: 14),
                                              SizedBox(width: 4),
                                              Text('FILTRER',
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Grille de produits (2 colonnes)
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  sliver: SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                      (ctx, i) => GestureDetector(
                                        onTap: () => ctx.push(
                                            '/marketplace/${(_products[i] as Map)['id']}'),
                                        child: _ProductCard(
                                          product: _products[i]
                                              as Map<String, dynamic>,
                                          currency: _currency,
                                        ),
                                      ),
                                      childCount: _products.length,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                    child: SizedBox(height: 80)),
                              ],
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.dividerDark)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
                icon: Icons.home_outlined,
                label: 'Accueil',
                selected: _selectedNav == 0,
                onTap: () => _selectNavigation(0)),
            _NavItem(
                icon: Icons.explore_outlined,
                label: 'Découvrir',
                selected: _selectedNav == 1,
                onTap: () => _selectNavigation(1)),
            _NavItem(
                icon: Icons.receipt_outlined,
                label: 'Mes Commandes',
                selected: _selectedNav == 2,
                onTap: () => _selectNavigation(2)),
            _NavItem(
                icon: Icons.person_outline,
                label: 'Profil',
                selected: _selectedNav == 3,
                onTap: () => _selectNavigation(3)),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceOrders() {
    if (_ordersLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_marketplaceOrders.isEmpty) {
      return const Center(
        child: Text('Vous n’avez pas encore de commande.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _marketplaceOrders.length,
      itemBuilder: (context, index) {
        final order = _marketplaceOrders[index] as Map<String, dynamic>;
        final items = order['items'] as List? ?? [];
        final firstItem =
            items.isEmpty ? null : items.first as Map<String, dynamic>;
        final firstProduct = firstItem?['product'] as Map<String, dynamic>?;
        final createdAt = order['createdAt'] as String?;
        return Card(
          color: AppColors.cardDark,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.surfaceDark,
              child: Icon(Icons.receipt_long, color: AppColors.primary),
            ),
            title: Text(
              order['orderNumber'] as String? ?? 'Commande',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${firstProduct?['name'] ?? 'Produit'}${items.length > 1 ? ' et ${items.length - 1} autre(s)' : ''}'
              '${createdAt == null ? '' : ' · ${DateFormat('dd/MM/yyyy').format(DateTime.parse(createdAt))}'}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_currency.format(order['totalAmount'] ?? 0)} FCFA',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                Text(
                  order['status'] as String? ?? '',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final NumberFormat currency;

  const _ProductCard({required this.product, required this.currency});

  @override
  Widget build(BuildContext context) {
    final artisan = product['artisan'] as Map<String, dynamic>?;
    final photos = product['photos'] as List?;
    final isVitrine = product['isVitrine'] as bool? ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image produit
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: photos != null && photos.isNotEmpty
                      ? Image.network(
                          photos.first as String,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _PlaceholderProduct(),
                        )
                      : _PlaceholderProduct(),
                ),
                // Favoris
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.favorite_border,
                        color: Colors.grey, size: 16),
                  ),
                ),
                // Badge vitrine
                if (isVitrine)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('⭐ vitriné',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),

          // Infos produit
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artisan?['businessName'] as String? ?? '',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product['name'] as String,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${currency.format(product['price'])} FCFA',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderProduct extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceDark,
      child: const Center(
          child: Icon(Icons.image_outlined,
              color: AppColors.textDisabled, size: 40)),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
