import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';

class UserQueries {
  final Database db = DatabaseHelper.instance.database as Database;

  Future<int> insert(Map<String, dynamic> user) async {
    final database = await DatabaseHelper.instance.database;
    return await database.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final database = await DatabaseHelper.instance.database;
    return await database.query('users');
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final database = await DatabaseHelper.instance.database;
    final result = await database.query('users', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> update(int id, Map<String, dynamic> user) async {
    final database = await DatabaseHelper.instance.database;
    return await database.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final database = await DatabaseHelper.instance.database;
    return await database.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
