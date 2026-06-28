import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables/users_table.dart';
import 'tables/stores_table.dart';
import 'tables/settings_table.dart';
import 'tables/customers_table.dart';
import 'tables/credit_transactions_table.dart';
import 'tables/payments_table.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_template.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(UsersTable.create());
    await db.execute(StoresTable.create());
    await db.execute(SettingsTable.create());
    await db.execute(CustomersTable.create());
    await db.execute(CreditTransactionsTable.create());
    await db.execute(PaymentsTable.create());
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await db.execute(UsersTable.create());
      await db.execute(StoresTable.create());
      await db.execute(SettingsTable.create());
      await db.execute(CustomersTable.create());
      await db.execute(CreditTransactionsTable.create());
      await db.execute(PaymentsTable.create());
    }
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${SettingsTable.tableName} '
          'ADD COLUMN ${SettingsTable.loginEnabled} '
          'INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE ${SettingsTable.tableName} '
          'ADD COLUMN ${SettingsTable.username} TEXT');
      await db.execute('ALTER TABLE ${SettingsTable.tableName} '
          'ADD COLUMN ${SettingsTable.passwordHash} TEXT');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
