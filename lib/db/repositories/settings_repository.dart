import '../db_helper.dart';
import '../../models/store_settings.dart';

class SettingsRepository {
  Future<int> insert(StoreSettings settings) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('store_settings', settings.toMap());
  }

  Future<StoreSettings?> getByStoreId(String storeId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('store_settings',
        where: 'storeId = ?', whereArgs: [storeId]);
    if (result.isEmpty) return null;
    return StoreSettings.fromMap(result.first);
  }

  Future<int> update(StoreSettings settings) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update('store_settings', settings.toMap(),
        where: 'storeId = ?', whereArgs: [settings.storeId]);
  }

  Future<int> delete(String storeId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('store_settings',
        where: 'storeId = ?', whereArgs: [storeId]);
  }
}
