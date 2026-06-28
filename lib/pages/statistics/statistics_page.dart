import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../db/repositories/credit_repository.dart';
import '../../db/repositories/customer_repository.dart';
import '../../db/repositories/payment_repository.dart';
import '../../l10n/app_localizations.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _customerRepo = CustomerRepository();
  final _creditRepo = CreditRepository();
  final _paymentRepo = PaymentRepository();

  bool _isLoading = true;

  List<_CustomerWithDebt> _customersWithDebt = [];
  double _totalRevenue = 0;
  Map<String, double> _monthlyRevenue = {};
  int _activeCount = 0;
  int _overdueCount = 0;
  int _paidOffCount = 0;

  static const _storeId = 'default_store';
  static const _green = Color(0xFF10B981);
  static const _greenLight = Color(0xFF34D399);
  static const _greenDark = Color(0xFF059669);
  static const _greenPale = Color(0xFFD1FAE5);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customers = await _customerRepo.getActiveByStoreId(_storeId);

    final list = <_CustomerWithDebt>[];
    double totalRevenue = 0;
    final monthlyRev = <String, double>{};

    int active = 0;
    int overdue = 0;
    int paidOff = 0;

    for (final c in customers) {
      final totalCredit = await _creditRepo.getTotalByCustomerId(c.id);
      final totalPaid = await _paymentRepo.getTotalByCustomerId(c.id);
      final debt = totalCredit - totalPaid;

      if (debt > 0) {
        if (c.nextDueDate != null && c.nextDueDate!.isBefore(DateTime.now())) {
          overdue++;
        } else {
          active++;
        }
        list.add(_CustomerWithDebt(name: c.name, debt: debt));
      } else {
        paidOff++;
      }

      final payments = await _paymentRepo.getByCustomerId(c.id);
      for (final p in payments) {
        totalRevenue += p.amount;
        final key =
            '${p.paymentDate.year}-${p.paymentDate.month.toString().padLeft(2, '0')}';
        monthlyRev.update(key, (v) => v + p.amount, ifAbsent: () => p.amount);
      }
    }

    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      monthlyRev.putIfAbsent(key, () => 0);
    }

    list.sort((a, b) => b.debt.compareTo(a.debt));

    if (!mounted) return;
    setState(() {
      _customersWithDebt = list;
      _totalRevenue = totalRevenue;
      _monthlyRevenue = monthlyRev;
      _activeCount = active;
      _overdueCount = overdue;
      _paidOffCount = paidOff;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalCustomers = _activeCount + _overdueCount + _paidOffCount;

    return Scaffold(
      backgroundColor: colors.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _buildSummaryRow(t, theme, colors, totalCustomers),
            const SizedBox(height: 20),
            _buildSectionTitle(t.translate('monthly_trend'), colors),
            const SizedBox(height: 10),
            _buildRevenueBarChart(t, theme, colors),
            const SizedBox(height: 24),
            _buildSectionTitle(t.translate('debt_distribution'), colors),
            const SizedBox(height: 10),
            _buildDebtPieChart(t, theme, colors),
            const SizedBox(height: 24),
            _buildSectionTitle(t.translate('top_debtors'), colors),
            const SizedBox(height: 10),
            _buildTopDebtorsChart(t, theme, colors),
            const SizedBox(height: 24),
            _buildSectionTitle(t.translate('customer_health'), colors),
            const SizedBox(height: 10),
            _buildHealthPieChart(t, theme, colors, totalCustomers),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    AppLocalizations t,
    ThemeData theme,
    ColorScheme colors,
    int totalCustomers,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_greenDark, _green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                t.translate('total_revenue'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_totalRevenue.toStringAsFixed(2)} ${t.translate('dzd')}',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$totalCustomers ${t.translate('customers').toLowerCase()} · ${t.translate('overdue').toLowerCase()}: $_overdueCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _chartContainer(Widget child, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildRevenueBarChart(
    AppLocalizations t,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final sortedKeys = _monthlyRevenue.keys.toList()..sort();
    if (sortedKeys.isEmpty) {
      return _chartContainer(_emptyChart(t, colors), theme);
    }

    final maxVal = _monthlyRevenue.values.reduce((a, b) => a > b ? a : b);

    return _chartContainer(
      SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toStringAsFixed(2),
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sortedKeys.length) {
                      return const SizedBox.shrink();
                    }
                    final parts = sortedKeys[idx].split('-');
                    final month = int.tryParse(parts[1]) ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _monthAbbr(month, t),
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colors.outlineVariant.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: sortedKeys.asMap().entries.map((entry) {
              final value = _monthlyRevenue[entry.value] ?? 0;
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: _green,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    gradient: LinearGradient(
                      colors: [_greenLight, _greenDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          duration: const Duration(milliseconds: 300),
        ),
      ),
      theme,
    );
  }

  Widget _buildDebtPieChart(
    AppLocalizations t,
    ThemeData theme,
    ColorScheme colors,
  ) {
    if (_customersWithDebt.isEmpty) {
      return _chartContainer(_emptyChart(t, colors), theme);
    }

    final top5 = _customersWithDebt.take(5).toList();
    final others = _customersWithDebt
        .skip(5)
        .fold<double>(0, (sum, c) => sum + c.debt);

    final sections = <PieChartSectionData>[];
    final pieColors = [
      _green,
      _greenLight,
      _greenDark,
      const Color(0xFF6EE7B7),
      const Color(0xFFA7F3D0),
      const Color(0xFFD1FAE5),
    ];

    for (int i = 0; i < top5.length; i++) {
      sections.add(
        PieChartSectionData(
          color: pieColors[i % pieColors.length],
          value: top5[i].debt,
          title: top5[i].name.length > 6
              ? '${top5[i].name.substring(0, 6)}..'
              : top5[i].name,
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (others > 0) {
      sections.add(
        PieChartSectionData(
          color: colors.outlineVariant,
          value: others,
          title: t.translate('others'),
          radius: 45,
          titleStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return _chartContainer(
      SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
                duration: const Duration(milliseconds: 300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < top5.length; i++)
                    _legendItem(
                      pieColors[i % pieColors.length],
                      top5[i].name,
                      top5[i].debt.toStringAsFixed(2),
                      colors,
                    ),
                  if (others > 0)
                    _legendItem(
                      colors.outlineVariant,
                      t.translate('others'),
                      others.toStringAsFixed(2),
                      colors,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      theme,
    );
  }

  Widget _legendItem(
    Color color,
    String name,
    String value,
    ColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDebtorsChart(
    AppLocalizations t,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final top = _customersWithDebt.take(6).toList();
    if (top.isEmpty) {
      return _chartContainer(_emptyChart(t, colors), theme);
    }

    final maxDebt = top.first.debt;

    return _chartContainer(
      Column(
        children: top.map((c) {
          final ratio = maxDebt > 0 ? c.debt / maxDebt : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${c.debt.toStringAsFixed(2)} ${t.translate('dzd')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _greenDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: _greenPale.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ratio > 0.7 ? _greenDark : _green,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      theme,
    );
  }

  Widget _buildHealthPieChart(
    AppLocalizations t,
    ThemeData theme,
    ColorScheme colors,
    int totalCustomers,
  ) {
    if (totalCustomers == 0) {
      return _chartContainer(_emptyChart(t, colors), theme);
    }

    final sections = [
      PieChartSectionData(
        color: _green,
        value: _activeCount.toDouble(),
        title: '$_activeCount',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFFF59E0B),
        value: _overdueCount.toDouble(),
        title: '$_overdueCount',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: _greenPale,
        value: _paidOffCount.toDouble(),
        title: '$_paidOffCount',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: colors.onSurface.withValues(alpha: 0.7),
        ),
      ),
    ];

    return _chartContainer(
      SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
                duration: const Duration(milliseconds: 300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(
                    _green,
                    t.translate('active'),
                    '$_activeCount',
                    colors,
                  ),
                  const SizedBox(height: 6),
                  _legendItem(
                    const Color(0xFFF59E0B),
                    t.translate('overdue'),
                    '$_overdueCount',
                    colors,
                  ),
                  const SizedBox(height: 6),
                  _legendItem(
                    _greenPale,
                    t.translate('paid_off'),
                    '$_paidOffCount',
                    colors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      theme,
    );
  }

  Widget _emptyChart(AppLocalizations t, ColorScheme colors) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          t.translate('no_data_chart'),
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _monthAbbr(int month, AppLocalizations t) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }
}

class _CustomerWithDebt {
  final String name;
  final double debt;

  _CustomerWithDebt({required this.name, required this.debt});
}
