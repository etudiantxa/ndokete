import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
                    const Text('Gestion des Artisans :',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 12),
                    ..._artisans.map((artisan) {
                      final plan = artisan['plan'] as String? ?? 'FREE';
                      final isPremium = plan != 'FREE';
                      return Container(
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
                                isPremium ? Icons.workspace_premium : Icons.store,
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
                                              ? AppColors.primary.withValues(alpha: 0.2)
                                              : AppColors.surfaceDark,
                                          borderRadius: BorderRadius.circular(6),
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
                      );
                    }),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Analyse de Rentabilité NDOKETE',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(
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
