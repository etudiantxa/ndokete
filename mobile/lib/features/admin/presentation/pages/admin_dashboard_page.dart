import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _kpis;
  List<dynamic> _artisans = [];
  bool _loading = true;
  final _currency = NumberFormat('#,###', 'fr_FR');
  int _selectedTab = 0;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showArtisanDetailModal(Map<String, dynamic> artisan) {
    final plan = artisan['plan'] as String? ?? 'FREE';
    final isPremium = plan != 'FREE';
    final phone = artisan['phone'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isPremium
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.cardDark,
                  child: Icon(
                    isPremium ? Icons.workspace_premium : Icons.store,
                    color: isPremium ? AppColors.primary : AppColors.textSecondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artisan['businessName'] ?? 'Atelier Artisan',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${artisan['email'] ?? ''} · $phone',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text('Clients', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${artisan['customersCount']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text('Produits', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${artisan['productsCount']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text('Commandes', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${artisan['ordersCount']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showPlanDialog(artisan);
                },
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: Text('Modifier le Plan (Actuel: $plan)', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),

            if (phone.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                    final recipient = cleanPhone.startsWith('221') ? cleanPhone : '221$cleanPhone';
                    final uri = Uri.https('wa.me', '/$recipient', {'text': 'Bonjour ${artisan['businessName']}, message de l\'administration NDOKETE 🇸🇳'});
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Contacter sur WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _selectedPlanFilter = 'TOUT';

  List<dynamic> get _filteredArtisans {
    return _artisans.where((a) {
      final plan = (a['plan'] as String? ?? 'FREE').toUpperCase();
      if (_selectedPlanFilter != 'TOUT' && plan != _selectedPlanFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final name = (a['businessName'] ?? '').toString().toLowerCase();
      final email = (a['email'] ?? '').toString().toLowerCase();
      final quarter = (a['quarter'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          quarter.contains(_searchQuery);
    }).toList();
  }

  Widget _filterChip(String label, String value) {
    final selected = _selectedPlanFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      labelStyle: TextStyle(color: selected ? Colors.black : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
      onSelected: (_) => setState(() => _selectedPlanFilter = value),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final client = getIt<ApiClient>();
      final [kpisResp, artisansResp] = await Future.wait([
        client.get('/analytics/admin'),
        client.get('/analytics/admin/artisans'),
      ]);

      if (mounted) {
        setState(() {
          _kpis = (kpisResp.data as Map)['data'] as Map<String, dynamic>? ??
              (kpisResp.data as Map<String, dynamic>);
          _artisans = (artisansResp.data as Map)['data'] as List? ??
              (artisansResp.data as List? ?? []);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement Admin: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updatePlan(String artisanId, String newPlan) async {
    try {
      final client = getIt<ApiClient>();
      await client.patch(
        '/analytics/admin/artisans/$artisanId/plan',
        data: {'plan': newPlan},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan de l\'artisan modifié vers $newPlan'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadAdminData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de modification du plan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPlanDialog(Map<String, dynamic> artisan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modifier le plan de ${artisan['businessName'] ?? 'l\'artisan'}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.textSecondary),
              title: const Text('Plan Gratuit (FREE)',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _updatePlan(artisan['id'], 'FREE');
              },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium,
                  color: AppColors.primary),
              title: const Text('Plan Premium (5 000 FCFA)',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _updatePlan(artisan['id'], 'PREMIUM');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: AppColors.secondary),
              title: const Text('Plan Premium+ (10 000 FCFA)',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _updatePlan(artisan['id'], 'PREMIUM_PLUS');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Administration NDOKETE 🇸🇳'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quitter l\'administration',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/marketplace');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: _loadAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Se déconnecter',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'MRR (Abonnements)',
                          value:
                              '${_currency.format(_kpis?['mrr'] ?? 0)} FCFA',
                          icon: Icons.repeat,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'Commissions (10%)',
                          value:
                              '${_currency.format(_kpis?['totalCommissions'] ?? 0)} FCFA',
                          icon: Icons.account_balance_wallet,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'Artisans Inscrits',
                          value: '${_kpis?['totalArtisans'] ?? 0}',
                          subtitle:
                              '${_kpis?['premiumArtisans'] ?? 0} Premium',
                          icon: Icons.store,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'Inactivité (Risk)',
                          value: '${_kpis?['churnRisk'] ?? 0}',
                          subtitle: 'Sans commande (30j)',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Artisans (Gestion)'),
                        selected: _selectedTab == 0,
                        selectedColor: AppColors.primary,
                        onSelected: (_) => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Vue Financière'),
                        selected: _selectedTab == 1,
                        selectedColor: AppColors.primary,
                        onSelected: (_) => setState(() => _selectedTab = 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_selectedTab == 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Gestion des Artisans :',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text('${_filteredArtisans.length} inscrit(s)',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.trim().toLowerCase()),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom, email ou quartier...',
                        hintStyle: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('Tous', 'TOUT'),
                          const SizedBox(width: 8),
                          _filterChip('Gratuit', 'FREE'),
                          const SizedBox(width: 8),
                          _filterChip('Premium', 'PREMIUM'),
                          const SizedBox(width: 8),
                          _filterChip('Premium+', 'PREMIUM_PLUS'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._filteredArtisans.map((artisan) {
                      final plan = artisan['plan'] as String? ?? 'FREE';
                      final isPremium = plan != 'FREE';
                      return GestureDetector(
                        onTap: () => _showArtisanDetailModal(artisan),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.dividerDark),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isPremium
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.surfaceDark,
                                child: Icon(
                                  isPremium
                                      ? Icons.workspace_premium
                                      : Icons.store,
                                  color: isPremium
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artisan['businessName'] ?? 'Atelier Artisan',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    Text(
                                      '${artisan['email'] ?? ''} · ${artisan['quarter'] ?? 'Quartier non spécifié'}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isPremium
                                                ? AppColors.primary
                                                    .withValues(alpha: 0.2)
                                                : AppColors.surfaceDark,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            plan,
                                            style: TextStyle(
                                                color: isPremium
                                                    ? AppColors.primary
                                                    : AppColors.textSecondary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${artisan['customersCount']} clients · ${artisan['productsCount']} produits',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.primary),
                                onPressed: () => _showPlanDialog(artisan),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.dividerDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.insights, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text('Croissance des Abonnements & Commissions',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.dividerDark, strokeWidth: 1),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 24,
                                      getTitlesWidget: (value, meta) {
                                        const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil'];
                                        final index = value.toInt();
                                        if (index >= 0 && index < months.length) {
                                          return Text(months[index], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11));
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 6,
                                minY: 0,
                                maxY: 120,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: const [
                                      FlSpot(0, 20),
                                      FlSpot(1, 40),
                                      FlSpot(2, 55),
                                      FlSpot(3, 75),
                                      FlSpot(4, 90),
                                      FlSpot(5, 105),
                                      FlSpot(6, 120),
                                    ],
                                    isCurved: true,
                                    color: AppColors.primary,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Analyse de Rentabilité NDOKETE',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                            'Chaque abonnement Premium rapporte 5 000 FCFA/mois récurrents. Chaque vente marketplace reverse 10% de commission à la plateforme.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
