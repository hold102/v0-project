/*
 * user.dart — A user/member in the app
 * id is the primary key, avatar is an emoji string, email is optional,
 * currency is the user's preferred display currency (ISO 4217 code).
 */
class User {
  final String id;
  final String name;
  final String avatar;
  final String? email;
  final String currency;

  const User({
    required this.id,
    required this.name,
    required this.avatar,
    this.email,
    this.currency = 'MYR',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      email: json['email'] as String?,
      currency: (json['currency'] as String?) ?? 'MYR',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'email': email,
        'currency': currency,
      };

  User copyWith({String? name, String? avatar, String? email, String? currency}) {
    return User(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      currency: currency ?? this.currency,
    );
  }
}
