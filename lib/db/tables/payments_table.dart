import 'customers_table.dart';

class PaymentsTable {
  static const tableName = 'payments';
  static const id = 'id';
  static const customerId = 'customerId';
  static const amount = 'amount';
  static const paymentDate = 'paymentDate';
  static const note = 'note';
  static const createdAt = 'createdAt';

  static String create() => '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $customerId TEXT NOT NULL,
      $amount REAL NOT NULL,
      $paymentDate TEXT NOT NULL,
      $note TEXT,
      $createdAt TEXT NOT NULL,
      FOREIGN KEY ($customerId) REFERENCES ${CustomersTable.tableName}(${CustomersTable.id})
    )
  ''';
}
