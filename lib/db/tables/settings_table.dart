import 'stores_table.dart';

class SettingsTable {
  static const tableName = 'store_settings';
  static const storeId = 'storeId';
  static const defaultCreditLimit = 'defaultCreditLimit';
  static const allowCreditLimitExceeded = 'allowCreditLimitExceeded';
  static const loginEnabled = 'loginEnabled';
  static const username = 'username';
  static const passwordHash = 'passwordHash';

  static String create() => '''
    CREATE TABLE $tableName (
      $storeId TEXT PRIMARY KEY,
      $defaultCreditLimit REAL,
      $allowCreditLimitExceeded INTEGER NOT NULL DEFAULT 0,
      $loginEnabled INTEGER NOT NULL DEFAULT 0,
      $username TEXT,
      $passwordHash TEXT,
      FOREIGN KEY ($storeId) REFERENCES ${StoresTable.tableName}(${StoresTable.id})
    )
  ''';
}
