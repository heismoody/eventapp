class ScannedGuest {
  const ScannedGuest({
    required this.qrToken,
    required this.name,
    required this.phone,
    required this.eventId,
    this.contributionAmount,
  });

  final String qrToken;
  final String name;
  final String phone;
  final String eventId;
  final String? contributionAmount;
}
