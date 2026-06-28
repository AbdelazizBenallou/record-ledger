class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String? imageUrl;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'imageUrl': imageUrl,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int?,
        firstName: map['firstName'] as String,
        lastName: map['lastName'] as String,
        imageUrl: map['imageUrl'] as String?,
      );

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? imageUrl,
  }) =>
      User(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}
