// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DeskClaw';

  @override
  String get appTagline => 'Works for you, grows with you';

  @override
  String get navSectionChat => 'Chat';

  @override
  String get navSectionControl => 'Control';

  @override
  String get navSectionAgent => 'Agent';

  @override
  String get navSectionSettings => 'Settings';

  @override
  String get navChat => 'Chat';

  @override
  String get navChannels => 'Channels';

  @override
  String get navSessions => 'Sessions';

  @override
  String get navCronJobs => 'Cron Jobs';

  @override
  String get navWorkspace => 'Workspace';

  @override
  String get navSkills => 'Skills';

  @override
  String get navMcp => 'MCP';

  @override
  String get navConfiguration => 'Configuration';

  @override
  String get navModels => 'Models';

  @override
  String get navEnvironments => 'Environments';

  @override
  String get workWithDeskClaw => 'Work with DeskClaw';

  @override
  String get newChat => 'New Chat';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get startNewChat => 'Start a new chat';

  @override
  String get welcomeTitle => 'Hello, how can I help you today?';

  @override
  String get welcomeSubtitle =>
      'I am a helpful assistant that can help you with your questions.';

  @override
  String get suggestionWhatCanYouDo => 'What can you do?';

  @override
  String get suggestionWriteArticle => 'Help me write an article about AI.';

  @override
  String get thinking => '💭 Thinking...';

  @override
  String errorOccurred(String message) {
    return '⚠️ **Error:** $message\n\nPlease check your API key and provider settings.';
  }

  @override
  String errorGeneric(String message) {
    return '⚠️ **Error:** $message\n\nPlease check your settings and try again.';
  }

  @override
  String get chatTitle => 'Chat';

  @override
  String get processing => 'Processing...';

  @override
  String get typeYourMessage => 'Type your message...';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get pageChannels => 'Channels';

  @override
  String get pageConfiguration => 'Configuration';

  @override
  String get pageCronJobs => 'Cron Jobs';

  @override
  String get pageModels => 'Models';

  @override
  String get pageSessions => 'Sessions';

  @override
  String get pageSkills => 'Skills';

  @override
  String get pageTools => 'Tools & MCP';

  @override
  String get pageWorkspace => 'Workspace';

  @override
  String get languageLabel => 'Language';

  @override
  String get switchToEnglish => 'English';

  @override
  String get switchToChinese => '中文';

  @override
  String get tooltipCopy => 'Copy';

  @override
  String get tooltipRefresh => 'Refresh';
}
