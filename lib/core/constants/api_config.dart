class ApiConfig {
  static const String baseUrlKey = 'api_base_url';
  static const String defaultBaseUrl = 'http://localhost:3000';
  static const String activeEventIdKey = 'active_event_id';
  static const String activeEventNameKey = 'active_event_name';

  static const String authPath = '/api/mobile/auth';
  static const String eventsPath = '/api/mobile/events';
  static String eventKeyPath(String eventId) => '/api/mobile/events/$eventId/key';
  static const String checkInPath = '/api/mobile/check-in';
  static const String attendeesPath = '/api/mobile/attendees';
  static const String smsLogsPath = '/api/mobile/sms-logs';
}
