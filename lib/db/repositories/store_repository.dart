import '../db_helper.dart';
import '../../models/store.dart';

class StoreRepository {
  Future<int> insert(Store store) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('stores', store.toMap());
  }

  Future<Store?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('stores', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Store.fromMap(result.first);
  }

  Future<List<Store>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('stores', orderBy: 'createdAt DESC');
    return result.map((e) => Store.fromMap(e)).toList();
  }

  Future<int> update(Store store) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update('stores', store.toMap(),
        where: 'id = ?', whereArgs: [store.id]);
  }

  Future<int> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('stores', where: 'id = ?', whereArgs: [id]);
  }
}
