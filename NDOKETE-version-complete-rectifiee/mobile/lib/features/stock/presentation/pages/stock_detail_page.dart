import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class StockDetailPage extends StatefulWidget {
  final String itemId;
  const StockDetailPage({super.key, required this.itemId});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  Map<String, dynamic>? _item;
  bool _loading = true;
  final _adjustQtyCtrl = TextEditingController();
  String _adjustType = 'ENTREE';

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    try {
      final client = getIt<ApiClient>();
      final response = await client.get('/artisans/stock/${widget.itemId}');
      if (!mounted) return;
      setState(() {
        _item = (response.data as Map)['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _adjustStock() async {
    final qty = double.tryParse(_adjustQtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Saisissez une quantité supérieure à zéro.')),
      );
      return;
    }

    try {
      final client = getIt<ApiClient>();
      final response =
          await client.patch('/artisans/stock/${widget.itemId}/adjust', data: {
        'type': _adjustType,
        'quantity': qty,
      });
      final result = (response.data as Map)['data'] as Map<String, dynamic>;
      if (mounted) setState(() => _item = result);
      _adjustQtyCtrl.clear();

      final alert = (response.data as Map)['alert'];
      if (mounted && alert != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(alert.toString()),
              backgroundColor: AppColors.warning),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ajustement impossible : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _editAlertThreshold() async {
    final controller = TextEditingController(
      text: (_item?['alertThreshold'] as num?)?.toString() ?? '0',
    );
    final threshold = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Seuil d’alerte',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Quantité minimale (${_item?['unit'] ?? 'unité'})',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                      content: Text('Saisissez un seuil positif ou nul.')),
                );
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (threshold == null) return;
    try {
      final response = await getIt<ApiClient>().patch(
        '/artisans/stock/${widget.itemId}',
        data: {'alertThreshold': threshold},
      );
      if (mounted) {
        setState(() =>
            _item = (response.data as Map)['data'] as Map<String, dynamic>);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Seuil d’alerte mis à jour'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Modification impossible : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _adjustQtyCtrl.dispose();
    super.dispose();
  }

  void _showAdjustDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajuster le stock',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: ['ENTREE', 'SORTIE', 'AJUSTEMENT']
                  .map((type) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _adjustType = type),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _adjustType == type
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _adjustType == type
                                      ? AppColors.primary
                                      : AppColors.dividerDark,
                                ),
                              ),
                              child: Text(
                                type == 'ENTREE'
                                    ? 'Entrée'
                                    : type == 'SORTIE'
                                        ? 'Sortie'
                                        : 'Ajust.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _adjustType == type
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adjustQtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Quantité (${_item?['unit'] ?? 'unité'})',
                suffixText: _item?['unit'] as String? ?? '',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _adjustStock();
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));

    final item = _item!;
    final qty = (item['quantity'] as num).toDouble();
    final threshold = (item['alertThreshold'] as num).toDouble();
    final movements = item['movements'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Détails Matière')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Photo + nom
            Container(
              width: double.infinity,
              height: 180,
              color: AppColors.cardDark,
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.texture,
                        color: AppColors.textDisabled, size: 80),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['category'] as String,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stock actuel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STOCK ACTUEL',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(
                          '$qty ${item['unit']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seuil d'alerte
                  InkWell(
                    onTap: _editAlertThreshold,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Seuil d’alerte',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                                Text(
                                  'Alerte à $threshold ${item['unit']} (Niveau ${qty > threshold ? 'Correct' : 'Critique'})',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Text('Modifier',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Historique récent
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Historique récent',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const Text('Voir tout',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...movements.take(5).map((m) {
                    final mov = m as Map<String, dynamic>;
                    final isEntry = mov['type'] == 'ENTREE';
                    final date =
                        DateTime.tryParse(mov['createdAt'] as String? ?? '');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (isEntry
                                      ? AppColors.success
                                      : AppColors.error)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              isEntry
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color:
                                  isEntry ? AppColors.success : AppColors.error,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    mov['reason'] as String? ??
                                        (isEntry
                                            ? 'Achat Fournisseur'
                                            : 'Commande'),
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                if (date != null)
                                  Text(DateFormat('dd Oct yyyy').format(date),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            '${isEntry ? '+' : '-'}${mov['quantity']} ${item['unit']}',
                            style: TextStyle(
                              color:
                                  isEntry ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Fournisseur
                  if (item['supplier'] != null) ...[
                    const Text('Fournisseur',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: Text((item['supplier'] as String)[0],
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['supplier'] as String,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600)),
                                if (item['supplierPhone'] != null)
                                  Text(item['supplierPhone'] as String,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                              ],
                            ),
                          ),
                          if (item['supplierPhone'] != null) ...[
                            GestureDetector(
                              onTap: () async {
                                final phone = (item['supplierPhone'] as String)
                                    .replaceAll(' ', '');
                                final uri = Uri(scheme: 'tel', path: phone);
                                if (await canLaunchUrl(uri))
                                  await launchUrl(uri);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color:
                                        AppColors.secondary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(18)),
                                child: const Icon(Icons.phone,
                                    color: AppColors.secondary, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final phone = (item['supplierPhone'] as String)
                                    .replaceAll(' ', '')
                                    .replaceAll('+', '');
                                final uri = Uri.parse('https://wa.me/$phone');
                                if (await canLaunchUrl(uri))
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(18)),
                                child: const Icon(Icons.message,
                                    color: AppColors.info, size: 18),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _showAdjustDialog,
          icon: const Icon(Icons.edit, size: 18, color: Colors.black),
          label: const Text('Ajuster le stock'),
        ),
      ),
    );
  }
}
