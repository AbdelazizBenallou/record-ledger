import 'stores_table.dart';

class CustomersTable {
  static const tableName = 'customers';
  static const id = 'id';
  static const storeId = 'storeId';
  static const name = 'name';
  static const phone = 'phone';
  static const address = 'address';
  static const creditLimit = 'creditLimit';
  static const nextDueDate = 'nextDueDate';
  static const note = 'note';
  static const status = 'status';
  static const createdAt = 'createdAt';

  static String create() => '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $storeId TEXT NOT NULL,
      $name TEXT NOT NULL,
      $phone TEXT,
      $address TEXT,
      $creditLimit REAL,
      $nextDueDate TEXT,
      $note TEXT,
      $status TEXT NOT NULL DEFAULT 'active',
      $createdAt TEXT NOT NULL,
      FOREIGN KEY ($storeId) REFERENCES ${StoresTable.tableName}(${StoresTable.id})
    )
  ''';
}
