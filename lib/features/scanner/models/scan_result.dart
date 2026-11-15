import 'card_status.dart';

/// - ready: the card has places left — the sheet offers Admit.
/// - full: every place is used.
/// - invalid: not a card for this event.
enum ScanResultType { ready, full, invalid }

class ScanResult {
  const ScanResult({required this.type, this.card, this.method = 'scan'});

  final ScanResultType type;
  final CardStatus? card;

  /// 'scan' or 'manual' (checked in from the guest list).
  final String method;
}

/// - admitted: recorded on the server.
/// - queued: saved on this phone, sent when the network allows.
/// - refused: the server turned it away (card full, guest removed, …).
enum AdmitOutcome { admitted, queued, refused }

class AdmitResult {
  const AdmitResult({required this.outcome, required this.card, this.message});

  final AdmitOutcome outcome;
  final CardStatus card;
  final String? message;
}
