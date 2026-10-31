class ScannedGuest {
  const ScannedGuest({
    required this.qrToken,
    required this.name,
    required this.phone,
    required this.eventId,
    this.contributionAmount,
    this.categoryName,
  });

  final String qrToken;
  final String name;
  final String phone;
  final String eventId;
  final String? contributionAmount;
  final String? categoryName;

  ScannedGuest withCategory(String? categoryName) => ScannedGuest(
    qrToken: qrToken,
    name: name,
    phone: phone,
    eventId: eventId,
    contributionAmount: contributionAmount,
    categoryName: categoryName,
  );
}
