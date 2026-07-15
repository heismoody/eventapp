class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  final String id;
  final String name;
  final String email;
  final List<String> roles;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }
}
