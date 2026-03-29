abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Accounts
  static const String accounts = '/accounts';
  static String account(String id) => '/accounts/$id';
  static String reconcileAccount(String id) => '/accounts/$id/reconcile';

  // Transactions
  static const String transactions = '/transactions';
  static String transaction(String id) => '/transactions/$id';
  static const String monthlyStats = '/transactions/stats/monthly';
  static const String categoryStats = '/transactions/stats/categories';

  // Budgets
  static const String budgets = '/budgets';
  static String budget(String id) => '/budgets/$id';
  static String budgetProgress(String id) => '/budgets/$id/progress';

  // Goals
  static const String goals = '/goals';
  static String goal(String id) => '/goals/$id';
  static String goalContributions(String id) => '/goals/$id/contributions';
  static String goalProjection(String id) => '/goals/$id/projection';

  // Categories
  static const String categories = '/categories';

  // Clarifications
  static const String clarifications = '/clarifications';
  static String respondClarification(String id) =>
      '/clarifications/$id/respond';
  static String dismissClarification(String id) =>
      '/clarifications/$id/dismiss';

  // Ingestion
  static const String parseSms = '/ingestion/sms/parse';
  static const String parseEmail = '/ingestion/email/parse';
  static const String voiceLog = '/ingestion/voice-log';
  static const String manualEntry = '/ingestion/manual-entry';

  // Insights
  static const String dashboardInsights = '/insights/dashboard';
  static const String weeklyInsights = '/insights/weekly';
  static const String monthlyInsights = '/insights/monthly';

  // Notifications
  static const String notifications = '/notifications';
  static String readNotification(String id) => '/notifications/$id/read';
  static const String readAllNotifications = '/notifications/read-all';
  static const String unreadCount = '/notifications/unread-count';

  // Assistant
  static const String assistantChat = '/assistant/chat';
  static const String voiceQuery = '/assistant/voice-query';
  static const String clarifyTransaction = '/assistant/clarify-transaction';
  static const String goalPlanning = '/assistant/goal-planning';
  static const String scenario = '/assistant/scenario';
  static const String fxSimulation = '/assistant/fx-simulation';

  // FX Rates
  static const String fxConvert = '/fx-rates/convert';
  static const String fxLatest = '/fx-rates/latest';

  // Users
  static const String userProfile = '/users/me';
  static const String userPreferences = '/users/me/preferences';
}
