class User {
  final String id;
  final String name;
  final String avatar;
  final String? email;

  const User({
    required this.id,
    required this.name,
    required this.avatar,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'email': email,
      };
}
