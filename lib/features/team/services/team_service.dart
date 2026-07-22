import 'package:dio/dio.dart';

import '../../../core/constants/api_config.dart';
import '../models/team_member_model.dart';

class TeamService {
  TeamService(this._dio);

  final Dio _dio;

  Future<List<TeamMemberModel>> fetchMembers() async {
    final response = await _dio.get(ApiConfig.membersPath);
    final data = response.data as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>;

    return members
        .map((item) => TeamMemberModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TeamMemberModel> createMember({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConfig.membersPath,
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return TeamMemberModel.fromJson(data['member'] as Map<String, dynamic>);
  }
}
