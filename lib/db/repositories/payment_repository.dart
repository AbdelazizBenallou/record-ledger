import '../db_helper.dart';
import '../../models/payment.dart';

class PaymentRepository {
  Future<int> insert(Payment payment) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getByCustomerId(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('payments',
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'paymentDate DESC');
    return result.map((e) => Payment.fromMap(e)).toList();
  }

  Future<double> getTotalByCustomerId(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total '
        'FROM payments WHERE customerId = ?',
        [customerId]);
    return (result.first['total'] as num).toDouble();
  }

  Future<DateTime?> getLastPaymentDate(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('payments',
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'paymentDate DESC',
        limit: 1);
    if (result.isEmpty) return null;
    return Payment.fromMap(result.first).paymentDate;
  }

  Future<int> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }
}
