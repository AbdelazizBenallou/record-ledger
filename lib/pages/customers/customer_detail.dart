import 'package:flutter/material.dart';

import '../../db/repositories/credit_repository.dart';
import '../../db/repositories/customer_repository.dart';
import '../../db/repositories/payment_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/customer_calculator.dart';
import '../../utils/snackbar_utils.dart';
import '../../models/credit_transaction.dart';
import '../../models/customer.dart';
import '../../models/payment.dart';
import '../../widgets/appbar/app_bar.dart';
import '../../widgets/button/button.dart';

class _TransactionItem {
  final DateTime date;
  final double amount;
  final String? note;
  final bool isCredit;
  final String id;

  _TransactionItem({
    required this.date,
    required this.amount,
    this.note,
    required this.isCredit,
    required this.id,
  });
}

class CustomerDetailPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final CustomerRepository _customerRepo = CustomerRepository();
  final CreditRepository _creditRepo = CreditRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final CustomerCalculator _calculator = CustomerCalculator();

  Customer? _customer;
  double _currentDebt = 0;
  double _totalPaid = 0;
  DateTime? _lastPaymentDate;
  List<_TransactionItem> _transactions = [];
  List<_TransactionItem> _filteredTransactions = [];
  DateTime? _selectedDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final customer = await _customerRepo.getById(widget.customerId);
    if (customer == null) {
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final results = await Future.wait([
      _calculator.currentDebt(customer.id),
      _calculator.totalPaid(customer.id),
      _paymentRepo.getLastPaymentDate(customer.id),
      _creditRepo.getByCustomerId(customer.id),
      _paymentRepo.getByCustomerId(customer.id),
    ]);

    final debt = results[0] as double;
    final paid = results[1] as double;
    final lastPay = results[2] as DateTime?;
    final credits = results[3] as List<CreditTransaction>;
    final payments = results[4] as List<Payment>;

    final txns = <_TransactionItem>[
      for (final c in credits)
        _TransactionItem(
          date: c.transactionDate,
          amount: c.amount,
          note: c.note,
          isCredit: true,
          id: 'credit_${c.id}',
        ),
      for (final p in payments)
        _TransactionItem(
          date: p.paymentDate,
          amount: p.amount,
          note: p.note,
          isCredit: false,
          id: 'payment_${p.id}',
        ),
    ];
    txns.sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) return;
    setState(() {
      _customer = customer;
      _currentDebt = debt;
      _totalPaid = paid;
      _lastPaymentDate = lastPay;
      _transactions = txns;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      if (_selectedDate == null) {
        _filteredTransactions = List.from(_transactions);
      } else {
        _filteredTransactions = _transactions.where((t) {
          return t.date.year == _selectedDate!.year &&
              t.date.month == _selectedDate!.month &&
              t.date.day == _selectedDate!.day;
        }).toList();
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _applyFilter();
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
    _applyFilter();
  }

  double get _effectiveLimit {
    final limit = _customer?.creditLimit;
    return limit ?? double.infinity;
  }

  Future<void> _showOperationDialog({required bool isCredit}) async {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    final effectiveLimit = _effectiveLimit;
    final hasLimit = effectiveLimit < double.infinity;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      margin: const EdgeInsets.only(bottom: 20)
                          .copyWith(
                        left: MediaQuery.of(context).size.width / 2 - 20,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (isCredit
                                    ? Colors.orange
                                    : Colors.green)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: isCredit ? Colors.orange : Colors.green,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isCredit
                              ? t.translate('new_debt')
                              : t.translate('new_payment'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textDirection: t.isRtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: t.translate('amount'),
                        hintText: t.translate('enter_amount'),
                        prefixText: '${t.translate('dzd')} ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t.translate('name_required');
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (!isCredit && parsed > _currentDebt) {
                          return _currentDebt > 0
                              ? '${t.translate('exceeds_debt')} (${_currentDebt.toStringAsFixed(2)} ${t.translate('dzd')})'
                              : t.translate('no_debt');
                        }
                        if (isCredit && hasLimit && _currentDebt + parsed > effectiveLimit) {
                          return '${t.translate('exceeds_limit')} (${effectiveLimit.toStringAsFixed(2)} ${t.translate('dzd')})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    if (isCredit)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          hasLimit
                              ? '${t.translate('available_credit')}: ${(effectiveLimit - _currentDebt).toStringAsFixed(2)} ${t.translate('dzd')}  ·  ${t.translate('limit')}: ${effectiveLimit.toStringAsFixed(2)} ${t.translate('dzd')}'
                              : '${t.translate('debt')}: ${_currentDebt.toStringAsFixed(0)} ${t.translate('dzd')}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
'${t.translate('debt')}: ${_currentDebt.toStringAsFixed(2)} ${t.translate('dzd')}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: noteCtrl,
                      textDirection: t.isRtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: t.translate('notes'),
                        hintText: t.translate('enter_note'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: isCredit
                          ? t.translate('add_debt')
                          : t.translate('add_payment'),
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSubmitting = true);

                              try {
                                final amount =
                                    double.parse(amountCtrl.text.trim());
                                final now = DateTime.now();
                                if (isCredit) {
                                  await _creditRepo.insert(CreditTransaction(
                                    id: now.microsecondsSinceEpoch.toString(),
                                    customerId: widget.customerId,
                                    amount: amount,
                                    transactionDate: now,
                                    note: noteCtrl.text.trim().isEmpty
                                        ? null
                                        : noteCtrl.text.trim(),
                                    createdAt: now,
                                  ));
                                } else {
                                  await _paymentRepo.insert(Payment(
                                    id: now.microsecondsSinceEpoch.toString(),
                                    customerId: widget.customerId,
                                    amount: amount,
                                    paymentDate: now,
                                    note: noteCtrl.text.trim().isEmpty
                                        ? null
                                        : noteCtrl.text.trim(),
                                    createdAt: now,
                                  ));
                                }

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx, true);
                              } catch (e) {
                                setSheetState(() => isSubmitting = false);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      showSuccessSnackBar(context, t.translate('operation_added'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: ''),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final customer = _customer!;
    final initial = customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?';
    final isOverdue = customer.nextDueDate != null &&
        customer.nextDueDate!.isBefore(DateTime.now()) &&
        _currentDebt > 0;

    return Scaffold(
      appBar: CustomAppBar(title: customer.name),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(theme, t, customer, initial, isOverdue)),
            SliverToBoxAdapter(child: _buildFinancialSummary(theme, t)),
            SliverToBoxAdapter(child: _buildActions(theme, t)),
            SliverToBoxAdapter(child: _buildDateFilter(theme, t)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t.translate('history'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedDate != null)
                      GestureDetector(
                        onTap: _clearDateFilter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 12,
                                  color: theme.colorScheme.onPrimaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                t.translate('clear_filter'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_filteredTransactions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                      const SizedBox(height: 12),
                      Text(
                        t.translate('no_history'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final txn = _filteredTransactions[index];
                    return _buildTransactionTile(theme, t, txn);
                  },
                  childCount: _filteredTransactions.length,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AppLocalizations t,
    Customer customer,
    String initial,
    bool isOverdue,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Text(
                          customer.phone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    if (customer.address != null && customer.address!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            customer.address!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildSmallChip(
                        theme,
                        isOverdue ? t.translate('overdue') : t.translate('active'),
                        isOverdue ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildSmallChip(
                        theme,
                        '${t.translate('customer_since')} ${customer.createdAt.year}',
                        theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallChip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(ThemeData theme, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniMetric(
              theme,
              label: t.translate('debt'),
              value: '${_currentDebt.toStringAsFixed(2)} ${t.translate('dzd')}',
              color: _currentDebt > 0
                  ? (() {
                      final overdue = _customer!.nextDueDate != null &&
                          _customer!.nextDueDate!.isBefore(DateTime.now());
                      return overdue ? Colors.red : Colors.orange;
                    })()
                  : Colors.green,
              icon: Icons.account_balance_wallet_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMiniMetric(
              theme,
              label: t.translate('total_paid'),
              value: '${_totalPaid.toStringAsFixed(2)} ${t.translate('dzd')}',
              color: Colors.green,
              icon: Icons.payments_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMiniMetric(
              theme,
              label: t.translate('last_payment'),
              value: _lastPaymentDate != null
                  ? '${_lastPaymentDate!.year}/${_lastPaymentDate!.month.toString().padLeft(2, '0')}/${_lastPaymentDate!.day.toString().padLeft(2, '0')}'
                  : '---',
              color: theme.colorScheme.primary,
              icon: Icons.history_rounded,
              smallValue: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool smallValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: (smallValue
                    ? theme.textTheme.labelLarge
                    : theme.textTheme.titleSmall)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: t.translate('new_debt'),
              icon: Icons.arrow_upward_rounded,
              onPressed: () => _showOperationDialog(isCredit: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              label: t.translate('new_payment'),
              icon: Icons.arrow_downward_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => _showOperationDialog(isCredit: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(ThemeData theme, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                        Icon(Icons.calendar_today_rounded,
                        size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}'
                          : t.translate('filter_date'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _selectedDate != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: _clearDateFilter,
                        child: Icon(Icons.close, size: 18,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(ThemeData theme, AppLocalizations t, _TransactionItem txn) {
    final isCredit = txn.isCredit;
    final color = isCredit ? Colors.orange : Colors.green;
    final icon = isCredit
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final label = isCredit
        ? t.translate('history_credit')
        : t.translate('history_payment');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${txn.amount.toStringAsFixed(2)} ${t.translate('dzd')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (txn.note != null && txn.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        txn.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${txn.date.day.toString().padLeft(2, '0')}/${txn.date.month.toString().padLeft(2, '0')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
