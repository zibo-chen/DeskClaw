import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'DeskClaw'**
  String get appTitle;

  /// App tagline shown below input bar
  ///
  /// In en, this message translates to:
  /// **'Works for you, grows with you'**
  String get appTagline;

  /// Chat section label in sidebar
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navSectionChat;

  /// Control section label in sidebar
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get navSectionControl;

  /// Agent section label in sidebar
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get navSectionAgent;

  /// Settings section label in sidebar
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSectionSettings;

  /// Chat nav item
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// Channels nav item
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get navChannels;

  /// Sessions nav item
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get navSessions;

  /// Cron Jobs nav item
  ///
  /// In en, this message translates to:
  /// **'Cron Jobs'**
  String get navCronJobs;

  /// Workspace nav item
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get navWorkspace;

  /// Skills nav item
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get navSkills;

  /// MCP nav item
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get navMcp;

  /// Configuration nav item
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get navConfiguration;

  /// Models nav item
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get navModels;

  /// Environments nav item
  ///
  /// In en, this message translates to:
  /// **'Environments'**
  String get navEnvironments;

  /// Chat list panel header
  ///
  /// In en, this message translates to:
  /// **'Work with DeskClaw'**
  String get workWithDeskClaw;

  /// New chat button label
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// Chat list empty state title
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// Chat list empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Start a new chat'**
  String get startNewChat;

  /// Welcome view title
  ///
  /// In en, this message translates to:
  /// **'Hello, how can I help you today?'**
  String get welcomeTitle;

  /// Welcome view subtitle
  ///
  /// In en, this message translates to:
  /// **'I am a helpful assistant that can help you with your questions.'**
  String get welcomeSubtitle;

  /// Suggestion card 1
  ///
  /// In en, this message translates to:
  /// **'What can you do?'**
  String get suggestionWhatCanYouDo;

  /// Suggestion card 2
  ///
  /// In en, this message translates to:
  /// **'Help me write an article about AI.'**
  String get suggestionWriteArticle;

  /// Thinking indicator
  ///
  /// In en, this message translates to:
  /// **'💭 Thinking...'**
  String get thinking;

  /// Error message with detail
  ///
  /// In en, this message translates to:
  /// **'⚠️ **Error:** {message}\n\nPlease check your API key and provider settings.'**
  String errorOccurred(String message);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'⚠️ **Error:** {message}\n\nPlease check your settings and try again.'**
  String errorGeneric(String message);

  /// Chat view top bar title
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// Input placeholder when processing
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// Collapse button tooltip
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Expand button tooltip
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// Channels page title
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get pageChannels;

  /// Configuration page title
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get pageConfiguration;

  /// Cron Jobs page title
  ///
  /// In en, this message translates to:
  /// **'Cron Jobs'**
  String get pageCronJobs;

  /// Models page title
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get pageModels;

  /// Sessions page title
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get pageSessions;

  /// Skills page title
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get pageSkills;

  /// Tools page title
  ///
  /// In en, this message translates to:
  /// **'Tools & MCP'**
  String get pageTools;

  /// Workspace page title
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get pageWorkspace;

  /// Language selector label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get switchToEnglish;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get switchToChinese;

  /// Copy tooltip
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get tooltipCopy;

  /// Refresh tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get tooltipRefresh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
