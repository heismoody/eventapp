class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.ownedEventId,
  });

  final String id;
  final String name;
  final String email;
  final List<String> roles;
  final String? ownedEventId;

  bool get isEventOwner => roles.contains('event_owner');
  bool get isEventScoped => ownedEventId != null && ownedEventId!.isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e.toString()).toList(),
      ownedEventId: json['ownedEventId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roles': roles,
      'ownedEventId': ownedEventId,
    };
  }
}
