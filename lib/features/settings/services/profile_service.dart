import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref);
});

class ProfileAccount {
  const ProfileAccount({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;

  factory ProfileAccount.fromJson(Map<String, dynamic> json) {
    return ProfileAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class ProfileService {
  ProfileService(this._ref);

  final Ref _ref;

  Future<ProfileAccount> fetchProfile() async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(ApiConfig.mePath);
    final data = response.data as Map<String, dynamic>;
    return ProfileAccount.fromJson(data['account'] as Map<String, dynamic>);
  }

  Future<ProfileAccount> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final body = <String, dynamic>{'name': name, 'email': email};
    if (phone != null) body['phone'] = phone;
    final response = await dio.patch(ApiConfig.mePath, data: body);
    final data = response.data as Map<String, dynamic>;
    return ProfileAccount.fromJson(data['account'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final dio = _ref.read(apiClientProvider);
    await dio.post(
      ApiConfig.mePasswordPath,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
