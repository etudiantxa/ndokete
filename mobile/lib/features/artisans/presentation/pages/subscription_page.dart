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

  Future<void> _upgradePlan(String plan) async {
    try {
      final client = getIt<ApiClient>();
      await client.post('/subscriptions/upgrade', data: {
        'plan': plan,
        'method': 'WAVE',
        'phone': '+221771234567',
      });
      await _loadSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Abonnement mis à jour avec succès !'),
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

  Future<void> _downloadReceipt(String plan) async {
    final pdf = pw.Document();
    final amount = plan == 'PREMIUM' ? '5 000 FCFA' : plan == 'PREMIUM_PLUS' ? '10 000 FCFA' : '0 FCFA';

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('NDOKETE PRO', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                pw.Text('REÇU D’ABONNEMENT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey),
            pw.SizedBox(height: 10),
            pw.Text('Date : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Type d’abonnement : $plan', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('Montant réglé : $amount', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('Moyen de paiement : Wave Mobile Money', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Statut : PAYÉ (Validé)', style: pw.TextStyle(fontSize: 12, color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey),
            pw.Spacer(),
            pw.Center(
              child: pw.Text('Merci d’utiliser NDOKETE pour la gestion de votre atelier !', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reçu_Abonnement_NDOKETE.pdf',
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
                          onPressed: () => _downloadReceipt(plan),
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
                  onTap: () => _upgradePlan('PREMIUM'),
                  isFeatured: true,
                ),
                const SizedBox(height: 14),

                _PlanCard(
                  title: 'PREMIUM PLUS',
                  price: '10 000 FCFA / mois',
                  features: const ['Tout illimité + Support prioritaire', 'Badge Artisan Vétéran VIP', 'Coaching & Visibilité accrue'],
                  isCurrent: plan == 'PREMIUM_PLUS',
                  onTap: () => _upgradePlan('PREMIUM_PLUS'),
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
            mainAxisAlignment: MainAxisAlignment.spanBetween,
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
