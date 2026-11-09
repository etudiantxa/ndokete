import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  Map<String, dynamic>? _report;
  bool _loading = true;
  DateTime _selectedMonth = DateTime.now();
  final _currency = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final client = getIt<ApiClient>();
      final response = await client.get(
        '/artisans/transactions/report/${_selectedMonth.year}/${_selectedMonth.month}',
      );
      if (!mounted) return;
      setState(() {
        _report = (response.data as Map)['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    final report = _report;
    if (report == null) return;
    final pdf = pw.Document();
    final period = DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth);
    final today = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(DateTime.now());
    String amount(dynamic value) => '${_currency.format(value ?? 0)} FCFA';

    final totalIncome = report['totalIncome'] ?? 0;
    final totalExpenses = report['totalExpenses'] ?? 0;
    final netProfit = report['netProfit'] ?? 0;
    final artisanName = report['artisanName'] as String? ?? 'Atelier NDOKETE';
    final transactions = (report['transactions'] as List?) ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête Exécutif VIP
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1E293B'),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 42,
                        height: 42,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F59E0B'),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Center(
                          child: pw.Text('N', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        ),
                      ),
                      pw.SizedBox(width: 14),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(artisanName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          pw.SizedBox(height: 3),
                          pw.Text('RAPPORT FINANCIER MENSUEL - ${period.toUpperCase()}', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#F59E0B'), fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ÉDITION OFFICIELLE', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#94A3B8'), fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(today, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Cartes KPIs
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RECETTES', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#64748B'), fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text(amount(totalIncome), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A'))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FEF2F2'),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromHex('#FCA5A5')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DÉPENSES', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#991B1B'), fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text(amount(totalExpenses), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#DC2626'))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#ECFDF5'),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromHex('#6EE7B7')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BÉNÉFICE NET', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#065F46'), fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text(amount(netProfit), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#047857'))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Journal des Transactions
            pw.Text('JOURNAL DES TRANSACTIONS DU MOIS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B'))),
            pw.SizedBox(height: 8),
            if (transactions.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headers: const ['Date', 'Catégorie', 'Type', 'Montant Net'],
                data: transactions.take(20).map((t) {
                  final tx = t as Map<String, dynamic>;
                  final date = tx['date'] != null ? DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(DateTime.parse(tx['date'].toString())) : '';
                  final isIncome = tx['type'] == 'ENTREE';
                  return [
                    date,
                    tx['category'] ?? '',
                    isIncome ? 'Recette (+)' : 'Dépense (-)',
                    '${isIncome ? '+' : '-'}${amount(tx['amount'])}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E293B')),
                cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1')),
              )
            else
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9'), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Center(child: pw.Text('Aucune transaction enregistrée pour cette période.', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#64748B')))),
              ),

            pw.Spacer(),

            // Pied de page certifié
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DOCUMENT COMPTABLE CERTIFIÉ PAR NDOKETE - PLATEFORME SAAS ARTISANAT', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#64748B'))),
                  pw.Text('CONFIDENTIEL', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D97706'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'ndokete-rapport-${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export PDF impossible : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _openWhatsAppShare() async {
    final report = _report;
    if (report == null) return;
    final message = [
      'Rapport financier NDOKETE — ${DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth)}',
      'Atelier : ${report['artisanName'] ?? 'Atelier'}',
      'Revenus : ${_currency.format(report['totalIncome'] ?? 0)} FCFA',
      'Dépenses : ${_currency.format(report['totalExpenses'] ?? 0)} FCFA',
      'Bénéfice net : ${_currency.format(report['netProfit'] ?? 0)} FCFA',
    ].join('\n');
    final uri = Uri.https('wa.me', '/', {'text': message});
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Impossible d’ouvrir WhatsApp : $error'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Rapport Financier')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PÉRIODE DU RAPPORT',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  // Sélecteur mois
                  GestureDetector(
                    onTap: _pickMonth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dividerDark),
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MMMM yyyy', 'fr_FR')
                                .format(_selectedMonth),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Aperçu du document',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),

                  // Aperçu du rapport (style document)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête rapport
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('N',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _report?['artisanName'] as String? ??
                                      'Atelier',
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                                const Text(
                                  'Rapport d\'activité mensuel',
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 11),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy', 'fr_FR')
                                      .format(DateTime.now()),
                                  style: const TextStyle(
                                      color: Colors.black38, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        const Divider(color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 16),

                        // Ligne revenus
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total des Revenus',
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 13)),
                            Text(
                              '${_currency.format(_report?['totalIncome'] ?? 0)} FCFA',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Ligne dépenses
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total des Dépenses',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 13)),
                            Text(
                              '${_currency.format(_report?['totalExpenses'] ?? 0)} FCFA',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 12),

                        // Bénéfice net
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Bénéfice Net',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            Text(
                              '${_currency.format(_report?['netProfit'] ?? 0)} FCFA',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        const Divider(color: Color(0xFFE0E0E0)),

                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Color(0xFF9E9E9E), size: 14),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Ce rapport est idéal à partager avec votre comptable ou banque. Il peut être exporté en PDF ou partagé via WhatsApp.',
                                style: TextStyle(
                                    color: Colors.black38,
                                    fontSize: 10,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Boutons export
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportPdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceDark,
                            foregroundColor: AppColors.textPrimary,
                          ),
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('PDF'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openWhatsAppShare,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success.withValues(alpha: 0.2),
                            foregroundColor: AppColors.success,
                          ),
                          icon: const Icon(Icons.message_outlined, size: 18),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Choisir une période',
            style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: 280,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 6,
            itemBuilder: (_, i) {
              final month = DateTime(now.year, now.month - i);
              return ListTile(
                title: Text(
                  DateFormat('MMMM yyyy', 'fr_FR').format(month),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedMonth = month);
                  _loadReport();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
