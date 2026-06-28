import '../db/repositories/customer_repository.dart';
import '../db/repositories/credit_repository.dart';
import '../db/repositories/payment_repository.dart';
import '../preferences/test_preferences.dart';

class Operation {
  final String customerName;
  final double amount;
  final String? note;
  final DateTime date;
  final OperationType type;

  Operation({
    required this.customerName,
    required this.amount,
    this.note,
    required this.date,
    required this.type,
  });
}

enum OperationType { credit, payment }

class HomeCalculator {
  final CustomerRepository _customerRepo = CustomerRepository();
  final CreditRepository _creditRepo = CreditRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();

  Future<HomeMetrics> calculate(String storeId) async {
    final customers = await _customerRepo.getActiveByStoreId(storeId);
    final now = DateTime.now();
    final testMinutes = await TestPreferences.getTestMinutes();

    int customerCount = customers.length;
    int activeDebtCount = 0;
    int overdueCount = 0;
    double totalDebt = 0;
    double todayIncome = 0;

    for (final c in customers) {
      final totalCredit = await _creditRepo.getTotalByCustomerId(c.id);
      final totalPaid = await _paymentRepo.getTotalByCustomerId(c.id);
      final debt = totalCredit - totalPaid;

      if (debt > 0) {
        activeDebtCount++;
        totalDebt += debt;

        if (c.nextDueDate != null && c.nextDueDate!.isBefore(now)) {
          overdueCount++;
        }
      }
    }

    for (final c in customers) {
      final payments = await _paymentRepo.getByCustomerId(c.id);
      for (final p in payments) {
        if (_isInTimeWindow(p.paymentDate, now, testMinutes)) {
          todayIncome += p.amount;
        }
      }
    }

    return HomeMetrics(
      totalOutstandingDebt: totalDebt,
      customerCount: customerCount,
      overdueCustomerCount: overdueCount,
      todayIncome: todayIncome,
      activeDebtCount: activeDebtCount,
    );
  }

  Future<HomeMetrics> calculateFiltered(
    String storeId,
    PeriodFilter filter,
  ) async {
    final customers = await _customerRepo.getActiveByStoreId(storeId);
    final now = DateTime.now();

    DateTime periodStart;
    switch (filter) {
      case PeriodFilter.week:
        periodStart = now.subtract(const Duration(days: 7));
      case PeriodFilter.month:
        periodStart = DateTime(now.year, now.month, 1);
    }

    double totalDebt = 0;
    double periodIncome = 0;
    int activeDebtCount = 0;
    int overdueCount = 0;

    for (final c in customers) {
      final credits = await _creditRepo.getByCustomerId(c.id);
      final payments = await _paymentRepo.getByCustomerId(c.id);

      double paymentInPeriod = 0;

      for (final p in payments) {
        if (!p.paymentDate.isBefore(periodStart)) {
          paymentInPeriod += p.amount;
        }
      }

      final totalCredit = credits.fold<double>(0, (s, c) => s + c.amount);
      final totalPaid = payments.fold<double>(0, (s, p) => s + p.amount);
      final debt = totalCredit - totalPaid;

      if (debt > 0) {
        activeDebtCount++;
        totalDebt += debt;
        if (c.nextDueDate != null && c.nextDueDate!.isBefore(now)) {
          overdueCount++;
        }
      }

      periodIncome += paymentInPeriod;
    }

    return HomeMetrics(
      totalOutstandingDebt: totalDebt,
      customerCount: customers.length,
      overdueCustomerCount: overdueCount,
      todayIncome: periodIncome,
      activeDebtCount: activeDebtCount,
    );
  }

  Future<List<Operation>> todayOperations(String storeId) async {
    final customers = await _customerRepo.getActiveByStoreId(storeId);
    final now = DateTime.now();
    final testMinutes = await TestPreferences.getTestMinutes();
    final ops = <Operation>[];

    for (final c in customers) {
      final credits = await _creditRepo.getByCustomerId(c.id);
      for (final cr in credits) {
        if (_isInTimeWindow(cr.transactionDate, now, testMinutes)) {
          ops.add(Operation(
            customerName: c.name,
            amount: cr.amount,
            note: cr.note,
            date: cr.transactionDate,
            type: OperationType.credit,
          ));
        }
      }

      final payments = await _paymentRepo.getByCustomerId(c.id);
      for (final p in payments) {
        if (_isInTimeWindow(p.paymentDate, now, testMinutes)) {
          ops.add(Operation(
            customerName: c.name,
            amount: p.amount,
            note: p.note,
            date: p.paymentDate,
            type: OperationType.payment,
          ));
        }
      }
    }

    ops.sort((a, b) => b.date.compareTo(a.date));
    return ops;
  }

  bool _isInTimeWindow(DateTime date, DateTime now, int testMinutes) {
    if (testMinutes > 0) {
      return date.isAfter(now.subtract(Duration(minutes: testMinutes)));
    }
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

enum PeriodFilter { week, month }

class HomeMetrics {
  final double totalOutstandingDebt;
  final int customerCount;
  final int overdueCustomerCount;
  final double todayIncome;
  final int activeDebtCount;

  HomeMetrics({
    required this.totalOutstandingDebt,
    required this.customerCount,
    required this.overdueCustomerCount,
    required this.todayIncome,
    required this.activeDebtCount,
  });
}
