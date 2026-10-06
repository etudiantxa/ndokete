import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _dashboardData;
  bool _loading = true;
  int _selectedTab = 0;

  final _currency = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final client = getIt<ApiClient>();
      final response = await client.get('/artisans/dashboard');
      setState(() {
        _dashboardData = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state is AuthAuthenticated)
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user?.businessName ?? 'Artisan'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _loadDashboard,
                      color: AppColors.primary,
                      child: _buildBody(),
                    ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/orders/new'),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NDOKETE WORKSPACE',
                style: TextStyle(color: AppColors.primary, fontSize: 10, letterSpacing: 1.5),
              ),
              Text(
                'Salam, $name',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final data = _dashboardData;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        // KPI card principale
        _KpiCard(
          todaySales: data?['todaySales'] as int? ?? 0,
          activeOrders: data?['activeOrders'] as int? ?? 0,
          currency: _currency,
        ),
        const SizedBox(height: 24),

        // Actions rapides
        const Text(
          'Actions Rapides',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
              icon: Icons.add_circle_outline,
              label: 'Ajouter\nCommande',
              color: AppColors.secondary,
              onTap: () => context.push('/orders/new'),
            ),
            const SizedBox(width: 12),
            _QuickAction(
              icon: Icons.person_add_outlined,
              label: 'Nouveau\nClient',
              color: AppColors.info,
              onTap: () => context.push('/clients'),
            ),
            const SizedBox(width: 12),
            _QuickAction(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Dépense',
              color: AppColors.warning,
              onTap: () => context.push('/finance/new'),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Commandes récentes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Commandes Récentes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/orders'),
              child: const Text(
                'Voir tout',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (data?['recentOrders'] != null)
          ...((data!['recentOrders'] as List).map(
            (order) => _OrderCard(order: order as Map<String, dynamic>, currency: _currency),
          ))
        else
          _EmptyOrders(),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.dividerDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.dashboard_outlined, label: 'Accueil', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
          _NavItem(icon: Icons.receipt_long_outlined, label: 'Commandes', selected: _selectedTab == 1, onTap: () { setState(() => _selectedTab = 1); context.push('/orders'); }),
          _NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Finance', selected: _selectedTab == 2, onTap: () { setState(() => _selectedTab = 2); context.push('/finance'); }),
          _NavItem(icon: Icons.person_outline, label: 'Profil', selected: _selectedTab == 3, onTap: () { setState(() => _selectedTab = 3); context.push('/profile'); }),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final int todaySales;
  final int activeOrders;
  final NumberFormat currency;

  const _KpiCard({required this.todaySales, required this.activeOrders, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventes du jour',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '${currency.format(todaySales)} CFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '+12% vs hier',
            style: TextStyle(color: Color(0xFF86EFAC), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _KpiItem(
                label: 'Commandes\nActives',
                value: '$activeOrders',
                icon: Icons.receipt_long,
              ),
              const SizedBox(width: 20),
              _KpiItem(
                label: 'En\nProduction',
                value: '$activeOrders',
                icon: Icons.handyman,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3)),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerDark),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final NumberFormat currency;

  const _OrderCard({required this.order, required this.currency});

  Color get _statusColor {
    switch (order['status']) {
      case 'EN_COURS': return AppColors.info;
      case 'PRET': return AppColors.success;
      case 'LIVRE': return AppColors.textSecondary;
      case 'ANNULE': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (order['status']) {
      case 'EN_ATTENTE': return 'EN ATTENTE';
      case 'EN_COURS': return 'EN COURS';
      case 'PRET': return 'PRÊT';
      case 'LIVRE': return 'LIVRÉ';
      default: return order['status'] as String? ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = order['customer'] as Map<String, dynamic>?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.checkroom, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer?['name'] as String? ?? 'Client',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order['title'] as String? ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.textDisabled, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Pas encore de commandes',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
