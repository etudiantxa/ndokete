import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_service.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customerSearchCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _isUrgent = false;
  bool _loading = false;
  List<dynamic> _customers = [];
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String _customerSearch = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final client = getIt<ApiClient>();
      final response = await client.get('/artisans/customers');
      setState(() {
        _customers = (response.data as Map)['data'] as List? ?? [];
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sélectionnez un client'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    final payload = {
      'customerId': _selectedCustomerId,
      'title': _titleCtrl.text,
      'amount': int.tryParse(_amountCtrl.text) ?? 0,
      'deposit': int.tryParse(_depositCtrl.text) ?? 0,
      'dueDate': _dueDate?.toIso8601String(),
      'isUrgent': _isUrgent,
      'notes': _notesCtrl.text,
      'localId': localId,
    };

    try {
      final client = getIt<ApiClient>();
      await client.post('/artisans/orders', data: payload);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande créée avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      final offline = e is DioException &&
          (e.response == null ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout);
      if (!kIsWeb && offline) {
        await HiveService.addToSyncQueue(
          entity: 'order',
          action: 'create',
          localId: localId,
          payload: payload,
        );
      }
      if (mounted && !kIsWeb && offline) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Commande sauvegardée hors ligne. Elle sera synchronisée à la reconnexion.'),
            backgroundColor: AppColors.warning,
          ),
        );
        context.pop();
      } else if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d’enregistrer la commande : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Nouvelle Commande')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client
              const _SectionLabel('Client'),
              TextFormField(
                controller: _customerSearchCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un client par nom ou téléphone',
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.textSecondary),
                ),
                onChanged: (value) => setState(
                    () => _customerSearch = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _customers.any((c) =>
                        (c as Map)['id'] == _selectedCustomerId &&
                        (_customerSearch.isEmpty ||
                            '${c['name']} ${c['phone']}'
                                .toLowerCase()
                                .contains(_customerSearch)))
                    ? _selectedCustomerId
                    : null,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _customers.isEmpty
                      ? 'Aucun client disponible'
                      : 'Choisir un client',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textSecondary),
                ),
                items: _customers.where((c) {
                  final customer = c as Map<String, dynamic>;
                  return _customerSearch.isEmpty ||
                      '${customer['name']} ${customer['phone']}'
                          .toLowerCase()
                          .contains(_customerSearch);
                }).map((c) {
                  final customer = c as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: customer['id'] as String,
                    child: Text(customer['name'] as String,
                        style: const TextStyle(color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (v) {
                  final customer =
                      _customers.cast<Map<String, dynamic>>().firstWhere(
                            (c) => c['id'] == v,
                            orElse: () => <String, dynamic>{},
                          );
                  setState(() {
                    _selectedCustomerId = v;
                    _selectedCustomerName = customer['name'] as String?;
                  });
                },
                validator: (_) =>
                    _selectedCustomerId == null ? 'Client requis' : null,
              ),
              const SizedBox(height: 20),

              // Titre de la commande
              const _SectionLabel('Description'),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ex: Boubou 3 pièces en soie',
                  prefixIcon: Icon(Icons.description_outlined,
                      color: AppColors.textSecondary),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Description requise' : null,
              ),
              const SizedBox(height: 16),

              // Montant + acompte
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Montant (FCFA)'),
                        TextFormField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: '0'),
                          validator: (v) {
                            final amount = int.tryParse(v?.trim() ?? '');
                            return amount == null || amount <= 0
                                ? 'Montant invalide'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Acompte (FCFA)'),
                        TextFormField(
                          controller: _depositCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: '0'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return null;
                            final deposit = int.tryParse(value.trim());
                            final amount =
                                int.tryParse(_amountCtrl.text.trim());
                            if (deposit == null || deposit < 0)
                              return 'Acompte invalide';
                            if (amount != null && deposit > amount)
                              return 'Supérieur au total';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date de livraison
              const _SectionLabel('Date de livraison'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Sélectionner une date',
                        style: TextStyle(
                          color: _dueDate != null
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Urgence toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isUrgent
                        ? AppColors.error.withOpacity(0.4)
                        : AppColors.dividerDark,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Commande urgente',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    Switch(
                      value: _isUrgent,
                      activeColor: AppColors.error,
                      onChanged: (v) => setState(() => _isUrgent = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              const _SectionLabel('Notes (optionnel)'),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Tissu spécifique, style préféré, remarques...',
                ),
              ),
              const SizedBox(height: 32),

              // Bouton créer
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Créer la commande'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
