import '../db_helper.dart';
import '../../models/credit_transaction.dart';

class CreditRepository {
  Future<int> insert(CreditTransaction credit) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('credit_transactions', credit.toMap());
  }

  Future<List<CreditTransaction>> getByCustomerId(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('credit_transactions',
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'transactionDate DESC');
    return result.map((e) => CreditTransaction.fromMap(e)).toList();
  }

  Future<double> getTotalByCustomerId(String customerId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total '
        'FROM credit_transactions WHERE customerId = ?',
        [customerId]);
    return (result.first['total'] as num).toDouble();
  }

  Future<int> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db
        .delete('credit_transactions', where: 'id = ?', whereArgs: [id]);
  }
}
