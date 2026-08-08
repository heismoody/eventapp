class ApiConfig {
  static const String baseUrlKey = 'api_base_url';
  static const String defaultBaseUrl = 'https://eventsys-kohl.vercel.app';
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
  static const String smsReminderPath = '/api/mobile/sms/reminder';
  static const String smsBroadcastPath = '/api/mobile/sms/broadcast';
  static const String smsBillingPath = '/api/mobile/sms/billing';
  static const String smsCreditsPath = '/api/mobile/sms/credits';
  static const String smsLogsPath = '/api/mobile/sms-logs';
  static const String smsPaymentsPath = '/api/mobile/sms/payments';
  static const String smsTemplatesPath = '/api/mobile/sms/templates';
  static String smsTemplatePath(String id) => '/api/mobile/sms/templates/$id';

  static const int smsPriceTzs = 100;
  static const int minSmsPurchaseTzs = 500;
}
