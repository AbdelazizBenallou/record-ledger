enum CustomerStatus { active, archived }

class Customer {
  final String id;
  final String storeId;
  final String name;
  final String? phone;
  final String? address;
  final double? creditLimit;
  final DateTime? nextDueDate;
  final String? note;
  final CustomerStatus status;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.storeId,
    required this.name,
    this.phone,
    this.address,
    this.creditLimit,
    this.nextDueDate,
    this.note,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'storeId': storeId,
        'name': name,
        'phone': phone,
        'address': address,
        'creditLimit': creditLimit,
        'nextDueDate': nextDueDate?.toIso8601String(),
        'note': note,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as String,
        storeId: map['storeId'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        address: map['address'] as String?,
        creditLimit: (map['creditLimit'] as num?)?.toDouble(),
        nextDueDate: map['nextDueDate'] != null
            ? DateTime.parse(map['nextDueDate'] as String)
            : null,
        note: map['note'] as String?,
        status: CustomerStatus.values.byName(map['status'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
