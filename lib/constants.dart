/// DeskClaw application constants
class AppConstants {
  AppConstants._();

  static const String appName = 'DeskClaw';
  static const String appVersion = 'v0.1.0';
  static const String appTagline = 'Works for you, grows with you';
  static const String welcomeTitle = 'Hello, how can I help you today?';
  static const String welcomeSubtitle =
      'I am a helpful assistant that can help you with your questions.';

  // Sidebar widths
  static const double sidebarWidth = 220.0;
  static const double chatListWidth = 260.0;

  // Input limits
  static const int maxInputLength = 10000;

  // Suggestion cards
  static const List<String> defaultSuggestions = ['你能做什么？', '帮我写一篇关于人工智能的文章。'];
}
