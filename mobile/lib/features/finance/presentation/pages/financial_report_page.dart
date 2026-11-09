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
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête du document PDF
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.amber300),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 36,
                    height: 36,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber400,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Center(
                      child: pw.Text('N', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(artisanName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.SizedBox(height: 2),
                      pw.Text('Rapport d\'activité mensuel - $period', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
                      pw.Text('Généré le $today', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Résumé Financier
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total des Revenus', style: const pw.TextStyle(fontSize: 12, color: PdfColors.black)),
                      pw.Text(amount(totalIncome), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey200),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total des Dépenses', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      pw.Text(amount(totalExpenses), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.green300),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Bénéfice Net', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        pw.Text(amount(netProfit), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tableau des Transactions du mois
            if (transactions.isNotEmpty) ...[
              pw.Text('Détail des Transactions du Mois', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: const ['Date', 'Catégorie', 'Type', 'Montant'],
                data: transactions.take(15).map((t) {
                  final tx = t as Map<String, dynamic>;
                  final date = tx['date'] != null ? DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.parse(tx['date'].toString())) : '';
                  final isIncome = tx['type'] == 'ENTREE';
                  return [
                    date,
                    tx['category'] ?? '',
                    isIncome ? 'Recette' : 'Dépense',
                    '${isIncome ? '+' : '-'}${amount(tx['amount'])}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.amber100),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: pw.TableBorder.all(color: PdfColors.grey300),
              ),
              pw.SizedBox(height: 20),
            ],

            pw.Spacer(),

            // Pied de page officiel
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('NDOKETE - Solution de gestion pour artisans', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Document officiel certifié', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
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
