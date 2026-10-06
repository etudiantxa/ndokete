import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _selectedTab = 'Toutes';
  List<dynamic> _orders = [];
  List<dynamic> _urgentOrders = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  Timer? _searchTimer;
  final _currency = NumberFormat('#,###', 'fr_FR');
  final _tabs = ['Toutes', 'En cours', 'Prêt', 'Livré'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({String? status, String? search}) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final client = getIt<ApiClient>();
      final params = <String, dynamic>{};
      if (status != null && _statusKey(status).isNotEmpty) {
        params['status'] = _statusKey(status);
      }
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }
      final [ordersResp, urgentResp] = await Future.wait([
        client.get('/artisans/orders', params: params.isEmpty ? null : params),
        client.get('/artisans/orders/urgent'),
      ]);
      if (!mounted) return;
      setState(() {
        _orders = (ordersResp.data as Map)['data'] as List? ?? [];
        _urgentOrders = (urgentResp.data as Map)['data'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusKey(String tab) {
    switch (tab) {
      case 'En cours':
        return 'EN_COURS';
      case 'Prêt':
        return 'PRET';
      case 'Livré':
        return 'LIVRE';
      default:
        return '';
    }
  }

  void _searchOrders(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _loadOrders(
        status: _selectedTab == 'Toutes' ? null : _selectedTab,
        search: value,
      );
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Gestion des Commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bannière rappels
          if (_urgentOrders.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_urgentOrders.length} commandes approchent de leur date de livraison.',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: _sendBulkReminders,
                    child: const Text(
                      'Préparer les SMS',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              ),
              onChanged: _searchOrders,
            ),
          ),
          const SizedBox(height: 12),

          // Filtres par statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _tabs
                  .map((tab) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedTab = tab);
                            _loadOrders(
                              status: tab == 'Toutes' ? null : tab,
                              search: _searchCtrl.text,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTab == tab
                                  ? AppColors.primary
                                  : AppColors.cardDark,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tab,
                              style: TextStyle(
                                color: _selectedTab == tab
                                    ? Colors.black
                                    : AppColors.textSecondary,
                                fontWeight: _selectedTab == tab
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
          const SizedBox(height: 16),

          // Section commandes urgentes
          if (_urgentOrders.isNotEmpty && _selectedTab == 'Toutes') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'COMMANDES URGENTES',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 'Toutes'),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Liste des commandes
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _orders.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune commande',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) => _OrderListItem(
                          order: _orders[i] as Map<String, dynamic>,
                          currency: _currency,
                          onTap: () async {
                            await context.push(
                              '/orders/${(_orders[i] as Map)['id']}',
                            );
                            if (mounted) {
                              _loadOrders(
                                status: _selectedTab == 'Toutes'
                                    ? null
                                    : _selectedTab,
                                search: _searchCtrl.text,
                              );
                            }
                          },
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
            _BottomItem(
                icon: Icons.people_outline,
                label: 'Clients',
                onTap: () => context.push('/clients')),
            _BottomItem(
                icon: Icons.straighten,
                label: 'Stock',
                onTap: () => context.push('/stock')),
            const SizedBox(width: 56), // FAB space
            _BottomItem(
                icon: Icons.storefront_outlined,
                label: 'Boutique',
                onTap: () => context.push('/marketplace')),
            _BottomItem(
                icon: Icons.person_outline,
                label: 'Profil',
                onTap: () => context.push('/profile')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await context.push('/orders/new');
          if (mounted) {
            _loadOrders(
              status: _selectedTab == 'Toutes' ? null : _selectedTab,
              search: _searchCtrl.text,
            );
          }
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Future<void> _sendBulkReminders() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardDark,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choisissez un client pour ouvrir son SMS',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _urgentOrders.length,
                itemBuilder: (_, index) {
                  final order = _urgentOrders[index] as Map<String, dynamic>;
                  final customer = order['customer'] as Map<String, dynamic>?;
                  return ListTile(
                    leading: const Icon(Icons.sms_outlined,
                        color: AppColors.secondary),
                    title: Text(
                      customer?['name'] as String? ?? 'Client',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      '${order['title'] ?? 'Commande'} · ${customer?['phone'] ?? ''}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _openReminderSms(order);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReminderSms(Map<String, dynamic> order) async {
    final customer = order['customer'] as Map<String, dynamic>?;
    final phone = customer?['phone'] as String?;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ce client n’a pas de numéro de téléphone.')),
      );
      return;
    }
    final dueDate = order['dueDate'] == null
        ? ''
        : DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(order['dueDate'] as String));
    final message =
        'Bonjour ${customer?['name'] ?? ''}, votre commande ${order['orderNumber'] ?? ''} est prévue pour le $dueDate. Répondez si vous avez une question.';
    try {
      await launchUrl(
        Uri(
          scheme: 'sms',
          path: phone,
          query: 'body=${Uri.encodeComponent(message)}',
        ),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Impossible d’ouvrir l’application SMS : $error')),
        );
      }
    }
  }
}

class _OrderListItem extends StatelessWidget {
  final Map<String, dynamic> order;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _OrderListItem(
      {required this.order, required this.currency, required this.onTap});

  Color get _statusColor {
    switch (order['status']) {
      case 'EN_COURS':
        return AppColors.info;
      case 'PRET':
        return AppColors.success;
      case 'LIVRE':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (order['status']) {
      case 'EN_ATTENTE':
        return 'EN ATTENTE';
      case 'EN_COURS':
        return 'EN COURS';
      case 'PRET':
        return 'PRÊT';
      case 'LIVRE':
        return 'LIVRÉ';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = order['customer'] as Map<String, dynamic>?;
    final isUrgent = order['isUrgent'] as bool? ?? false;
    final dueDate = order['dueDate'] != null
        ? DateFormat('dd Oct. yyyy')
            .format(DateTime.parse(order['dueDate'] as String))
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: isUrgent
              ? Border.all(color: AppColors.error.withOpacity(0.4))
              : Border.all(color: AppColors.dividerDark),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar client
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/avatar_placeholder.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child:
                      const Icon(Icons.person, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            customer?['name'] as String? ?? '',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (isUrgent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '🔴 6H',
                                style: TextStyle(
                                    color: AppColors.error, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order['title'] as String? ?? '',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            if (dueDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'LIVRAISON : $dueDate',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Voir Mesures',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
