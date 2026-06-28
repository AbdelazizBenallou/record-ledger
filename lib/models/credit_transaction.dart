class CreditTransaction {
  final String id;
  final String customerId;
  final double amount;
  final DateTime transactionDate;
  final String? note;
  final DateTime createdAt;

  CreditTransaction({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.transactionDate,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'amount': amount,
        'transactionDate': transactionDate.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CreditTransaction.fromMap(Map<String, dynamic> map) =>
      CreditTransaction(
        id: map['id'] as String,
        customerId: map['customerId'] as String,
        amount: (map['amount'] as num).toDouble(),
        transactionDate: DateTime.parse(map['transactionDate'] as String),
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
