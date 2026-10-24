import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class SyncStatusPage extends StatefulWidget {
  const SyncStatusPage({super.key});

  @override
  State<SyncStatusPage> createState() => _SyncStatusPageState();
}

class _SyncStatusPageState extends State<SyncStatusPage> {
  List<Map<String, dynamic>> _pendingItems = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  void _loadPending() {
    setState(() {
      _pendingItems = HiveService.getPendingSyncItems();
    });
  }

  Future<void> _syncNow() async {
    if (_syncing || _pendingItems.isEmpty) return;
    setState(() => _syncing = true);

    try {
      final client = getIt<ApiClient>();
      final keys = HiveService.getPendingSyncKeys();

      for (final key in keys) {
        final item = HiveService.getItem(HiveService.syncQueueBox, key);
        if (item != null && item['status'] == 'pending') {
          final entity = item['entity'];
          final action = item['action'];
          final payload = item['payload'];

          if (entity == 'order' && action == 'create') {
            await client.post('/artisans/orders', data: payload);
          } else if (entity == 'customer' && action == 'create') {
            await client.post('/artisans/customers', data: payload);
          }

          await HiveService.markSyncItemProcessed(key);
        }
      }

      await HiveService.clearSyncedItems();
      _loadPending();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Synchronisation hors-ligne réussie !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de synchronisation : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Synchronisation & Mode Hors-Ligne'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.cloud_sync, color: Colors.black),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode Offline-First',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_pendingItems.length} action(s) en attente de synchronisation.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _syncing || _pendingItems.isEmpty ? null : _syncNow,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.sync),
              label: Text(
                _syncing ? 'Synchronisation en cours...' : 'Synchroniser maintenant',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Actions en attente :',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),

          if (_pendingItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('Aucune action en attente. Tout est synchronisé !',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ..._pendingItems.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entité : ${item['entity']} (${item['action']})',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Text(
                            'Créé le : ${item['createdAt'] ?? ''}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('En attente',
                          style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
