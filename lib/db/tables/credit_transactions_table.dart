import 'customers_table.dart';

class CreditTransactionsTable {
  static const tableName = 'credit_transactions';
  static const id = 'id';
  static const customerId = 'customerId';
  static const amount = 'amount';
  static const transactionDate = 'transactionDate';
  static const note = 'note';
  static const createdAt = 'createdAt';

  static String create() => '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $customerId TEXT NOT NULL,
      $amount REAL NOT NULL,
      $transactionDate TEXT NOT NULL,
      $note TEXT,
      $createdAt TEXT NOT NULL,
      FOREIGN KEY ($customerId) REFERENCES ${CustomersTable.tableName}(${CustomersTable.id})
    )
  ''';
}
