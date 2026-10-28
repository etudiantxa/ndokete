import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String, dynamic>? _subData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final client = getIt<ApiClient>();
      final response = await client.get('/subscriptions/my');
      setState(() {
        _subData = (response.data as Map)['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<bool?> _showPaymentSimulationDialog({
    required BuildContext context,
    required String planLabel,
    required int amount,
    required String method,
    required String phone,
  }) {
    final pinCtrl = TextEditingController();
    bool isProcessing = false;
    final isWave = method == 'WAVE';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isWave ? Icons.waves : Icons.phone_android,
                color: isWave ? AppColors.secondary : Colors.orange,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isWave ? 'Paiement Wave' : 'Paiement Orange Money',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.dividerDark),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Abonnement :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(planLabel, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('${NumberFormat('#,###', 'fr_FR').format(amount)} FCFA',
                            style: TextStyle(
                                color: isWave ? AppColors.secondary : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Entrez votre code secret a 4 chiffres pour autoriser le prelevement :',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '••••',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(dialogCtx, false),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isWave ? AppColors.secondary : Colors.orange,
                foregroundColor: Colors.black,
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (pinCtrl.text.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez entrer un code PIN à 4 chiffres.')),
                        );
                        return;
                      }
                      setDialogState(() => isProcessing = true);
                      await Future<void>.delayed(const Duration(milliseconds: 1200));
                      if (ctx.mounted) Navigator.pop(dialogCtx, true);
                    },
              child: isProcessing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Valider le Paiement', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upgradePlan(String plan, int amount) async {
    String selectedMethod = 'WAVE';

    final methodChosen = await showDialog<String>(
      context: context,
      builder: (methodCtx) => StatefulBuilder(
        builder: (ctx, setMethodState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Choisir le moyen de paiement', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selectionnez votre operateur Mobile Money :', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setMethodState(() => selectedMethod = 'WAVE'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'WAVE' ? AppColors.secondary.withValues(alpha: 0.2) : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selectedMethod == 'WAVE' ? AppColors.secondary : AppColors.dividerDark),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.waves, color: AppColors.secondary, size: 18),
                            SizedBox(width: 8),
                            Text('Wave', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setMethodState(() => selectedMethod = 'ORANGE_MONEY'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'ORANGE_MONEY' ? Colors.orange.withValues(alpha: 0.2) : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selectedMethod == 'ORANGE_MONEY' ? Colors.orange : AppColors.dividerDark),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_android, color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Text('Orange Money', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(methodCtx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(methodCtx, selectedMethod),
              child: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (methodChosen == null) return;

    final confirmed = await _showPaymentSimulationDialog(
      context: context,
      planLabel: 'Abonnement $plan Pro',
      amount: amount,
      method: methodChosen,
      phone: '+221771234567',
    );

    if (confirmed != true) return;

    try {
      final client = getIt<ApiClient>();
      await client.post('/subscriptions/upgrade', data: {
        'plan': plan,
        'method': methodChosen,
        'phone': '+221771234567',
      });
      await _loadSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Paiement $methodChosen valide & Abonnement active !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _downloadReceipt(String plan, String method) async {
    final pdf = pw.Document();
    final amount = plan == 'PREMIUM' ? '5 000 FCFA' : plan == 'PREMIUM_PLUS' ? '10 000 FCFA' : '0 FCFA';
    final operatorName = method == 'WAVE' ? 'Wave Mobile Money' : 'Orange Money';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5A623'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('NDOKETE PRO', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.SizedBox(height: 4),
                      pw.Text('Plateforme SaaS & Marketplace pour Artisans', style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('RECU DE PAIEMENT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.SizedBox(height: 4),
                      pw.Text('Ref: REC-${DateTime.now().millisecondsSinceEpoch}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('EMETTEUR :', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text('NDOKETE S.A.', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Dakar, Senegal', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    pw.Text('contact@ndokete.sn', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('DATE DE REGLEMENT :', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(DateFormat('dd/MM/yyyy a HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('Description du Plan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('Moyen de Paiement', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('Montant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('Abonnement Pro - Plan $plan', style: const pw.TextStyle(fontSize: 11))),
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(operatorName, style: const pw.TextStyle(fontSize: 11))),
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(amount, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E8F5E9'),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.green, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('STATUT : PAYE', style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.SizedBox(height: 4),
                      pw.Text('Total Regle : $amount', style: pw.TextStyle(color: PdfColors.green900, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('Merci pour votre confiance. NDOKETE - Solution SaaS pour Artisans Senegalais.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Recu_Abonnement_NDOKETE.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _subData?['plan'] as String? ?? 'GRATUIT';
    final status = _subData?['status'] as String? ?? 'ACTIF';
    final expiresAt = DateTime.tryParse(_subData?['expiresAt'] as String? ?? '');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Mon Abonnement & Facturation'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF252836), Color(0xFF1A1D27)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('PLAN ACTUEL', style: TextStyle(color: AppColors.primary, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status, style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        plan,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expiresAt != null
                            ? 'Renouvellement le : ${DateFormat('dd/MM/yyyy').format(expiresAt)}'
                            : 'Accès illimité actif',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      if (plan != 'GRATUIT' && plan != 'FREEMIUM')
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          onPressed: () => _downloadReceipt(plan, 'WAVE'),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Télécharger le reçu PDF'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                const Text('Plans d’Abonnement Pro', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                _PlanCard(
                  title: 'GRATUIT (Freemium)',
                  price: '0 FCFA',
                  features: const ['20 clients max', '5 produits marketplace', 'Gestion de base'],
                  isCurrent: plan == 'GRATUIT' || plan == 'FREEMIUM',
                  onTap: () {},
                ),
                const SizedBox(height: 14),

                _PlanCard(
                  title: 'PREMIUM',
                  price: '5 000 FCFA / mois',
                  features: const ['Clients illimités', 'Produits illimités', 'Assistant IA vocal', 'Statistiques financières'],
                  isCurrent: plan == 'PREMIUM',
                  onTap: () => _upgradePlan('PREMIUM', 5000),
                  isFeatured: true,
                ),
                const SizedBox(height: 14),

                _PlanCard(
                  title: 'PREMIUM PLUS',
                  price: '10 000 FCFA / mois',
                  features: const ['Tout illimité + Support prioritaire', 'Badge Artisan Vétéran VIP', 'Coaching & Visibilité accrue'],
                  isCurrent: plan == 'PREMIUM_PLUS',
                  onTap: () => _upgradePlan('PREMIUM_PLUS', 10000),
                ),
              ],
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isCurrent;
  final VoidCallback onTap;
  final bool isFeatured;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.features,
    required this.isCurrent,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isFeatured ? AppColors.primary : AppColors.dividerDark, width: isFeatured ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(price, style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? AppColors.surfaceDark : AppColors.primary,
                foregroundColor: isCurrent ? AppColors.textSecondary : Colors.black,
              ),
              onPressed: isCurrent ? null : onTap,
              child: Text(isCurrent ? 'Plan Actuel' : 'Choisir ce plan', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
