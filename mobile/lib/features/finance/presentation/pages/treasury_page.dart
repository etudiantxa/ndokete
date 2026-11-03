import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

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
  String _selectedPeriod = 'month'; // 'today', 'week', 'month', 'all'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = getIt<ApiClient>();
      final [treas, weekly] = await Future.wait([
        client.get('/artisans/transactions/treasury?period=$_selectedPeriod'),
        client.get('/artisans/transactions/weekly'),
      ]);
      setState(() {
        _treasury = (treas.data as Map)['data'] as Map<String, dynamic>;
        _weeklyData = (weekly.data as Map)['data'] as List? ?? [];
        _loading = false;
      });
    } catch (e) {
      final is403 = (e is DioException && e.response?.statusCode == 403) ||
          e.toString().contains('403') ||
          e.toString().contains('Forbidden');
      setState(() {
        if (is403) _accessDenied = true;
        _loading = false;
      });
    }
  }

  Widget _periodChip(String label, String value) {
    final selected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      labelStyle: TextStyle(
          color: selected ? Colors.black : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12),
      onSelected: (_) {
        setState(() => _selectedPeriod = value);
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_accessDenied) {
      return const _AccessDeniedView();
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && !authState.user.isOwner && !authState.user.canManageFinances) {
      return const _AccessDeniedView();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Trésorerie & Bénéfices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Sélectionner une date',
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDate: DateTime.now(),
              );
              if (selected != null && mounted) {
                setState(() => _selectedPeriod = 'all');
                _load();
                final localCtx = context;
                ScaffoldMessenger.of(localCtx).showSnackBar(SnackBar(
                  content: Text('Période filtrée au : ${selected.day}/${selected.month}/${selected.year}'),
                ));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Rapport financier',
            onPressed: () => context.push('/finance/report'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        onPressed: () async {
          await context.push('/finance/new');
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Sélecteur de période interactif
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _periodChip('Aujourd’hui', 'today'),
                        const SizedBox(width: 8),
                        _periodChip('Cette semaine', 'week'),
                        const SizedBox(width: 8),
                        _periodChip('Ce mois', 'month'),
                        const SizedBox(width: 8),
                        _periodChip('Tout', 'all'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // KPIs recettes/dépenses
                  Row(
                    children: [
                      Expanded(
                        child: _KpiMini(
                          label: 'Recettes',
                          value:
                              '${_currency.format(_treasury?['totalIncome'] ?? 0)} FCFA',
                          icon: Icons.trending_up,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiMini(
                          label: 'Dépenses',
                          value:
                              '${_currency.format(_treasury?['totalExpenses'] ?? 0)} FCFA',
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
                        const Text('Bénéfice Net',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${_currency.format(_treasury?['netProfit'] ?? 0)} FCFA',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getHealthColor()
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle,
                                      color: _getHealthColor(), size: 6),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SCORE: ${_treasury?['healthScore'] ?? 'EXCELLENT'}',
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ÉVOLUTION HEBDOMADAIRE',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              letterSpacing: 1)),
                      Text('4 SEMAINES',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.dividerDark),
                    ),
                    child: SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                getTitlesWidget: (value, meta) {
                                  const weeks = [
                                    'S1',
                                    'S2',
                                    'S3',
                                    'S4 (Actuelle)'
                                  ];
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < weeks.length) {
                                    return Text(weeks[idx],
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _weeklyData.isNotEmpty
                                  ? _weeklyData
                                      .asMap()
                                      .entries
                                      .map((e) => FlSpot(e.key.toDouble(),
                                          (e.value['amount'] ?? 0).toDouble()))
                                      .toList()
                                  : const [
                                      FlSpot(0, 10000),
                                      FlSpot(1, 25000),
                                      FlSpot(2, 40000),
                                      FlSpot(3, 65000)
                                    ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transactions récentes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TRANSACTIONS RÉCENTES',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              letterSpacing: 1)),
                      TextButton(
                        onPressed: () => context.push('/finance/transactions'),
                        child: const Text('VOIR TOUT',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...?((_treasury?['recentTransactions'] as List?)?.map(
                        (tx) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.dividerDark),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: (tx['type'] == 'ENTREE'
                                          ? AppColors.success
                                          : AppColors.error)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  tx['type'] == 'ENTREE'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: tx['type'] == 'ENTREE'
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['category'] ?? 'Transaction',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      tx['description'] ??
                                          (tx['order']?['title'] ?? ''),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${tx['type'] == 'ENTREE' ? '+' : '-'}${_currency.format(tx['amount'] ?? 0)}',
                                style: TextStyle(
                                  color: tx['type'] == 'ENTREE'
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Color _getHealthColor() {
    final score = _treasury?['healthScore'] as String? ?? '';
    if (score.contains('DÉFICIT') || score.contains('ATTENTION')) {
      return AppColors.error;
    }
    if (score.contains('MOYEN')) return AppColors.warning;
    return AppColors.success;
  }
}

class _KpiMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiMini({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    String cleanVal = value;
    if (cleanVal.endsWith('.000')) {
      cleanVal = cleanVal.substring(0, cleanVal.length - 4);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cleanVal,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
