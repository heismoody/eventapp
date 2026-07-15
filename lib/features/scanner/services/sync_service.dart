import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../../../local_db/checkin_history_dao.dart';
import '../../../local_db/queue_dao.dart';
import '../../../shared/services/connectivity_service.dart';
import '../models/sync_queue_item.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

class SyncService {
  SyncService(this._ref);

  final Ref _ref;
  final _queueDao = QueueDao();
  final _historyDao = CheckinHistoryDao();

  Future<int> drainQueue() async {
    final online = await _ref.read(connectivityServiceProvider).isOnline();
    if (!online) return 0;

    final pending = await _queueDao.getPending();
    var synced = 0;

    for (final item in pending) {
      final queueItem = SyncQueueItem.fromMap(item);
      try {
        final dio = _ref.read(apiClientProvider);
        await dio.post(
          ApiConfig.checkInPath,
          data: {
            'qrToken': queueItem.qrToken,
            'eventId': queueItem.eventId,
          },
        );

        await _queueDao.markSynced(queueItem.id);
        await _historyDao.markSynced(queueItem.qrToken, queueItem.eventId);
        synced++;
      } catch (_) {
        await _queueDao.incrementAttempts(queueItem.id);
      }
    }

    return synced;
  }
}
