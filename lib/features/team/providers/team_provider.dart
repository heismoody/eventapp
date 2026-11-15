import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../events/providers/event_provider.dart';
import '../models/team_member_model.dart';
import '../services/team_service.dart';

final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(ref.read(apiClientProvider));
});

final teamMembersProvider = FutureProvider<List<TeamMemberModel>>((ref) async {
  // Watched, so switching events reloads the team. The server ignores the
  // id for owners (always their own event); super admins need it.
  final eventId = ref.watch(activeEventIdProvider);
  return ref.read(teamServiceProvider).fetchMembers(eventId: eventId);
});
