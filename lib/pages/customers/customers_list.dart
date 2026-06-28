import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/repositories/customer_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/customer_calculator.dart';
import '../../models/customer.dart';
import 'add_customer.dart';
import 'customer_detail.dart';

class CustomersListPage extends StatefulWidget {
  const CustomersListPage({super.key});

  @override
  State<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends State<CustomersListPage> {
  final CustomerRepository _customerRepo = CustomerRepository();
  final CustomerCalculator _calculator = CustomerCalculator();

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  Map<String, double> _customerDebts = {};
  Map<String, bool> _customerOverdue = {};
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _sortMode = 'name';
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  static const _avatarColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await _customerRepo.getActiveByStoreId('default_store');
    final debts = <String, double>{};
    final overdue = <String, bool>{};
    for (final c in customers) {
      final debt = await _calculator.currentDebt(c.id);
      debts[c.id] = debt;
      overdue[c.id] = c.nextDueDate != null &&
          c.nextDueDate!.isBefore(DateTime.now()) &&
          debt > 0;
    }
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _customerDebts = debts;
      _customerOverdue = overdue;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();
    setState(() {
      _filteredCustomers = _customers.where((c) {
        if (query.isNotEmpty &&
            !c.name.toLowerCase().contains(query) &&
            (c.phone == null || !c.phone!.contains(query))) {
          return false;
        }
        final debt = _customerDebts[c.id] ?? 0;
        final isOverdue = _customerOverdue[c.id] ?? false;
        switch (_selectedFilter) {
          case 'has_debt':
            return debt > 0 && !isOverdue;
          case 'paid_off':
            return debt == 0;
          case 'overdue':
            return isOverdue;
          default:
            return true;
        }
      }).toList();

      switch (_sortMode) {
        case 'date_added':
          _filteredCustomers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        case 'credit_high':
          _filteredCustomers.sort(
              (a, b) => (_customerDebts[b.id] ?? 0).compareTo(_customerDebts[a.id] ?? 0));
        case 'credit_low':
          _filteredCustomers.sort(
              (a, b) => (_customerDebts[a.id] ?? 0).compareTo(_customerDebts[b.id] ?? 0));
        default:
          _filteredCustomers.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  void _showSortOptions() {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final sortOptions = [
          ('name', t.translate('sort_name'), Icons.sort_by_alpha),
          ('date_added', t.translate('sort_date_added'), CupertinoIcons.clock),
          ('credit_high', t.translate('sort_credit_high'), CupertinoIcons.arrow_up),
          ('credit_low', t.translate('sort_credit_low'), CupertinoIcons.arrow_down),
        ];
        return Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.translate('sort_by'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...sortOptions.map((s) => ListTile(
                    leading: Icon(s.$3),
                    title: Text(s.$2),
                    trailing: _sortMode == s.$1
                        ? Icon(CupertinoIcons.check_mark, color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() => _sortMode = s.$1);
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Color _getAvatarColor(String name) {
    final index = name.hashCode.abs() % _avatarColors.length;
    return _avatarColors[index];
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _messageCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCustomers,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchField(theme, t, isRtl)),
                  SliverToBoxAdapter(child: _buildFilterRow(theme, t)),
                  if (_filteredCustomers.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState(theme, t))
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildCustomerCard(
                                _filteredCustomers[index], theme, t),
                        childCount: _filteredCustomers.length,
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerPage()),
          );
          if (result == true) {
            _loadCustomers();
          }
        },
        child: const Icon(CupertinoIcons.person_add),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme, AppLocalizations t, bool isRtl) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        onChanged: (value) {
          _searchQuery = value;
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: t.translate('search_hint'),
          hintTextDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          prefixIcon: const Icon(CupertinoIcons.search),
          suffixIcon: IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            onPressed: _showSortOptions,
          ),
          filled: true,
          fillColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(ThemeData theme, AppLocalizations t) {
    final filters = [
      ('all', t.translate('all_filter')),
      ('has_debt', t.translate('has_debt')),
      ('paid_off', t.translate('paid_off')),
      ('overdue', t.translate('overdue')),
    ];

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f.$1;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                label: Text(f.$2),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = f.$1);
                  _applyFilters();
                },
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.person_2,
              size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(t.translate('no_customers'),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, ThemeData theme, AppLocalizations t) {
    final debt = _customerDebts[customer.id] ?? 0;
    final isOverdue = _customerOverdue[customer.id] ?? false;
    final avatarColor = _getAvatarColor(customer.name);
    final initial = customer.name.isNotEmpty ? customer.name[0] : '?';

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailPage(customerId: customer.id),
              ),
            ).then((_) => _loadCustomers());
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildDebtChip(debt, isOverdue, t),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (debt > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${t.translate('debt')}: ${debt.toStringAsFixed(2)} ${t.translate('dzd')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isOverdue ? Colors.red : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (customer.address != null &&
                          customer.address!.isNotEmpty)
                        Text(
                          customer.address!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (customer.phone != null &&
                    customer.phone!.isNotEmpty) ...[
                  IconButton(
                    icon: Icon(CupertinoIcons.phone,
                        size: 20, color: theme.colorScheme.primary),
                    onPressed: () => _callCustomer(customer.phone),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: Icon(CupertinoIcons.chat_bubble,
                        size: 20, color: theme.colorScheme.primary),
                    onPressed: () => _messageCustomer(customer.phone),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtChip(double debt, bool isOverdue, AppLocalizations t) {
    if (debt > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isOverdue
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isOverdue ? t.translate('overdue') : t.translate('has_debt'),
          style: TextStyle(
            fontSize: 11,
            color: isOverdue ? Colors.red : Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        t.translate('paid_off'),
        style: const TextStyle(
          fontSize: 11,
          color: Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
