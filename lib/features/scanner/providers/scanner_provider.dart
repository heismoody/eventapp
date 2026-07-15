import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/crypto/qr_decryptor.dart';
import '../../../local_db/checkin_history_dao.dart';
import '../../../local_db/queue_dao.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../events/providers/event_provider.dart';
import '../../events/services/event_service.dart';
import '../models/scan_result.dart';

final scannerProvider = Provider<ScannerController>((ref) {
  return ScannerController(ref);
});

class ScannerController {
  ScannerController(this._ref);

  final Ref _ref;
  final _historyDao = CheckinHistoryDao();
  final _queueDao = QueueDao();

  Future<ScanResult> processScan(String rawValue) async {
    final eventId = _ref.read(activeEventIdProvider);
    if (eventId == null) {
      return const ScanResult(type: ScanResultType.invalid);
    }

    final keyHex = await _ref.read(keyVaultProvider).get(eventId);
    if (keyHex == null || keyHex.isEmpty) {
      return const ScanResult(type: ScanResultType.invalid);
    }

    final guest = await QrDecryptor.decrypt(rawValue.trim(), keyHex);
    if (guest == null) {
      return const ScanResult(type: ScanResultType.invalid);
    }

    if (guest.eventId != eventId) {
      return const ScanResult(type: ScanResultType.invalid);
    }

    final existing = await _historyDao.getByQrToken(guest.qrToken, eventId);
    if (existing != null) {
      return ScanResult(
        type: ScanResultType.duplicate,
        guest: guest,
        checkedInAt: DateTime.parse(existing['checked_in_at'] as String),
      );
    }

    final checkedInAt = DateTime.now();
    await _historyDao.insert(
      qrToken: guest.qrToken,
      eventId: eventId,
      name: guest.name,
      phone: guest.phone,
      contribution: guest.contributionAmount,
      checkedInAt: checkedInAt,
    );

    final online = await _ref.read(connectivityServiceProvider).isOnline();
    if (online) {
      try {
        final dio = _ref.read(apiClientProvider);
        await dio.post(
          ApiConfig.checkInPath,
          data: {'qrToken': guest.qrToken, 'eventId': eventId},
        );
        await _historyDao.markSynced(guest.qrToken, eventId);
      } catch (_) {
        await _queueDao.enqueue(
          qrToken: guest.qrToken,
          eventId: eventId,
          checkedInAt: checkedInAt,
        );
      }
    } else {
      await _queueDao.enqueue(
        qrToken: guest.qrToken,
        eventId: eventId,
        checkedInAt: checkedInAt,
      );
    }

    return ScanResult(
      type: ScanResultType.success,
      guest: guest,
      checkedInAt: checkedInAt,
    );
  }
}

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  return QueueDao().pendingCount();
});

final checkinCountProvider = FutureProvider.family<int, String>((ref, eventId) async {
  return CheckinHistoryDao().countForEvent(eventId);
});

final recentCheckinsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, eventId) async {
  return CheckinHistoryDao().getAll(eventId: eventId);
});
