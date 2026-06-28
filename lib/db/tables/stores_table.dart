class StoresTable {
  static const tableName = 'stores';
  static const id = 'id';
  static const name = 'name';
  static const address = 'address';
  static const phone = 'phone';
  static const currency = 'currency';
  static const createdAt = 'createdAt';

  static String create() => '''
    CREATE TABLE $tableName (
      $id TEXT PRIMARY KEY,
      $name TEXT NOT NULL,
      $address TEXT NOT NULL,
      $phone TEXT NOT NULL,
      $currency TEXT NOT NULL,
      $createdAt TEXT NOT NULL
    )
  ''';
}
