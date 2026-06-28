import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'logic/home_calculator.dart';
import 'db/repositories/store_repository.dart';
import 'db/repositories/customer_repository.dart';
import 'models/store.dart';
import 'pages/settings/settings.dart';
import 'pages/profile/profile.dart';
import 'pages/customers/customers_list.dart';
import 'pages/notifications/notifications_page.dart';
import 'pages/statistics/statistics_page.dart';
import 'pages/store/store_details_page.dart';
import 'widgets/animated_bottom_bar.dart';
import 'widgets/metric_card/metric_card.dart';
import 'models/icon_model.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  final PageController pageController = PageController();
  final HomeCalculator _calculator = HomeCalculator();
  final StoreRepository _storeRepo = StoreRepository();
  final CustomerRepository _customerRepo = CustomerRepository();

  HomeMetrics? _metrics;
  List<Operation>? _operations;
  Store? _store;
  PeriodFilter _periodFilter = PeriodFilter.month;
  int _notificationCount = 0;
  bool _isLoading = true;

  static const _storeId = 'default_store';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _calculator.calculateFiltered(_storeId, _periodFilter),
      _calculator.todayOperations(_storeId),
      _storeRepo.getById(_storeId),
      _customerRepo.getDueToday(_storeId),
      _customerRepo.getOverdue(_storeId),
    ]);
    if (!mounted) return;
    setState(() {
      _metrics = results[0] as HomeMetrics;
      _operations = results[1] as List<Operation>;
      _store = results[2] as Store?;
      final due = results[3] as List<dynamic>;
      final overdue = results[4] as List<dynamic>;
      _notificationCount = due.length + overdue.length;
      _isLoading = false;
    });
  }

  void _setFilter(PeriodFilter filter) {
    setState(() => _periodFilter = filter);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isRtl = t.isRtl;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            setState(() => _notificationCount = 0);
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
            _loadData();
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 24),
                if (_notificationCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        title: Text(
          selectedIndex == 0
              ? ''
              : selectedIndex == 1
              ? t.translate('customers')
              : selectedIndex == 2
              ? t.translate('my_profile')
              : selectedIndex == 3
              ? t.translate('statistics')
              : t.translate('settings'),
        ),
        actions: [
          if (_store != null)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreDetailsPage(storeId: _store!.id),
                ),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _store!.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.store_outlined,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: pageController,
          children: [
            _buildHomeTab(t, theme),
            const CustomersListPage(),
            const ProfilePage(),
            const StatisticsPage(),
            const SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBottomBar(
        currentIcon: selectedIndex,
        onTap: (index) {
          setState(() => selectedIndex = index);
          if (index == 0) _loadData();
          pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
          );
        },
        icons: const [
          IconModel(id: 0, icon: Icons.home_outlined),
          IconModel(id: 1, icon: Icons.people_outline),
          IconModel(id: 2, icon: Icons.person_outline),
          IconModel(id: 3, icon: Icons.bar_chart_outlined),
          IconModel(id: 4, icon: Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _buildHomeTab(AppLocalizations t, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final metrics = _metrics!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDebtSummary(t, theme, metrics),
            const SizedBox(height: 14),
            _buildFilterRow(t, theme),
            const SizedBox(height: 12),
            _buildMetricGrid(t, theme, metrics),
            const SizedBox(height: 20),
            _buildOperationsSection(t, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummary(
    AppLocalizations t,
    ThemeData theme,
    HomeMetrics metrics,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -15,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 16,
            child: Icon(
              Icons.store_rounded,
              size: 40,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.translate('total_debts'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${metrics.totalOutstandingDebt.toStringAsFixed(2)} ${t.translate('dzd')}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_periodFilter == PeriodFilter.month ? t.translate('month') : t.translate('week')} · ${t.translate('dzd')}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(AppLocalizations t, ThemeData theme) {
    return Row(
      children: [
        _filterChip(t.translate('week'), PeriodFilter.week, theme),
        const SizedBox(width: 10),
        _filterChip(t.translate('month'), PeriodFilter.month, theme),
      ],
    );
  }

  Widget _filterChip(String label, PeriodFilter filter, ThemeData theme) {
    final isSelected = _periodFilter == filter;
    return GestureDetector(
      onTap: () => _setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricGrid(
    AppLocalizations t,
    ThemeData theme,
    HomeMetrics metrics,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: [
        MetricCard(
          icon: Icons.people_alt_outlined,
          label: t.translate('customer_count'),
          value: '${metrics.customerCount}',
          color: const Color(0xFF6366F1),
          subtitle: '${metrics.activeDebtCount} ${t.translate('active_debts').toLowerCase()}',
        ),
        MetricCard(
          icon: Icons.warning_amber_rounded,
          label: t.translate('overdue_customers'),
          value: '${metrics.overdueCustomerCount}',
          color: const Color(0xFFEF4444),
          subtitle: metrics.customerCount > 0
              ? '${(metrics.overdueCustomerCount * 100 / metrics.customerCount).toStringAsFixed(0)}% ${t.translate('of_total').toLowerCase()}'
              : null,
        ),
        MetricCard(
          icon: Icons.trending_up_rounded,
          label: t.translate('daily_income'),
          value:
              '${metrics.todayIncome.toStringAsFixed(2)} ${t.translate('dzd')}',
          color: const Color(0xFF10B981),
          smallValue: true,
          subtitle: '${t.translate('period').toLowerCase()} · ${_periodFilter == PeriodFilter.month ? t.translate('month') : t.translate('week')}',
        ),
        MetricCard(
          icon: Icons.receipt_long_outlined,
          label: t.translate('active_debts'),
          value: '${metrics.activeDebtCount}',
          color: const Color(0xFFF59E0B),
          subtitle: metrics.activeDebtCount > 0
              ? '${metrics.totalOutstandingDebt.toStringAsFixed(2)} ${t.translate('dzd')} ${t.translate('total').toLowerCase()}'
              : null,
        ),
      ],
    );
  }

  Widget _buildOperationsSection(AppLocalizations t, ThemeData theme) {
    final ops = _operations ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              t.translate('today_operations'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (ops.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 26,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 12),
                  Text(
                    t.translate('no_operations'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          )
        else
          ...ops.map((op) => _operationTile(op, t, theme)),
      ],
    );
  }

  Widget _operationTile(Operation op, AppLocalizations t, ThemeData theme) {
    final isCredit = op.type == OperationType.credit;
    final color = isCredit ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final icon = isCredit
        ? Icons.shopping_cart_outlined
        : Icons.payments_outlined;
    final label = isCredit ? t.translate('purchase') : t.translate('payment');
    final sign = isCredit ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          op.customerName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (op.note != null && op.note!.isNotEmpty)
                          Text(
                            op.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$sign${op.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
