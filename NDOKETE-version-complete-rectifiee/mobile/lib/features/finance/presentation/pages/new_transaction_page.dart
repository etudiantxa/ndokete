import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_service.dart';

class NewTransactionPage extends StatefulWidget {
  const NewTransactionPage({super.key});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _type = 'ENTREE';
  String? _selectedCategory;
  String? _selectedOrderId;
  bool _loading = false;
  bool _hasReceipt = false;
  bool _ordersLoading = true;
  List<Map<String, dynamic>> _availableOrders = [];

  final _incomeCategories = ['Vente', 'Acompte', 'Solde', 'Autre'];
  final _expenseCategories = [
    'Tissu',
    'Fil',
    'Main d\'œuvre',
    'Loyer',
    'Matériel',
    'Autre'
  ];

  List<String> get _categories =>
      _type == 'ENTREE' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _updateDateLabel();
    _loadAvailableOrders();
  }

  void _updateDateLabel() {
    _dateCtrl.text =
        DateFormat('EEE d MMM yyyy', 'fr_FR').format(_selectedDate);
  }

  String get _selectedOrderTitle {
    final orderId = _selectedOrderId;
    if (orderId == null) return 'Sélectionner une commande en cours';
    return _availableOrders.firstWhere(
      (order) => order['id'] == orderId,
      orElse: () => {'title': 'Commande sélectionnée'},
    )['title'] as String;
  }

  Future<void> _loadAvailableOrders() async {
    try {
      final response = await getIt<ApiClient>().get('/artisans/orders');
      final data = (response.data as Map)['data'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _availableOrders = data
            .whereType<Map>()
            .map((order) => Map<String, dynamic>.from(order))
            .where((order) =>
                order['transaction'] == null &&
                order['status'] != 'LIVRE' &&
                order['status'] != 'ANNULE')
            .toList();
        _ordersLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _ordersLoading = false);
    }
  }

  Future<void> _pickOperationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _updateDateLabel();
      });
    }
  }

  Future<void> _chooseOrder() async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardDark,
      builder: (sheetContext) => SafeArea(
        child: _ordersLoading
            ? const SizedBox(
                height: 120,
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            : _availableOrders.isEmpty
                ? const SizedBox(
                    height: 140,
                    child: Center(
                      child: Text('Aucune commande disponible',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('Sans commande',
                            style: TextStyle(color: AppColors.textPrimary)),
                        onTap: () => Navigator.pop(sheetContext, ''),
                      ),
                      ..._availableOrders.map((order) => ListTile(
                            leading: const Icon(Icons.receipt_long,
                                color: AppColors.primary),
                            title: Text(
                              order['title'] as String? ?? 'Commande',
                              style:
                                  const TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              '${order['orderNumber'] ?? ''} · ${order['customer']?['name'] ?? ''}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            onTap: () => Navigator.pop(
                                sheetContext, order['id'] as String),
                          )),
                    ],
                  ),
      ),
    );
    if (selectedId != null) {
      setState(() => _selectedOrderId = selectedId.isEmpty ? null : selectedId);
    }
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0 || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Saisissez un montant valide et choisissez une catégorie.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    final payload = {
      'type': _type,
      'amount': amount,
      'category': _selectedCategory,
      'orderId': _selectedOrderId,
      'date': _selectedDate.toIso8601String(),
      'localId': localId,
    };

    try {
      final client = getIt<ApiClient>();
      await client.post('/artisans/transactions', data: payload);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transaction enregistrée'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (error) {
      if (!kIsWeb) {
        await HiveService.addToSyncQueue(
          entity: 'transaction',
          action: 'create',
          localId: localId,
          payload: payload,
        );
      }
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb
                ? 'Impossible d’enregistrer la transaction : $error'
                : 'Transaction enregistrée hors ligne et en attente de synchronisation.'),
            backgroundColor: kIsWeb ? AppColors.error : AppColors.warning,
          ),
        );
        if (!kIsWeb) context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Nouvelle Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Entrée / Dépense
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: ['ENTREE', 'DEPENSE']
                    .map((t) => Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _type = t;
                              _selectedCategory = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == t
                                    ? (t == 'ENTREE'
                                        ? AppColors.success
                                        : AppColors.error)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    t == 'ENTREE'
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: _type == t
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t == 'ENTREE' ? 'Entrée' : 'Dépense',
                                    style: TextStyle(
                                      color: _type == t
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 28),

            // Montant
            const Text('MONTANT',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                          color: AppColors.textDisabled, fontSize: 32),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('FCFA',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 18)),
                ),
              ],
            ),
            const Divider(color: AppColors.dividerDark),
            const SizedBox(height: 20),

            // Catégorie
            const Text('Catégorie',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories
                  .map((cat) => GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedCategory == cat
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedCategory == cat
                                  ? AppColors.primary
                                  : AppColors.dividerDark,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_categoryIcon(cat),
                                  color: _selectedCategory == cat
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: TextStyle(
                                  color: _selectedCategory == cat
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: _selectedCategory == cat
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Date
            const Text('DATE DE L\'OPÉRATION',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickOperationDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dividerDark),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(_dateCtrl.text,
                            style:
                                const TextStyle(color: AppColors.textPrimary))),
                    const Icon(Icons.calendar_today,
                        color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lier commande (optionnel)
            const Text('LIER À UNE COMMANDE (OPTIONNEL)',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _chooseOrder,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dividerDark),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedOrderTitle,
                        style: TextStyle(
                          color: _selectedOrderId == null
                              ? AppColors.textDisabled
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Justificatif
            const Text('JUSTIFICATIF',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _hasReceipt = !_hasReceipt),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _hasReceipt ? AppColors.success : AppColors.dividerDark,
                    style: _hasReceipt ? BorderStyle.solid : BorderStyle.none,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _hasReceipt
                          ? Icons.check_circle
                          : Icons.camera_alt_outlined,
                      color: _hasReceipt
                          ? AppColors.success
                          : AppColors.textDisabled,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasReceipt
                          ? 'Justificatif ajouté'
                          : 'Prendre une photo du reçu',
                      style: TextStyle(
                        color: _hasReceipt
                            ? AppColors.success
                            : AppColors.textDisabled,
                        fontSize: 13,
                      ),
                    ),
                    if (!_hasReceipt)
                      const Text(
                        'Facture, ticket ou papier libre',
                        style: TextStyle(
                            color: AppColors.textDisabled, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.save, size: 18, color: Colors.black),
              label: const Text('Enregistrer la transaction'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Vente':
        return Icons.sell_outlined;
      case 'Tissu':
        return Icons.texture;
      case 'Fil':
        return Icons.linear_scale;
      case 'Main d\'œuvre':
        return Icons.handyman;
      case 'Loyer':
        return Icons.home_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}
