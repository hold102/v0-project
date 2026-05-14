/*
 * balance.dart — Represents a settlement between two users
 * "from" owes "to" the specified "amount".
 * E.g., Balance(from: "u2", to: "u1", amount: 50) means Alex owes Me RM50.
 */
class Balance {
  final String from;     // User ID of the debtor (who owes money)
  final String to;       // User ID of the creditor (who is owed money)
  final double amount;   // How much they owe (in the app's currency)

  const Balance({
    required this.from,
    required this.to,
    required this.amount,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      from: json['from'] as String,
      to: json['to'] as String,
      amount: (json['amount'] as num).toDouble(),  // num → double (handles int or double from JSON)
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'amount': amount,
      };
}
