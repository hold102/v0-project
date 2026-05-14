class Balance {
  final String from;
  final String to;
  final double amount;

  const Balance({
    required this.from,
    required this.to,
    required this.amount,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      from: json['from'] as String,
      to: json['to'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'amount': amount,
      };
}
