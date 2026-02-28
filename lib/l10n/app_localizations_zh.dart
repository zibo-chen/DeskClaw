// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DeskClaw';

  @override
  String get appTagline => '为你而工作，与你共成长';

  @override
  String get navSectionChat => '聊天';

  @override
  String get navSectionControl => '控制';

  @override
  String get navSectionAgent => '代理';

  @override
  String get navSectionSettings => '设置';

  @override
  String get navChat => '聊天';

  @override
  String get navChannels => '频道';

  @override
  String get navSessions => '会话';

  @override
  String get navCronJobs => '定时任务';

  @override
  String get navWorkspace => '工作区';

  @override
  String get navSkills => '技能';

  @override
  String get navMcp => 'MCP';

  @override
  String get navConfiguration => '配置';

  @override
  String get navModels => '模型';

  @override
  String get navEnvironments => '环境';

  @override
  String get workWithDeskClaw => '与 DeskClaw 一起工作';

  @override
  String get newChat => '新对话';

  @override
  String get noConversationsYet => '暂无对话';

  @override
  String get startNewChat => '开始新对话';

  @override
  String get welcomeTitle => '你好，今天我能帮你什么？';

  @override
  String get welcomeSubtitle => '我是一个智能助手，可以帮助你解答各种问题。';

  @override
  String get suggestionWhatCanYouDo => '你能做什么？';

  @override
  String get suggestionWriteArticle => '帮我写一篇关于人工智能的文章。';

  @override
  String get thinking => '💭 思考中...';

  @override
  String errorOccurred(String message) {
    return '⚠️ **错误：** $message\n\n请检查你的 API 密钥和供应商设置。';
  }

  @override
  String errorGeneric(String message) {
    return '⚠️ **错误：** $message\n\n请检查你的设置后重试。';
  }

  @override
  String get chatTitle => '聊天';

  @override
  String get processing => '处理中...';

  @override
  String get typeYourMessage => '输入消息…';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展开';

  @override
  String get pageChannels => '频道';

  @override
  String get pageConfiguration => '配置';

  @override
  String get pageCronJobs => '定时任务';

  @override
  String get pageModels => '模型';

  @override
  String get pageSessions => '会话';

  @override
  String get pageSkills => '技能';

  @override
  String get pageTools => '工具与 MCP';

  @override
  String get pageWorkspace => '工作区';

  @override
  String get languageLabel => '语言';

  @override
  String get switchToEnglish => 'English';

  @override
  String get switchToChinese => '中文';

  @override
  String get tooltipCopy => '复制';

  @override
  String get tooltipRefresh => '刷新';
}
