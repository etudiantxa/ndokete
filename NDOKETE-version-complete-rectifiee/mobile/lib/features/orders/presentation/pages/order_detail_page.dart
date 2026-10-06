import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _saving = false;
  double _progressValue = 0;
  final _currency = NumberFormat('#,###', 'fr_FR');

  final _statuses = ['EN_ATTENTE', 'EN_COURS', 'PRET', 'LIVRE'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = getIt<ApiClient>();
      final response = await client.get('/artisans/orders/${widget.orderId}');
      setState(() {
        _order = (response.data as Map)['data'] as Map<String, dynamic>;
        _progressValue =
            ((_order!['progressPct'] as num?)?.toDouble() ?? 0) / 100;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final client = getIt<ApiClient>();
      final response = await client.patch(
        '/artisans/orders/${widget.orderId}',
        data: {'status': newStatus},
      );
      if (!mounted) return;
      setState(() {
        _order = (response.data as Map)['data'] as Map<String, dynamic>;
        _progressValue =
            ((_order!['progressPct'] as num?)?.toDouble() ?? 0) / 100;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Statut mis à jour : $newStatus'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Impossible de modifier le statut : $error'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProgress(double value) async {
    final percent = (value * 100).round();
    try {
      final response = await getIt<ApiClient>().patch(
        '/artisans/orders/${widget.orderId}',
        data: {'progressPct': percent},
      );
      if (mounted) {
        setState(() =>
            _order = (response.data as Map)['data'] as Map<String, dynamic>);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Progression non enregistrée : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Supprimer cette commande ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'La commande et ses paiements seront supprimés. Les transactions comptables liées seront conservées sans lien avec cette commande.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await getIt<ApiClient>().delete('/artisans/orders/${widget.orderId}');
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Suppression impossible : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _whatsappNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.trim().startsWith('+') || digits.startsWith('221')) return digits;
    final local = digits.startsWith('0') ? digits.substring(1) : digits;
    return '221$local';
  }

  Future<void> _openSms(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final order = _order;
    final text =
        'Bonjour, votre commande ${order?['orderNumber'] ?? ''} est à jour.';
    final recipient = '+${_whatsappNumber(phone)}';
    try {
      await launchUrl(
        Uri(
            scheme: 'sms',
            path: recipient,
            query: 'body=${Uri.encodeComponent(text)}'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Ouvrez votre application SMS pour envoyer le message.')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final order = _order;
    final text =
        'Bonjour, votre commande ${order?['orderNumber'] ?? ''} est à jour.';
    final uri =
        Uri.https('wa.me', '/${_whatsappNumber(phone)}', {'text': text});
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp n’a pas pu être ouvert.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));

    final order = _order!;
    final customer = order['customer'] as Map<String, dynamic>?;
    final currentStatusIdx = _statuses.indexOf(order['status'] as String);
    final progressPct = _progressValue.clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(order['orderNumber'] as String),
        actions: [
          IconButton(
            tooltip: 'Supprimer la commande',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _deleteOrder,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppColors.cardDark,
              builder: (sheetContext) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _statuses
                      .map((status) => ListTile(
                            title: Text(status,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _updateStatus(status);
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Infos client
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      (customer?['name'] as String? ?? 'C')[0],
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer?['name'] as String? ?? '',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                        Text(customer?['phone'] as String? ?? '',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Envoyer un SMS (envoi manuel)',
                    onPressed: () => _openSms(customer?['phone'] as String?),
                    icon: const Icon(Icons.sms_outlined,
                        color: AppColors.secondary),
                  ),
                  IconButton(
                    tooltip: 'Contacter sur WhatsApp',
                    onPressed: () =>
                        _openWhatsApp(customer?['phone'] as String?),
                    icon: const Icon(Icons.chat_outlined,
                        color: AppColors.success),
                  ),
                  GestureDetector(
                    onTap: () => context
                        .push('/clients/${customer?['id']}/measurements'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Mesures',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Titre et montant
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['title'] as String,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  if (order['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(order['description'] as String,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoChip(
                          label: 'Total',
                          value: '${_currency.format(order['amount'])} FCFA'),
                      const SizedBox(width: 12),
                      _InfoChip(
                          label: 'Acompte',
                          value: '${_currency.format(order['deposit'])} FCFA'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progression
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progression',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      Text('${(progressPct * 100).round()}%',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPct,
                      backgroundColor: AppColors.dividerDark,
                      color: AppColors.primary,
                      minHeight: 8,
                    ),
                  ),
                  Slider(
                    value: progressPct,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _progressValue = value),
                    onChangeEnd: _saving ? null : _saveProgress,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.dividerDark,
                  ),
                  const Text(
                    'La progression suit le statut. Vous pouvez aussi la régler ici.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statuts
            const Text('Mettre à jour le statut',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: _statuses.asMap().entries.map((e) {
                final idx = e.key;
                final status = e.value;
                final isPast = idx <= currentStatusIdx;
                final isCurrent = idx == currentStatusIdx;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _updateStatus(status),
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                isPast ? AppColors.primary : AppColors.cardDark,
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                          ),
                          child: Icon(
                            isPast ? Icons.check : Icons.circle,
                            color:
                                isPast ? Colors.black : AppColors.textDisabled,
                            size: isPast ? 16 : 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ['Attente', 'En cours', 'Prêt', 'Livré'][idx],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Notes
            if (order['notes'] != null) ...[
              const Text('Notes',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(order['notes'] as String,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
