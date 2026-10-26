class ApiConfig {
  // Saved server override — only honoured in dev builds; see
  // AppEnvironment.baseUrl, which is how every caller should resolve it.
  static const String baseUrlKey = 'api_base_url';
  static const String activeEventIdKey = 'active_event_id';
  static const String activeEventNameKey = 'active_event_name';

  static const String authPath = '/api/mobile/auth';
  static const String eventsPath = '/api/mobile/events';
  static String eventKeyPath(String eventId) =>
      '/api/mobile/events/$eventId/key';
  static const String checkInPath = '/api/mobile/check-in';
  static const String attendeesPath = '/api/mobile/attendees';
  static const String attendeesImportPath = '/api/mobile/attendees/import';
  static String attendeePatchPath(String id) => '/api/mobile/attendees/$id';
  static const String membersPath = '/api/mobile/members';
  static const String contributionCategoriesPath =
      '/api/mobile/contribution-categories';
  static String contributionCategoryPath(String id) =>
      '/api/mobile/contribution-categories/$id';
  static const String contributionsPath = '/api/mobile/contributions';
  static const String mePath = '/api/mobile/me';
  static const String mePasswordPath = '/api/mobile/me/password';
  static String eventReportPath(String eventId) =>
      '/api/mobile/events/$eventId/report';
}
