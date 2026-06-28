class Store {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String currency;
  final DateTime createdAt;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.currency,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'currency': currency,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Store.fromMap(Map<String, dynamic> map) => Store(
        id: map['id'] as String,
        name: map['name'] as String,
        address: map['address'] as String,
        phone: map['phone'] as String,
        currency: map['currency'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
