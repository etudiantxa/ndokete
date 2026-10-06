import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class TreasuryPage extends StatefulWidget {
  const TreasuryPage({super.key});

  @override
  State<TreasuryPage> createState() => _TreasuryPageState();
}

class _TreasuryPageState extends State<TreasuryPage> {
  Map<String, dynamic>? _treasury;
  List<dynamic> _weeklyData = [];
  bool _loading = true;
  final _currency = NumberFormat('#,###', 'fr_FR');
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = getIt<ApiClient>();
      final [treas, weekly] = await Future.wait([
        client.get('/artisans/transactions/treasury'),
        client.get('/artisans/transactions/weekly'),
      ]);
      setState(() {
        _treasury = (treas.data as Map)['data'] as Map<String, dynamic>;
        _weeklyData = (weekly.data as Map)['data'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Trésorerie & Bénéfices'),
        actions: [
          IconButton(icon: const Icon(Icons.download_outlined), onPressed: () => context.push('/finance/report')),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDate: DateTime.now(),
              );
              if (selected != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Période sélectionnée : ${selected.day}/${selected.month}/${selected.year}'),
                ));
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Période
                  Text(
                    DateFormat('MMMM yyyy', 'fr_FR').format(DateTime.now()),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // KPIs recettes/dépenses
                  Row(
                    children: [
                      Expanded(
                        child: _KpiMini(
                          label: 'Recettes',
                          value: '${_currency.format(_treasury?['income'] ?? 0)}.000',
                          icon: Icons.trending_up,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiMini(
                          label: 'Dépenses',
                          value: '${_currency.format(_treasury?['expenses'] ?? 0)}.000',
                          icon: Icons.trending_down,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bénéfice net
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.dividerDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bénéfice Net', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_currency.format(_treasury?['netProfit'] ?? 0)} FCFA',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getHealthColor().withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.circle, color: _getHealthColor(), size: 8),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SANTÉ FINANCIÈRE ${_treasury?['healthScore'] ?? ''}',
                                    style: TextStyle(
                                      color: _getHealthColor(),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Graphique évolution hebdomadaire
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ÉVOLUTION HEBDOMADAIRE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1)),
                      const Text('À CONSULTER BRAQUAGE', style: TextStyle(color: AppColors.primary, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Chart
                  SizedBox(
                    height: 120,
                    child: _weeklyData.isEmpty
                        ? const Center(child: Text('Données insuffisantes', style: TextStyle(color: AppColors.textDisabled)))
                        : LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, _) => Text(
                                      'SEM${value.toInt() + 1}',
                                      style: const TextStyle(color: AppColors.textDisabled, fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _weeklyData.asMap().entries.map((e) {
                                    final data = e.value as Map<String, dynamic>;
                                    return FlSpot(e.key.toDouble(), (data['income'] as num).toDouble() / 100000);
                                  }).toList(),
                                  isCurved: true,
                                  color: AppColors.success,
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.success.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Transactions récentes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('TRANSACTIONS RÉCENTES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1)),
                      Text('VOIR TOUT', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('AUJOURD\'HUI', style: TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                  const SizedBox(height: 8),

                  ...(_treasury?['recentTransactions'] as List? ?? []).take(5).map((t) {
                    final tx = t as Map<String, dynamic>;
                    final isIncome = tx['type'] == 'ENTREE';
                    return _TransactionItem(transaction: tx, currency: _currency, isIncome: isIncome);
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.dividerDark)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavTab(icon: Icons.home_outlined, label: 'Aperçu', selected: _selectedNav == 0, onTap: () => setState(() => _selectedNav = 0)),
            _NavTab(icon: Icons.receipt_long_outlined, label: 'Commandes', selected: _selectedNav == 1, onTap: () { setState(() => _selectedNav = 1); context.push('/orders'); }),
            _NavTab(icon: Icons.storefront_outlined, label: 'Marché', selected: _selectedNav == 2, onTap: () { setState(() => _selectedNav = 2); context.push('/marketplace'); }),
            _NavTab(icon: Icons.person_outline, label: 'Profil', selected: _selectedNav == 3, onTap: () { setState(() => _selectedNav = 3); context.push('/profile'); }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/finance/new'),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nouvelle Transaction', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Color _getHealthColor() {
    switch (_treasury?['healthScore']) {
      case 'EXCELLENTE': return AppColors.success;
      case 'BONNE': return AppColors.secondary;
      case 'CORRECTE': return AppColors.warning;
      default: return AppColors.error;
    }
  }
}

class _KpiMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiMini({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final NumberFormat currency;
  final bool isIncome;

  const _TransactionItem({required this.transaction, required this.currency, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.success : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction['description'] as String? ?? transaction['category'] as String,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(transaction['category'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${currency.format(transaction['amount'])}.000',
            style: TextStyle(
              color: isIncome ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavTab({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}
