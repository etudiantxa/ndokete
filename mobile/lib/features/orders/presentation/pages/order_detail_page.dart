import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
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

  Future<void> _shareOrderOnWhatsApp() async {
    final order = _order;
    if (order == null) return;
    final customer = order['customer'] as Map<String, dynamic>?;
    final customerName = customer?['name'] ?? 'Client';
    final customerPhone = customer?['phone'] ?? '';
    final orderNum = order['orderNumber'] ?? '';
    final title = order['title'] ?? '';
    final amount = _currency.format(order['amount']);
    final deposit = _currency.format(order['deposit'] ?? 0);
    final status = order['status'] ?? 'EN_ATTENTE';

    final text = '''
🛍️ *COMMANDE NDOKETE* - $orderNum
👤 Client : $customerName ($customerPhone)
🧵 Article : $title
💰 Montant : $amount FCFA (Acompte : $deposit FCFA)
📌 Statut : $status

Géré avec la plateforme NDOKETE 🇸🇳
''';

    final uri = Uri.https('wa.me', '', {'text': text});
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp.')),
        );
      }
    }
  }

  static String _formatStatusLabel(String? status) {
    switch (status) {
      case 'EN_ATTENTE':
        return 'En attente';
      case 'EN_COURS':
        return 'En confection';
      case 'PRET':
        return 'Prêt';
      case 'LIVRE':
        return 'Livré';
      default:
        return status ?? '';
    }
  }

  Future<void> _generateAndSharePdf() async {
    final order = _order;
    if (order == null) return;
    final customer = order['customer'] as Map<String, dynamic>?;
    final customerName = customer?['name'] ?? 'Client';
    final customerPhone = customer?['phone'] ?? '';
    final orderNum = order['orderNumber'] ?? 'CMD-000';
    final title = order['title'] ?? 'Article sur mesure';
    final amount = (order['amount'] as num?)?.toDouble() ?? 0;
    final deposit = (order['deposit'] as num?)?.toDouble() ?? 0;
    final balance = amount - deposit;
    final createdAt = order['createdAt'] as String?;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NDOKETE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                        pw.SizedBox(height: 4),
                        pw.Text('Plateforme de Gestion & Marketplace pour Artisans', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('FACTURE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Réf : $orderNum', style: const pw.TextStyle(fontSize: 12)),
                        if (createdAt != null)
                          pw.Text('Date : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(createdAt))}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Divider(color: PdfColors.orange800, thickness: 2),
                pw.SizedBox(height: 20),

                pw.Text('FACTURÉ À :', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 6),
                pw.Text(customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                if (customerPhone.isNotEmpty)
                  pw.Text('Téléphone : $customerPhone', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 30),

                pw.Table.fromTextArray(
                  headers: ['Description / Article', 'Statut', 'Montant (FCFA)'],
                  data: [
                    [title, _formatStatusLabel(order['status'] as String?), '${_currency.format(amount)} FCFA'],
                  ],
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
                  rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3.8),
                    1: const pw.FlexColumnWidth(2.0),
                    2: const pw.FlexColumnWidth(2.2),
                  },
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.centerRight},
                ),
                pw.SizedBox(height: 20),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.SizedBox(
                      width: 250,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Montant Total :', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text('${_currency.format(amount)} FCFA', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Acompte versé :', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text('${_currency.format(deposit)} FCFA', style: pw.TextStyle(fontSize: 12, color: PdfColors.green800)),
                            ],
                          ),
                          pw.Divider(thickness: 1),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Reste à payer :', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                              pw.Text('${_currency.format(balance)} FCFA', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey400),
                pw.Center(
                  child: pw.Text('Merci pour votre confiance ! - Généré via NDOKETE (Sénégal)', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'facture_$orderNum.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }

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
            tooltip: 'Générer la Facture PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            onPressed: _generateAndSharePdf,
          ),
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
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      (customer?['name'] as String? ?? '').isNotEmpty
                          ? (customer!['name'] as String)[0].toUpperCase()
                          : 'C',
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
                    onTap: () {
                      final clientId = customer?['id'] as String?;
                      if (clientId == null || clientId.isEmpty || clientId == 'null') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Information client non disponible.'),
                          ),
                        );
                        return;
                      }
                      context.push('/clients/$clientId/measurements');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
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
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _shareOrderOnWhatsApp,
                      icon: const Icon(Icons.share, color: AppColors.success, size: 18),
                      label: const Text('Partager le reçu sur WhatsApp',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
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
