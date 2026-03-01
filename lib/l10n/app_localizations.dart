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

  /// Suggestion card 3
  ///
  /// In en, this message translates to:
  /// **'Explain the basics of machine learning in simple terms.'**
  String get suggestionExplainML;

  /// Suggestion card 4
  ///
  /// In en, this message translates to:
  /// **'Help me write a professional email.'**
  String get suggestionWriteEmail;

  /// Suggestion card 5
  ///
  /// In en, this message translates to:
  /// **'How can I improve my productivity?'**
  String get suggestionImproveProductivity;

  /// Suggestion card 6
  ///
  /// In en, this message translates to:
  /// **'Recommend some books worth reading.'**
  String get suggestionRecommendBooks;

  /// Suggestion card 7
  ///
  /// In en, this message translates to:
  /// **'Help me plan a short trip.'**
  String get suggestionPlanTrip;

  /// Suggestion card 8
  ///
  /// In en, this message translates to:
  /// **'Brainstorm some creative ideas.'**
  String get suggestionBrainstorm;

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

  /// Dark mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Light mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Tool call success status
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get toolCallSuccess;

  /// Tool call failed status
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get toolCallFailed;

  /// Coming soon badge
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Feature coming soon description
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon.'**
  String get featureComingSoon;

  /// Environments page description
  ///
  /// In en, this message translates to:
  /// **'Manage environment variables and deployment profiles.'**
  String get environmentsDescription;

  /// Provider config section title
  ///
  /// In en, this message translates to:
  /// **'Provider Configuration'**
  String get providerConfiguration;

  /// Provider dropdown label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get providerLabel;

  /// Model dropdown label
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelLabel;

  /// API key field label
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// API key field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your API key...'**
  String get apiKeyHint;

  /// API base URL field label
  ///
  /// In en, this message translates to:
  /// **'API Base URL'**
  String get apiBaseUrlLabel;

  /// Temperature slider label
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// Save button label when saving
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Config saved success message
  ///
  /// In en, this message translates to:
  /// **'Configuration saved!'**
  String get configSaved;

  /// Config save failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to save config'**
  String get configSaveFailed;

  /// Runtime status section title
  ///
  /// In en, this message translates to:
  /// **'Runtime Status'**
  String get runtimeStatus;

  /// Initialized status label
  ///
  /// In en, this message translates to:
  /// **'Initialized'**
  String get initialized;

  /// Yes label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Configured status
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// Missing status
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// Active provider label
  ///
  /// In en, this message translates to:
  /// **'Active Provider'**
  String get activeProvider;

  /// Active model label
  ///
  /// In en, this message translates to:
  /// **'Active Model'**
  String get activeModel;

  /// Model name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter model name or select from list...'**
  String get modelNameHint;

  /// Show suggestions tooltip
  ///
  /// In en, this message translates to:
  /// **'Show suggestions'**
  String get showSuggestions;

  /// Workspace info section title
  ///
  /// In en, this message translates to:
  /// **'Workspace Info'**
  String get workspaceInfo;

  /// Workspace directory label
  ///
  /// In en, this message translates to:
  /// **'Workspace Directory'**
  String get workspaceDirectory;

  /// Config file label
  ///
  /// In en, this message translates to:
  /// **'Config File'**
  String get configFile;

  /// Agent settings section title
  ///
  /// In en, this message translates to:
  /// **'Agent Settings'**
  String get agentSettings;

  /// Max tool iterations label
  ///
  /// In en, this message translates to:
  /// **'Max Tool Iterations'**
  String get maxToolIterations;

  /// Max history messages label
  ///
  /// In en, this message translates to:
  /// **'Max History Messages'**
  String get maxHistoryMessages;

  /// Parallel tool execution label
  ///
  /// In en, this message translates to:
  /// **'Parallel Tool Execution'**
  String get parallelToolExecution;

  /// Compact context label
  ///
  /// In en, this message translates to:
  /// **'Compact Context'**
  String get compactContext;

  /// Tool dispatcher label
  ///
  /// In en, this message translates to:
  /// **'Tool Dispatcher'**
  String get toolDispatcher;

  /// Memory section title
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memorySection;

  /// Backend label
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get backend;

  /// Auto save label
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get autoSave;

  /// Enabled status
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// Disabled status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Hygiene label
  ///
  /// In en, this message translates to:
  /// **'Hygiene'**
  String get hygiene;

  /// Archive after label
  ///
  /// In en, this message translates to:
  /// **'Archive After'**
  String get archiveAfter;

  /// Days unit
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// Purge after label
  ///
  /// In en, this message translates to:
  /// **'Purge After'**
  String get purgeAfter;

  /// Embedding provider label
  ///
  /// In en, this message translates to:
  /// **'Embedding Provider'**
  String get embeddingProvider;

  /// Embedding model label
  ///
  /// In en, this message translates to:
  /// **'Embedding Model'**
  String get embeddingModel;

  /// Cost tracking section title
  ///
  /// In en, this message translates to:
  /// **'Cost Tracking'**
  String get costTracking;

  /// Daily limit label
  ///
  /// In en, this message translates to:
  /// **'Daily Limit'**
  String get dailyLimit;

  /// Monthly limit label
  ///
  /// In en, this message translates to:
  /// **'Monthly Limit'**
  String get monthlyLimit;

  /// Warn at label
  ///
  /// In en, this message translates to:
  /// **'Warn At'**
  String get warnAt;

  /// Autonomy & security section title
  ///
  /// In en, this message translates to:
  /// **'Autonomy & Security'**
  String get autonomySecurity;

  /// Autonomy level label
  ///
  /// In en, this message translates to:
  /// **'Autonomy Level'**
  String get autonomyLevel;

  /// Read only autonomy level
  ///
  /// In en, this message translates to:
  /// **'Read Only'**
  String get readOnly;

  /// Supervised autonomy level
  ///
  /// In en, this message translates to:
  /// **'Supervised'**
  String get supervised;

  /// Full autonomy level
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get fullAutonomy;

  /// Workspace only setting
  ///
  /// In en, this message translates to:
  /// **'Workspace Only'**
  String get workspaceOnly;

  /// Require approval for medium risk
  ///
  /// In en, this message translates to:
  /// **'Require Approval (Medium Risk)'**
  String get requireApprovalMediumRisk;

  /// Block high risk commands
  ///
  /// In en, this message translates to:
  /// **'Block High Risk'**
  String get blockHighRisk;

  /// Max actions per hour
  ///
  /// In en, this message translates to:
  /// **'Max Actions/Hour'**
  String get maxActionsPerHour;

  /// Max cost per day
  ///
  /// In en, this message translates to:
  /// **'Max Cost/Day'**
  String get maxCostPerDay;

  /// Allowed commands label
  ///
  /// In en, this message translates to:
  /// **'Allowed Commands'**
  String get allowedCommands;

  /// Auto-approved tools label
  ///
  /// In en, this message translates to:
  /// **'Auto-Approved Tools'**
  String get autoApprovedTools;

  /// Tools section title
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsSection;

  /// Tool count label
  ///
  /// In en, this message translates to:
  /// **'{count} tools'**
  String toolCountLabel(int count);

  /// Core tools category
  ///
  /// In en, this message translates to:
  /// **'Core Tools'**
  String get categoryCoreTools;

  /// Version control category
  ///
  /// In en, this message translates to:
  /// **'Version Control'**
  String get categoryVersionControl;

  /// Web & network category
  ///
  /// In en, this message translates to:
  /// **'Web & Network'**
  String get categoryWebNetwork;

  /// Memory category
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get categoryMemory;

  /// System category
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get categorySystem;

  /// File processing category
  ///
  /// In en, this message translates to:
  /// **'File Processing'**
  String get categoryFileProcessing;

  /// Agent category
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get categoryAgent;

  /// Scheduling category
  ///
  /// In en, this message translates to:
  /// **'Scheduling'**
  String get categoryScheduling;

  /// Auto approval label
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get approvalAuto;

  /// Ask approval label
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get approvalAsk;

  /// Delete session dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get deleteSessionTitle;

  /// Delete session confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this session? This action cannot be undone.'**
  String get deleteSessionConfirm;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Session deleted message
  ///
  /// In en, this message translates to:
  /// **'Session deleted'**
  String get sessionDeleted;

  /// Rename session dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename Session'**
  String get renameSessionTitle;

  /// Session title field label
  ///
  /// In en, this message translates to:
  /// **'Session Title'**
  String get sessionTitleLabel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Session renamed message
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get sessionRenamed;

  /// Clear all sessions dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear All Sessions'**
  String get clearAllSessionsTitle;

  /// Clear all sessions confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all saved sessions? This action cannot be undone.'**
  String get clearAllSessionsConfirm;

  /// Delete all button
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// All sessions cleared message
  ///
  /// In en, this message translates to:
  /// **'All sessions cleared'**
  String get allSessionsCleared;

  /// Session count label
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionCount;

  /// Message count label
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messageCount;

  /// Refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Clear all sessions button
  ///
  /// In en, this message translates to:
  /// **'Clear All Sessions'**
  String get clearAllSessions;

  /// No saved sessions empty state
  ///
  /// In en, this message translates to:
  /// **'No saved sessions'**
  String get noSavedSessions;

  /// Sessions auto save hint
  ///
  /// In en, this message translates to:
  /// **'Sessions will be automatically saved here after you send messages in chat'**
  String get sessionsAutoSaveHint;

  /// Search sessions placeholder
  ///
  /// In en, this message translates to:
  /// **'Search sessions...'**
  String get searchSessions;

  /// Message count with unit
  ///
  /// In en, this message translates to:
  /// **'{count} messages'**
  String messageCountWithUnit(int count);

  /// Rename button
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Select session hint
  ///
  /// In en, this message translates to:
  /// **'Select a session to view details'**
  String get selectSessionToView;

  /// Messages count and created at label
  ///
  /// In en, this message translates to:
  /// **'{count} messages · Created at'**
  String messagesCreatedAt(int count);

  /// You role label
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get roleYou;

  /// AI role label
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get roleAI;

  /// Just now time label
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// Minutes ago time label
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// Hours ago time label
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String hoursAgo(int count);

  /// Days ago time label
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// Feature toggles section title
  ///
  /// In en, this message translates to:
  /// **'Feature Toggles'**
  String get featureToggles;

  /// Feature toggles description
  ///
  /// In en, this message translates to:
  /// **'Quickly enable or disable Agent feature modules, select to use directly'**
  String get featureTogglesDesc;

  /// Web search feature name
  ///
  /// In en, this message translates to:
  /// **'Web Search'**
  String get featureWebSearch;

  /// Web search feature description
  ///
  /// In en, this message translates to:
  /// **'Search the internet for latest information'**
  String get featureWebSearchDesc;

  /// Web fetch feature name
  ///
  /// In en, this message translates to:
  /// **'Web Fetch'**
  String get featureWebFetch;

  /// Web fetch feature description
  ///
  /// In en, this message translates to:
  /// **'Fetch web page content and extract text'**
  String get featureWebFetchDesc;

  /// Browser automation feature name
  ///
  /// In en, this message translates to:
  /// **'Browser Automation'**
  String get featureBrowser;

  /// Browser automation feature description
  ///
  /// In en, this message translates to:
  /// **'Automate browser operations and interactions'**
  String get featureBrowserDesc;

  /// HTTP request feature name
  ///
  /// In en, this message translates to:
  /// **'HTTP Request'**
  String get featureHttpRequest;

  /// HTTP request feature description
  ///
  /// In en, this message translates to:
  /// **'Send API requests (GET/POST/PUT/DELETE)'**
  String get featureHttpRequestDesc;

  /// Auto memory feature name
  ///
  /// In en, this message translates to:
  /// **'Auto Memory'**
  String get featureMemory;

  /// Auto memory feature description
  ///
  /// In en, this message translates to:
  /// **'Automatically save important information from conversations'**
  String get featureMemoryDesc;

  /// Cost tracking feature name
  ///
  /// In en, this message translates to:
  /// **'Cost Tracking'**
  String get featureCostTracking;

  /// Cost tracking feature description
  ///
  /// In en, this message translates to:
  /// **'Track API call costs and set limits'**
  String get featureCostTrackingDesc;

  /// Community skills feature name
  ///
  /// In en, this message translates to:
  /// **'Community Skills'**
  String get featureSkillsOpen;

  /// Community skills feature description
  ///
  /// In en, this message translates to:
  /// **'Enable open-source community skill extensions'**
  String get featureSkillsOpenDesc;

  /// Feature enabled status
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get featureEnabled;

  /// Feature disabled status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get featureDisabled;

  /// Operation failed message
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// Built-in tools section title
  ///
  /// In en, this message translates to:
  /// **'Built-in Tools'**
  String get builtInTools;

  /// Tool approval hint
  ///
  /// In en, this message translates to:
  /// **'Click approval status label to quickly toggle tool permission'**
  String get toolApprovalHint;

  /// Auto approval label
  ///
  /// In en, this message translates to:
  /// **'Auto Approval'**
  String get autoApproval;

  /// Require confirmation label
  ///
  /// In en, this message translates to:
  /// **'Require Confirmation'**
  String get requireConfirmation;

  /// Default approval label
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultApproval;

  /// Core category
  ///
  /// In en, this message translates to:
  /// **'Core Tools'**
  String get categoryCore;

  /// VCS category
  ///
  /// In en, this message translates to:
  /// **'Version Control'**
  String get categoryVcs;

  /// Web category
  ///
  /// In en, this message translates to:
  /// **'Web & Network'**
  String get categoryWeb;

  /// Memory & Storage category
  ///
  /// In en, this message translates to:
  /// **'Memory & Storage'**
  String get categoryMemoryTools;

  /// Cron category
  ///
  /// In en, this message translates to:
  /// **'Scheduling'**
  String get categoryCron;

  /// File category
  ///
  /// In en, this message translates to:
  /// **'File Processing'**
  String get categoryFile;

  /// Agent delegation category
  ///
  /// In en, this message translates to:
  /// **'Agent Delegation'**
  String get categoryAgentTools;

  /// Channel config saved message
  ///
  /// In en, this message translates to:
  /// **'{name} configuration saved'**
  String channelConfigSaved(String name);

  /// Save failed message
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailedWithError(String error);

  /// Disable channel dialog title
  ///
  /// In en, this message translates to:
  /// **'Disable {name}'**
  String disableChannelTitle(String name);

  /// Disable channel confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disable this channel? Configuration will be cleared.'**
  String get disableChannelConfirm;

  /// Disable button
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// Channel disabled message
  ///
  /// In en, this message translates to:
  /// **'{name} disabled'**
  String channelDisabled(String name);

  /// Operation failed with error message
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailedWithError(String error);

  /// Active count label
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeCount(int count);

  /// No channels available message
  ///
  /// In en, this message translates to:
  /// **'No channels available'**
  String get noChannelsAvailable;

  /// Active channels section
  ///
  /// In en, this message translates to:
  /// **'Active Channels'**
  String get activeChannels;

  /// Available channels section
  ///
  /// In en, this message translates to:
  /// **'Available Channels'**
  String get availableChannels;

  /// Active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// Inactive status
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// Configure channel tooltip
  ///
  /// In en, this message translates to:
  /// **'Configure {name}'**
  String configureChannel(String name);

  /// Disable channel tooltip
  ///
  /// In en, this message translates to:
  /// **'Disable {name}'**
  String disableChannel(String name);

  /// Skills config section title
  ///
  /// In en, this message translates to:
  /// **'Skills Configuration'**
  String get skillsConfig;

  /// Local skills label
  ///
  /// In en, this message translates to:
  /// **'Local Skills'**
  String get localSkills;

  /// Community skills label
  ///
  /// In en, this message translates to:
  /// **'Community Skills'**
  String get communitySkills;

  /// Open source skills title
  ///
  /// In en, this message translates to:
  /// **'Community Open-Source Skills'**
  String get openSourceSkills;

  /// Open source skills description
  ///
  /// In en, this message translates to:
  /// **'Auto-sync community skills from GitHub when enabled'**
  String get openSourceSkillsDesc;

  /// Prompt injection mode label
  ///
  /// In en, this message translates to:
  /// **'Prompt Injection Mode'**
  String get promptInjectionMode;

  /// Full injection mode
  ///
  /// In en, this message translates to:
  /// **'Full Mode'**
  String get fullMode;

  /// Full mode description
  ///
  /// In en, this message translates to:
  /// **'Inject complete skill instructions and tool info into system prompt'**
  String get fullModeDesc;

  /// Compact injection mode
  ///
  /// In en, this message translates to:
  /// **'Compact Mode'**
  String get compactMode;

  /// Compact mode description
  ///
  /// In en, this message translates to:
  /// **'Inject skill summary only, load details on demand'**
  String get compactModeDesc;

  /// No skills available message
  ///
  /// In en, this message translates to:
  /// **'No skills available'**
  String get noSkillsAvailable;

  /// No skills hint
  ///
  /// In en, this message translates to:
  /// **'Create SKILL.toml or SKILL.md files in the workspace\'s skills/ directory to add custom skills, or enable community open-source skills for more capabilities.'**
  String get noSkillsHint;

  /// Quick start skill button
  ///
  /// In en, this message translates to:
  /// **'Quick Start: Create SKILL.toml'**
  String get quickStartSkill;

  /// Local source label
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get sourceLocal;

  /// Community source label
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get sourceCommunity;

  /// Included tools label
  ///
  /// In en, this message translates to:
  /// **'Included Tools'**
  String get includedTools;

  /// Prompts label
  ///
  /// In en, this message translates to:
  /// **'Prompts'**
  String get prompts;

  /// Prompts with count
  ///
  /// In en, this message translates to:
  /// **'Prompts ({count})'**
  String promptsWithCount(int count);

  /// Community skills toggled message
  ///
  /// In en, this message translates to:
  /// **'Community skills {status}'**
  String communitySkillsToggled(String status);

  /// Injection mode updated message
  ///
  /// In en, this message translates to:
  /// **'Injection mode updated to {mode}'**
  String injectionModeUpdated(String mode);

  /// Delete cron job dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Cron Job'**
  String get deleteCronJobTitle;

  /// Delete cron job confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this cron job? This action cannot be undone.'**
  String get deleteCronJobConfirm;

  /// Deleted message
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// Delete failed message
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailedWithError(String error);

  /// Cron job enabled message
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get cronJobEnabled;

  /// Cron job paused message
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get cronJobPaused;

  /// Execution success message
  ///
  /// In en, this message translates to:
  /// **'Execution succeeded'**
  String get executionSuccess;

  /// Execution failed message
  ///
  /// In en, this message translates to:
  /// **'Execution failed: {error}'**
  String executionFailedWithError(String error);

  /// Execution error message
  ///
  /// In en, this message translates to:
  /// **'Execution error: {error}'**
  String executionErrorWithError(String error);

  /// Total count label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalCount;

  /// Running status
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// Paused status
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// New task button
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No cron jobs message
  ///
  /// In en, this message translates to:
  /// **'No cron jobs'**
  String get noCronJobs;

  /// No cron jobs hint
  ///
  /// In en, this message translates to:
  /// **'Click \"New Task\" above to create Shell or AI Agent scheduled tasks'**
  String get noCronJobsHint;

  /// Main session label
  ///
  /// In en, this message translates to:
  /// **'Main Session'**
  String get mainSession;

  /// Run now button
  ///
  /// In en, this message translates to:
  /// **'Run Now'**
  String get runNow;

  /// Collapse history button
  ///
  /// In en, this message translates to:
  /// **'Collapse History'**
  String get collapseHistory;

  /// Run history button
  ///
  /// In en, this message translates to:
  /// **'Run History'**
  String get runHistory;

  /// Next execution label
  ///
  /// In en, this message translates to:
  /// **'Next execution:'**
  String get nextExecution;

  /// Last run label
  ///
  /// In en, this message translates to:
  /// **'Last:'**
  String get lastRun;

  /// One-time schedule label
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get oneTime;

  /// No run history message
  ///
  /// In en, this message translates to:
  /// **'No run history'**
  String get noRunHistory;

  /// Run history recent count
  ///
  /// In en, this message translates to:
  /// **'Run History (recent {count})'**
  String runHistoryRecent(int count);

  /// New cron job dialog title
  ///
  /// In en, this message translates to:
  /// **'New Cron Job'**
  String get newCronJob;

  /// Task name field label
  ///
  /// In en, this message translates to:
  /// **'Task Name (optional)'**
  String get taskNameOptional;

  /// Task type label
  ///
  /// In en, this message translates to:
  /// **'Task Type'**
  String get taskType;

  /// Shell command option
  ///
  /// In en, this message translates to:
  /// **'Shell Command'**
  String get shellCommand;

  /// AI Agent option
  ///
  /// In en, this message translates to:
  /// **'AI Agent'**
  String get aiAgent;

  /// Schedule type label
  ///
  /// In en, this message translates to:
  /// **'Schedule Type'**
  String get scheduleType;

  /// Interval option
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// Scheduled option
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// Cron expression label
  ///
  /// In en, this message translates to:
  /// **'Cron Expression'**
  String get cronExpression;

  /// Interval in milliseconds label
  ///
  /// In en, this message translates to:
  /// **'Interval (milliseconds)'**
  String get intervalMs;

  /// Execution time label
  ///
  /// In en, this message translates to:
  /// **'Execution Time (RFC3339)'**
  String get executionTime;

  /// Shell command input label
  ///
  /// In en, this message translates to:
  /// **'Shell Command'**
  String get shellCommandLabel;

  /// AI prompt input label
  ///
  /// In en, this message translates to:
  /// **'AI Prompt'**
  String get aiPromptLabel;

  /// Model optional field label
  ///
  /// In en, this message translates to:
  /// **'Model (optional)'**
  String get modelOptional;

  /// Use default model hint
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use default model'**
  String get useDefaultModel;

  /// Session target label
  ///
  /// In en, this message translates to:
  /// **'Session Target'**
  String get sessionTarget;

  /// Isolated session option
  ///
  /// In en, this message translates to:
  /// **'Isolated'**
  String get isolated;

  /// Delete after run option
  ///
  /// In en, this message translates to:
  /// **'Delete After Run'**
  String get deleteAfterRun;

  /// Delete after run description
  ///
  /// In en, this message translates to:
  /// **'Automatically delete task after one execution'**
  String get deleteAfterRunDesc;

  /// Create button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Cron job created message
  ///
  /// In en, this message translates to:
  /// **'Cron job created'**
  String get cronJobCreated;

  /// Create failed message
  ///
  /// In en, this message translates to:
  /// **'Create failed: {error}'**
  String createFailedWithError(String error);

  /// Environments page title
  ///
  /// In en, this message translates to:
  /// **'Environments'**
  String get pageEnvironments;

  /// Knowledge base nav item
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get navKnowledge;

  /// Knowledge base page title
  ///
  /// In en, this message translates to:
  /// **'Knowledge Base'**
  String get pageKnowledge;

  /// Knowledge stats section title
  ///
  /// In en, this message translates to:
  /// **'Knowledge Base Overview'**
  String get knowledgeOverview;

  /// Total entries stat label
  ///
  /// In en, this message translates to:
  /// **'Total Entries'**
  String get totalEntries;

  /// Health status healthy
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// Health status unhealthy
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get unhealthy;

  /// Search knowledge placeholder
  ///
  /// In en, this message translates to:
  /// **'Search knowledge entries...'**
  String get searchKnowledge;

  /// Add knowledge button
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addKnowledge;

  /// Knowledge entries list title
  ///
  /// In en, this message translates to:
  /// **'Knowledge Entries'**
  String get knowledgeEntries;

  /// Empty knowledge list title
  ///
  /// In en, this message translates to:
  /// **'No knowledge entries yet'**
  String get noKnowledgeEntries;

  /// Empty knowledge list hint
  ///
  /// In en, this message translates to:
  /// **'Add knowledge entries to help your AI assistant remember important information, facts, and context.'**
  String get noKnowledgeHint;

  /// Knowledge entry added message
  ///
  /// In en, this message translates to:
  /// **'Knowledge entry added'**
  String get knowledgeEntryAdded;

  /// Knowledge entry deleted message
  ///
  /// In en, this message translates to:
  /// **'Knowledge entry deleted'**
  String get knowledgeEntryDeleted;

  /// Delete knowledge dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteKnowledgeTitle;

  /// Delete knowledge confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this knowledge entry? This cannot be undone.'**
  String get deleteKnowledgeConfirm;

  /// Knowledge key input label
  ///
  /// In en, this message translates to:
  /// **'Key / Title'**
  String get knowledgeKeyLabel;

  /// Knowledge key input hint
  ///
  /// In en, this message translates to:
  /// **'e.g. user-preferences, project-guidelines'**
  String get knowledgeKeyHint;

  /// Knowledge content input label
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get knowledgeContentLabel;

  /// Knowledge content input hint
  ///
  /// In en, this message translates to:
  /// **'Enter the knowledge content...'**
  String get knowledgeContentHint;

  /// Knowledge category input label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get knowledgeCategoryLabel;

  /// All categories filter
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get knowledgeCategoryAll;

  /// Core category
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get knowledgeCategoryCore;

  /// Daily category
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get knowledgeCategoryDaily;

  /// Conversation category
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get knowledgeCategoryConversation;
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
