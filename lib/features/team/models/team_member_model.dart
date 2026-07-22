class TeamMemberModel {
  const TeamMemberModel({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String status;
  final DateTime createdAt;

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
