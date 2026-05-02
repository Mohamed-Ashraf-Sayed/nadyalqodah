class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://judges.etqanly.com',
  );

  static const String apiPath = '/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Password reset
  static const String passwordRequest = '/password/request';
  static const String passwordVerify = '/password/verify';
  static const String passwordReset = '/password/reset';

  // Email verification
  static const String emailRequestCode = '/email/request';
  static const String emailConfirm = '/email/confirm';

  // Members
  static const String members = '/members';
  static const String myMember = '/members/me';
  static const String myPhoto = '/members/me/photo';
  static const String filters = '/members/filters';

  // Admin
  static const String adminPending = '/admin/pending';
  static const String adminUsers = '/admin/users';
  static const String adminBroadcast = '/admin/notifications/broadcast';

  // News
  static const String news = '/news';

  // Notifications
  static const String notifications = '/notifications';
  static const String devices = '/notifications/devices';

  // Contracts
  static const String contracts = '/contracts';

  // Events
  static const String events = '/events';

  // Suggestions
  static const String suggestions = '/suggestions';
  static const String mySuggestions = '/suggestions/me';

  // Admin
  static const String adminStats = '/admin/stats';

  // Export
  static String memberPdf(String id) => '/export/members/$id/pdf';
  static const String directoryPdf = '/export/members/pdf';
}
