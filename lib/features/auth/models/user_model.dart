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
  bool get isSuperAdmin => roles.contains('super_admin');
  bool get isEventScoped => ownedEventId != null && ownedEventId!.isNotEmpty;

  /// Owner tools — contributions, team, the money side of the dashboard.
  /// An owner has them for their own event; a super admin for whichever
  /// event they picked.
  bool get canManageEvent => isEventOwner || isSuperAdmin;

  /// The Scan tab and manual "Check in guest".
  bool get canCheckIn => roles.contains('scanner') || isSuperAdmin;

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
