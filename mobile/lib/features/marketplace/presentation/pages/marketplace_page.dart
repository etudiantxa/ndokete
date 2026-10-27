import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class MarketplacePage extends StatefulWidget {
  final int initialTab;
  const MarketplacePage({super.key, this.initialTab = 0});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  List<dynamic> _products = [];
  bool _loading = true;
  bool _ordersLoading = false;
  bool _isArtisan = false;
  List<dynamic> _marketplaceOrders = [];
  List<dynamic> _allProducts = [];
  String _selectedCategory = 'Tout';
  String _sortBy = 'RECENT';
  String _selectedLocation = 'Toutes';
  double _maxPrice = 200000;
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat('#,###', 'fr_FR');
  late int _selectedNav;

  final _categories = [
    'Tout',
    'Vêtements',
    'Accessoires',
    'Maison',
    'Chaussures',
    'Couture',
    'Bijouterie',
  ];

  @override
  void initState() {
    super.initState();
    _selectedNav = widget.initialTab;
    _initializeMarketplace();
    if (_selectedNav == 2) {
      _loadMarketplaceOrders();
    }
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
      final params = {
        if (_selectedCategory != 'Tout') 'category': _selectedCategory,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final response = _isArtisan && _selectedNav == 0
          ? await client.get('/marketplace/my-shop', params: params)
          : await client.get('/marketplace', params: params);
      if (!mounted) return;
      final payload = (response.data as Map)['data'];
      List<dynamic> productList = [];
      if (payload is List) {
        productList = payload;
      } else if (payload is Map && payload['data'] is List) {
        productList = payload['data'] as List;
      }
      _allProducts = productList;
      _applyFiltersAndSort();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFiltersAndSort() {
    var filtered = List<Map<String, dynamic>>.from(
      _allProducts.map((p) => p as Map<String, dynamic>),
    );

    filtered = filtered.where((p) {
      final price = (p['price'] as num?)?.toDouble() ?? 0;
      return price <= _maxPrice;
    }).toList();

    if (_selectedLocation != 'Toutes') {
      filtered = filtered.where((p) {
        final loc = (p['location'] ?? p['artisan']?['quarter'] ?? '').toString();
        return loc.toLowerCase().contains(_selectedLocation.toLowerCase());
      }).toList();
    }

    if (_sortBy == 'PRIX_ASC') {
      filtered.sort((a, b) => ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0));
    } else if (_sortBy == 'PRIX_DESC') {
      filtered.sort((a, b) => ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0));
    }

    setState(() {
      _products = filtered;
      _loading = false;
    });
  }

  void _showAdvancedFilterDialog() {
    String tempSort = _sortBy;
    String tempLocation = _selectedLocation;
    double tempMaxPrice = _maxPrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: AppColors.primary, size: 24),
                      SizedBox(width: 10),
                      Text('Filtres Avancés & Tri',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        tempSort = 'RECENT';
                        tempLocation = 'Toutes';
                        tempMaxPrice = 200000;
                      });
                    },
                    child: const Text('Réinitialiser', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Trier par :', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Plus récents'),
                    selected: tempSort == 'RECENT',
                    selectedColor: AppColors.primary,
                    onSelected: (sel) => setSheetState(() => tempSort = 'RECENT'),
                  ),
                  ChoiceChip(
                    label: const Text('Prix : croissant'),
                    selected: tempSort == 'PRIX_ASC',
                    selectedColor: AppColors.primary,
                    onSelected: (sel) => setSheetState(() => tempSort = 'PRIX_ASC'),
                  ),
                  ChoiceChip(
                    label: const Text('Prix : décroissant'),
                    selected: tempSort == 'PRIX_DESC',
                    selectedColor: AppColors.primary,
                    onSelected: (sel) => setSheetState(() => tempSort = 'PRIX_DESC'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Ville / Quartier :', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Toutes', 'Dakar', 'Thiès', 'Saint-Louis', 'Touba'].map((loc) {
                  return ChoiceChip(
                    label: Text(loc),
                    selected: tempLocation == loc,
                    selectedColor: AppColors.primary,
                    onSelected: (sel) => setSheetState(() => tempLocation = loc),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Prix maximum :', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${_currency.format(tempMaxPrice.toInt())} FCFA', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: tempMaxPrice,
                min: 5000,
                max: 200000,
                divisions: 39,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.cardDark,
                onChanged: (val) => setSheetState(() => tempMaxPrice = val),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      _sortBy = tempSort;
                      _selectedLocation = tempLocation;
                      _maxPrice = tempMaxPrice;
                    });
                    Navigator.pop(sheetCtx);
                    _applyFiltersAndSort();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Appliquer les filtres', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMarketplaceOrders() async {
    setState(() {
      _ordersLoading = true;
      _selectedNav = 2;
    });
    try {
      final response = await getIt<ApiClient>().get('/orders');
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
          if (_isArtisan && _selectedNav == 0)
            IconButton(
              tooltip: 'Ajouter un produit',
              onPressed: () async {
                await context.push('/marketplace/add');
                _loadProducts();
              },
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary, size: 26),
            ),
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
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Filtres avancés & Tri',
                        onPressed: _showAdvancedFilterDialog,
                        icon: const Icon(Icons.tune_outlined, color: AppColors.primary, size: 20),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          tooltip: 'Mes commandes',
                          onPressed: () => _selectNavigation(2),
                          icon: const Icon(Icons.shopping_cart_outlined,
                              color: AppColors.textSecondary, size: 18),
                        ),
                      ),
                    ],
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
      floatingActionButton: (_isArtisan && _selectedNav == 0)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () async {
                await context.push('/marketplace/add');
                _loadProducts();
              },
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Ajouter un produit',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Future<bool?> _showPaymentSimulationDialog({
    required BuildContext context,
    required String planLabel,
    required int amount,
    required String method,
    required String phone,
  }) {
    final pinCtrl = TextEditingController();
    bool isProcessing = false;
    final isWave = method == 'WAVE';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isWave ? Icons.waves : Icons.phone_android,
                color: isWave ? AppColors.secondary : Colors.orange,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isWave ? 'Paiement Wave' : 'Paiement Orange Money',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.dividerDark),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Commande :',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text(planLabel,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant :',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text('${_currency.format(amount)} FCFA',
                            style: TextStyle(
                                color:
                                    isWave ? AppColors.secondary : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Entrez votre code secret à 4 chiffres pour autoriser le prélèvement :',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '••••',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isProcessing ? null : () => Navigator.pop(dialogCtx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isWave ? AppColors.secondary : Colors.orange,
                foregroundColor: Colors.black,
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (pinCtrl.text.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Veuillez entrer un code PIN à 4 chiffres.')),
                        );
                        return;
                      }
                      setDialogState(() => isProcessing = true);
                      await Future<void>.delayed(
                          const Duration(milliseconds: 1200));
                      if (ctx.mounted) Navigator.pop(dialogCtx, true);
                    },
              child: isProcessing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Valider le Paiement',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final items = order['items'] as List? ?? [];
    final payments = order['payments'] as List? ?? [];
    final status = order['status'] as String? ?? 'EN_ATTENTE';
    final isPaid = payments.any((p) => (p is Map) && p['status'] == 'PAYE');
    final statuses = ['EN_ATTENTE', 'EN_COURS', 'PRET', 'LIVRE'];
    final currentIdx = statuses.indexOf(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['orderNumber'] as String? ?? 'Détails de la commande',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Suivi en temps réel',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: statuses.asMap().entries.map((e) {
                final idx = e.key;
                final s = e.value;
                final isPast = idx <= currentIdx;
                final isCurrent = idx == currentIdx;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isPast ? AppColors.primary : AppColors.cardDark,
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          isPast ? Icons.check : Icons.circle,
                          color: isPast ? Colors.black : AppColors.textDisabled,
                          size: isPast ? 14 : 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['Attente', 'En cours', 'Prêt', 'Livré'][idx],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text('Articles commandés',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...items.map((item) {
              final product = item['product'] as Map<String, dynamic>?;
              final qty = item['quantity'] ?? 1;
              final price = item['price'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        product?['name'] ?? 'Produit',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text('x$qty', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 16),
                    Text('${_currency.format(price * qty)} FCFA',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total à payer :', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                Text('${_currency.format(order['totalAmount'] ?? 0)} FCFA',
                    style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            if (!isPaid) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final confirmed = await _showPaymentSimulationDialog(
                      context: context,
                      planLabel: order['orderNumber'] ?? 'Commande',
                      amount: (order['totalAmount'] as num).toInt(),
                      method: 'WAVE',
                      phone: '+221771234567',
                    );
                    if (confirmed != true) return;

                    try {
                      final client = getIt<ApiClient>();
                      await client.post('/payments/initiate', data: {
                        'marketplaceOrderId': order['id'],
                        'amount': order['totalAmount'],
                        'method': 'WAVE',
                        'phone': '+221771234567',
                      });
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Paiement effectué avec succès !'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadMarketplaceOrders();
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur de paiement : $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Payer maintenant (Wave / OM)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('Paiement déjà effectué', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  final uri = Uri.https('wa.me', '', {'text': 'Bonjour, je souhaite avoir des nouvelles de ma commande ${order['orderNumber']}'});
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Contacter l’artisan sur WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
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
        return GestureDetector(
          onTap: () => _showOrderDetails(order),
          child: Card(
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
                          ImageUtils.formatImageUrl(photos.first as String?),
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
