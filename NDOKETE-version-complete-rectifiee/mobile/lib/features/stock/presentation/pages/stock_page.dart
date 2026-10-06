import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String _selectedCategory = 'Tout';
  final _categories = ['Tout', 'Tissus', 'Fils', 'Cuir', 'Perles'];

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  void _showAddStockDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'm');
    final thresholdCtrl = TextEditingController(text: '5');
    String? selectedCategory = _categories.firstWhere((c) => c != 'Tout');
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajouter au Stock',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Nom de la matière'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: _categories.where((c) => c != 'Tout').map((c) =>
                    DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setSheetState(() => selectedCategory = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: quantityCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Quantité'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: unitCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Unité (m, u, kg...)'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: thresholdCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Seuil d\'alerte'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  setSheetState(() => loading = true);
                  try {
                    final client = getIt<ApiClient>();
                    await client.post('/artisans/stock', data: {
                      'name': nameCtrl.text,
                      'category': selectedCategory,
                      'quantity': double.tryParse(quantityCtrl.text) ?? 0,
                      'unit': unitCtrl.text,
                      'alertThreshold': double.tryParse(thresholdCtrl.text) ?? 5,
                    });
                    _loadStock();
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (_) {
                    setSheetState(() => loading = false);
                  }
                },
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadStock([String? category]) async {
    setState(() => _loading = true);
    try {
      final client = getIt<ApiClient>();
      final params = <String, dynamic>{};
      if (category != null && category != 'Tout') params['category'] = category;
      final response = await client.get('/artisans/stock', params: params);
      setState(() {
        _items = (response.data as Map)['data'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Inventaire des Matières Premi...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Utilisez les catégories pour filtrer le stock.')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _loadStock(_selectedCategory == 'Tout' ? null : _selectedCategory),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres catégories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _loadStock(cat == 'Tout' ? null : cat);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedCategory == cat ? AppColors.primary : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: _selectedCategory == cat ? Colors.black : AppColors.textSecondary,
                        fontWeight: _selectedCategory == cat ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: () => _loadStock(_selectedCategory == 'Tout' ? null : _selectedCategory),
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _StockItemCard(
                        item: _items[i] as Map<String, dynamic>,
                        onTap: () => context.push('/stock/${(_items[i] as Map)['id']}'),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.dividerDark)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavTab(
              icon: Icons.inventory_2_outlined,
              label: 'Stock',
              selected: true,
              onTap: () => _loadStock(
                  _selectedCategory == 'Tout' ? null : _selectedCategory),
            ),
            _NavTab(icon: Icons.receipt_long_outlined, label: 'Commandes', selected: false, onTap: () => context.push('/orders')),
            _NavTab(icon: Icons.people_outline, label: 'Clients', selected: false, onTap: () => context.push('/clients')),
            _NavTab(icon: Icons.person_outline, label: 'Profil', selected: false, onTap: () => context.push('/profile')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddStockDialog(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _StockItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _StockItemCard({required this.item, required this.onTap});

  bool get _isLow {
    final qty = (item['quantity'] as num).toDouble();
    final threshold = (item['alertThreshold'] as num).toDouble();
    return qty <= threshold;
  }

  bool get _isCritical {
    final qty = (item['quantity'] as num).toDouble();
    final threshold = (item['alertThreshold'] as num).toDouble();
    return qty <= threshold * 0.5;
  }

  double get _stockPercentage {
    final qty = (item['quantity'] as num).toDouble();
    final threshold = (item['alertThreshold'] as num).toDouble();
    return (qty / (threshold * 2)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final qty = item['quantity'];
    final unit = item['unit'] as String;
    final category = item['category'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isCritical ? AppColors.error.withOpacity(0.4) : AppColors.dividerDark,
          ),
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(category),
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              item['description'] as String? ?? category,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$qty $unit',
                        style: TextStyle(
                          color: _isCritical ? AppColors.error : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Barre de stock
                  if (!_isLow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NIVEAU DE STOCK',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _stockPercentage,
                            backgroundColor: AppColors.dividerDark,
                            color: AppColors.success,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (_isCritical ? AppColors.error : AppColors.warning).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isCritical ? 'CRITIQUE' : 'RÉAPPROVISIONNEMENT REQUIS',
                            style: TextStyle(
                              color: _isCritical ? AppColors.error : AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(_stockPercentage * 100).round()}%',
                          style: TextStyle(
                            color: _isCritical ? AppColors.error : AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Badge stockable
            if (!_isLow) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'STOCKABLE',
                  style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tissus': return Icons.texture;
      case 'fils': return Icons.linear_scale;
      case 'cuir': return Icons.wallet;
      case 'perles': return Icons.circle_outlined;
      default: return Icons.inventory_2;
    }
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
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
