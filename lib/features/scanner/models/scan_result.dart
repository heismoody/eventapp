import 'scanned_guest.dart';

enum ScanResultType { success, duplicate, invalid }

class ScanResult {
  const ScanResult({
    required this.type,
    this.guest,
    this.checkedInAt,
  });

  final ScanResultType type;
  final ScannedGuest? guest;
  final DateTime? checkedInAt;
}
