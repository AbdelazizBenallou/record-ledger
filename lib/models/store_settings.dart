class StoreSettings {
  final String storeId;
  final double? defaultCreditLimit;
  final bool allowCreditLimitExceeded;
  final bool loginEnabled;
  final String? username;
  final String? passwordHash;

  StoreSettings({
    required this.storeId,
    this.defaultCreditLimit,
    required this.allowCreditLimitExceeded,
    required this.loginEnabled,
    this.username,
    this.passwordHash,
  });

  Map<String, dynamic> toMap() => {
        'storeId': storeId,
        'defaultCreditLimit': defaultCreditLimit,
        'allowCreditLimitExceeded': allowCreditLimitExceeded ? 1 : 0,
        'loginEnabled': loginEnabled ? 1 : 0,
        'username': username,
        'passwordHash': passwordHash,
      };

  factory StoreSettings.fromMap(Map<String, dynamic> map) => StoreSettings(
        storeId: map['storeId'] as String,
        defaultCreditLimit: (map['defaultCreditLimit'] as num?)?.toDouble(),
        allowCreditLimitExceeded: (map['allowCreditLimitExceeded'] as int) == 1,
        loginEnabled: (map['loginEnabled'] as int) == 1,
        username: map['username'] as String?,
        passwordHash: map['passwordHash'] as String?,
      );

  StoreSettings copyWith({
    String? storeId,
    double? defaultCreditLimit,
    bool? allowCreditLimitExceeded,
    bool? loginEnabled,
    String? username,
    String? passwordHash,
  }) =>
      StoreSettings(
        storeId: storeId ?? this.storeId,
        defaultCreditLimit: defaultCreditLimit ?? this.defaultCreditLimit,
        allowCreditLimitExceeded:
            allowCreditLimitExceeded ?? this.allowCreditLimitExceeded,
        loginEnabled: loginEnabled ?? this.loginEnabled,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
      );
}
