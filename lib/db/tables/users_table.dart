class UsersTable {
  static const String tableName = 'users';
  static const String id = 'id';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String imageUrl = 'imageUrl';

  static String create() => '''
    CREATE TABLE $tableName (
      $id INTEGER PRIMARY KEY AUTOINCREMENT,
      $firstName TEXT NOT NULL,
      $lastName TEXT NOT NULL,
      $imageUrl TEXT
    )
  ''';
}
