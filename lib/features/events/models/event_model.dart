class EventModel {
  const EventModel({
    required this.id,
    required this.name,
    this.description,
    required this.date,
    this.venue,
    this.eventKey,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime date;
  final String? venue;
  final String? eventKey;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      venue: json['venue'] as String?,
      eventKey: json['eventKey'] as String?,
    );
  }
}
