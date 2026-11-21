/// RESTful API Endpoint Strings (ASP.NET Core Backend + SignalR Hubs)
class ServerStrings {
  ServerStrings._();

  // API Versioning prefix
  static const String apiV1 = '/api/v1';

  // Authentication & Security Token Endpoints
  static const String login = '$apiV1/auth/login';
  static const String biometricLogin = '$apiV1/auth/biometric-login';
  static const String register = '$apiV1/auth/register';
  static const String logout = '$apiV1/auth/logout';
  static const String refreshToken = '$apiV1/auth/refresh-token';
  static const String changePassword = '$apiV1/auth/change-password';

  // User & Members Endpoints
  static const String profile = '$apiV1/members/me';
  static const String updateProfile = '$apiV1/members/me';
  static const String members = '$apiV1/members';
  static const String updateMemberRole = '$apiV1/members/role';

  // Chatting Room & Groups Endpoints
  static const String chatGroups = '$apiV1/chat/groups';
  static const String chatMessages = '$apiV1/chat/messages';
  static const String pinGroup = '$apiV1/chat/groups/pin';

  // Posts Feed (Timeline) Endpoints
  static const String posts = '$apiV1/posts';
  static const String postReactions = '$apiV1/posts/reactions';
  static const String postComments = '$apiV1/posts/comments';
  static const String pollVote = '$apiV1/posts/poll/vote';

  // Shared Files & Documents Endpoints
  static const String sharedFiles = '$apiV1/files';
  static const String uploadFile = '$apiV1/files/upload';
  static const String downloadFile = '$apiV1/files/download';

  // Calendar & Events Endpoints
  static const String calendarEvents = '$apiV1/calendar/events';
  static const String eventReminders = '$apiV1/calendar/reminders';

  // Notifications & Reminders Endpoints
  static const String notifications = '$apiV1/notifications';
  static const String markAllNotificationsRead = '$apiV1/notifications/read-all';

  // SignalR Real-Time Hubs
  static const String chatHub = '/hubs/chat';
  static const String notificationHub = '/hubs/notifications';
}
