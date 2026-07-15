class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.qrToken,
    required this.eventId,
    required this.checkedInAt,
    required this.attempts,
    required this.synced,
  });

  final int id;
  final String qrToken;
  final String eventId;
  final DateTime checkedInAt;
  final int attempts;
  final bool synced;

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int,
      qrToken: map['qr_token'] as String,
      eventId: map['event_id'] as String,
      checkedInAt: DateTime.parse(map['checked_in_at'] as String),
      attempts: map['attempts'] as int,
      synced: (map['synced'] as int) == 1,
    );
  }
}
