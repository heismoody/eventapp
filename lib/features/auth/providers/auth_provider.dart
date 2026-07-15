import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

final authTokenProvider = StateProvider<String?>((ref) => null);

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

final authInitializedProvider = FutureProvider<bool>((ref) async {
  final token = await ref.read(authServiceProvider).getToken();
  ref.read(authTokenProvider.notifier).state = token;
  return token != null && token.isNotEmpty;
});
