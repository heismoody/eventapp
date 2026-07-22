import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../models/team_member_model.dart';
import '../services/team_service.dart';

final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(ref.read(apiClientProvider));
});

final teamMembersProvider = FutureProvider<List<TeamMemberModel>>((ref) async {
  return ref.read(teamServiceProvider).fetchMembers();
});
