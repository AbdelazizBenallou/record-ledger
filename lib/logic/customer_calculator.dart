import '../db/repositories/credit_repository.dart';
import '../db/repositories/payment_repository.dart';
import '../models/store_settings.dart';

class CustomerCalculator {
  final CreditRepository _creditRepo = CreditRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();

  Future<double> currentDebt(String customerId) async {
    final totalCredit = await _creditRepo.getTotalByCustomerId(customerId);
    final totalPaid = await _paymentRepo.getTotalByCustomerId(customerId);
    return totalCredit - totalPaid;
  }

  Future<double> totalPurchased(String customerId) async {
    return await _creditRepo.getTotalByCustomerId(customerId);
  }

  Future<double> totalPaid(String customerId) async {
    return await _paymentRepo.getTotalByCustomerId(customerId);
  }

  Future<int> purchaseCount(String customerId) async {
    final credits = await _creditRepo.getByCustomerId(customerId);
    return credits.length;
  }

  Future<int> paymentCount(String customerId) async {
    final payments = await _paymentRepo.getByCustomerId(customerId);
    return payments.length;
  }

  double effectiveCreditLimit(
    double? customerCreditLimit,
    StoreSettings settings,
  ) {
    return customerCreditLimit ?? settings.defaultCreditLimit ?? 0;
  }

  bool canPurchase(double debt, double amount, StoreSettings settings) {
    if (!settings.allowCreditLimitExceeded) {
      final limit = effectiveCreditLimit(null, settings);
      if (debt + amount > limit) return false;
    }
    return true;
  }
}
