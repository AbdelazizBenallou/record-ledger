class Payment {
  final String id;
  final String customerId;
  final double amount;
  final DateTime paymentDate;
  final String? note;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paymentDate,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] as String,
        customerId: map['customerId'] as String,
        amount: (map['amount'] as num).toDouble(),
        paymentDate: DateTime.parse(map['paymentDate'] as String),
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
