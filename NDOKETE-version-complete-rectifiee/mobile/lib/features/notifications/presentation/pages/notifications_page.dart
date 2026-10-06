import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _load();
  }

  Future<void> _load() async {
    try {
      final client = getIt<ApiClient>();
      final response = await client.get('/notifications');
      setState(() {
        _notifications = (response.data as Map)['data'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final client = getIt<ApiClient>();
      await client.patch('/notifications/read-all');
      setState(() {
        for (final n in _notifications) {
          (n as Map<String, dynamic>)['isRead'] = true;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !(n as Map)['isRead']).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tout lire', style: TextStyle(color: AppColors.primary)),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/notifications/config'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none, color: AppColors.textDisabled, size: 80),
                      const SizedBox(height: 16),
                      const Text('Aucune notification', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (_, i) {
                    final n = _notifications[i] as Map<String, dynamic>;
                    final isRead = n['isRead'] as bool? ?? false;
                    final createdAt = DateTime.tryParse(n['createdAt'] as String? ?? '');

                    return GestureDetector(
                      onTap: () async {
                        if (!isRead) {
                          final client = getIt<ApiClient>();
                          await client.patch('/notifications/${n['id']}/read');
                          setState(() => n['isRead'] = true);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead ? AppColors.cardDark : AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRead ? AppColors.dividerDark : AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _typeColor(n['type'] as String).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                _typeIcon(n['type'] as String),
                                color: _typeColor(n['type'] as String),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['title'] as String,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n['body'] as String,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                                  ),
                                  if (createdAt != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      timeago.format(createdAt, locale: 'fr'),
                                      style: const TextStyle(color: AppColors.textDisabled, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'COMMANDE': return AppColors.info;
      case 'PAIEMENT': return AppColors.success;
      case 'RAPPEL_LIVRAISON': return AppColors.warning;
      case 'STOCK_ALERTE': return AppColors.error;
      case 'NOUVEAU_AVIS': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'COMMANDE': return Icons.receipt_long;
      case 'PAIEMENT': return Icons.payments_outlined;
      case 'RAPPEL_LIVRAISON': return Icons.local_shipping_outlined;
      case 'STOCK_ALERTE': return Icons.inventory_2_outlined;
      case 'NOUVEAU_AVIS': return Icons.star_outline;
      default: return Icons.notifications_outlined;
    }
  }
}
