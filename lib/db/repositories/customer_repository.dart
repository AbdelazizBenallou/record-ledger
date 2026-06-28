import '../db_helper.dart';
import '../../models/customer.dart';

class CustomerRepository {
  Future<int> insert(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getDueToday(String storeId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final result = await db.query('customers',
        where:
            'storeId = ? AND status = ? AND nextDueDate >= ? AND nextDueDate < ?',
        whereArgs: [
          storeId,
          'active',
          todayStart.toIso8601String(),
          todayEnd.toIso8601String()
        ],
        orderBy: 'name ASC');
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  Future<List<Customer>> getOverdue(String storeId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final result = await db.query('customers',
        where: 'storeId = ? AND status = ? AND nextDueDate < ?',
        whereArgs: [storeId, 'active', todayStart.toIso8601String()],
        orderBy: 'nextDueDate ASC');
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  Future<Customer?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  Future<List<Customer>> getByStoreId(String storeId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('customers',
        where: 'storeId = ?', whereArgs: [storeId], orderBy: 'name ASC');
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  Future<List<Customer>> getActiveByStoreId(String storeId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('customers',
        where: 'storeId = ? AND status = ?',
        whereArgs: [storeId, 'active'],
        orderBy: 'name ASC');
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  Future<int> update(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update('customers', customer.toMap(),
        where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> archive(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update('customers', {'status': 'archived'},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
