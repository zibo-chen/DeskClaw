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
  String get suggestionExplainML => '用简单的语言解释机器学习的基本原理。';

  @override
  String get suggestionWriteEmail => '帮我写一封专业邮件。';

  @override
  String get suggestionImproveProductivity => '如何提高工作效率？';

  @override
  String get suggestionRecommendBooks => '推荐几本值得阅读的书。';

  @override
  String get suggestionPlanTrip => '帮我规划一次短途旅行。';

  @override
  String get suggestionBrainstorm => '帮我头脑风暴一些创意。';

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

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get toolCallSuccess => '成功';

  @override
  String get toolCallFailed => '失败';

  @override
  String get comingSoon => '即将推出';

  @override
  String get featureComingSoon => '此功能即将推出。';

  @override
  String get environmentsDescription => '管理环境变量和部署配置。';

  @override
  String get providerConfiguration => '供应商配置';

  @override
  String get providerLabel => '供应商';

  @override
  String get modelLabel => '模型';

  @override
  String get apiKeyLabel => 'API 密钥';

  @override
  String get apiKeyHint => '请输入您的 API 密钥…';

  @override
  String get apiBaseUrlLabel => 'API 基础 URL';

  @override
  String get temperatureLabel => '温度';

  @override
  String get saving => '保存中…';

  @override
  String get save => '保存';

  @override
  String get configSaved => '配置已保存！';

  @override
  String get configSaveFailed => '保存配置失败';

  @override
  String get runtimeStatus => '运行状态';

  @override
  String get initialized => '已初始化';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get configured => '已配置';

  @override
  String get missing => '缺失';

  @override
  String get activeProvider => '当前供应商';

  @override
  String get activeModel => '当前模型';

  @override
  String get modelNameHint => '输入模型名称或从列表中选择…';

  @override
  String get showSuggestions => '显示建议';

  @override
  String get workspaceInfo => '工作区信息';

  @override
  String get workspaceDirectory => '工作区目录';

  @override
  String get configFile => '配置文件';

  @override
  String get agentSettings => 'Agent 设置';

  @override
  String get maxToolIterations => '最大工具迭代次数';

  @override
  String get maxHistoryMessages => '最大历史消息数';

  @override
  String get parallelToolExecution => '并行工具执行';

  @override
  String get compactContext => '紧凑上下文';

  @override
  String get toolDispatcher => '工具调度器';

  @override
  String get memorySection => '记忆';

  @override
  String get backend => '后端';

  @override
  String get autoSave => '自动保存';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get hygiene => '数据清理';

  @override
  String get archiveAfter => '归档于…之后';

  @override
  String get days => '天';

  @override
  String get purgeAfter => '清除于…之后';

  @override
  String get embeddingProvider => '嵌入供应商';

  @override
  String get embeddingModel => '嵌入模型';

  @override
  String get costTracking => '费用追踪';

  @override
  String get dailyLimit => '每日限额';

  @override
  String get monthlyLimit => '每月限额';

  @override
  String get warnAt => '警告阈值';

  @override
  String get autonomySecurity => '自治与安全';

  @override
  String get autonomyLevel => '自治级别';

  @override
  String get readOnly => '只读';

  @override
  String get supervised => '受监督';

  @override
  String get fullAutonomy => '完全自治';

  @override
  String get workspaceOnly => '仅限工作区';

  @override
  String get requireApprovalMediumRisk => '需要审批（中等风险）';

  @override
  String get blockHighRisk => '阻止高风险操作';

  @override
  String get maxActionsPerHour => '每小时最大操作数';

  @override
  String get maxCostPerDay => '每日最大费用';

  @override
  String get allowedCommands => '允许的命令';

  @override
  String get autoApprovedTools => '自动审批的工具';

  @override
  String get toolsSection => '工具';

  @override
  String toolCountLabel(int count) {
    return '$count 个工具';
  }

  @override
  String get categoryCoreTools => '核心工具';

  @override
  String get categoryVersionControl => '版本控制';

  @override
  String get categoryWebNetwork => '网络 & Web';

  @override
  String get categoryMemory => '记忆';

  @override
  String get categorySystem => '系统';

  @override
  String get categoryFileProcessing => '文件处理';

  @override
  String get categoryAgent => 'Agent';

  @override
  String get categoryScheduling => '定时调度';

  @override
  String get approvalAuto => '自动';

  @override
  String get approvalAsk => '确认';

  @override
  String get deleteSessionTitle => '删除会话';

  @override
  String get deleteSessionConfirm => '确定删除此会话？此操作不可撤销。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get sessionDeleted => '已删除会话';

  @override
  String get renameSessionTitle => '重命名会话';

  @override
  String get sessionTitleLabel => '会话标题';

  @override
  String get confirm => '确认';

  @override
  String get sessionRenamed => '已重命名';

  @override
  String get clearAllSessionsTitle => '清空所有会话';

  @override
  String get clearAllSessionsConfirm => '确定删除所有已保存的会话？此操作不可撤销。';

  @override
  String get deleteAll => '全部删除';

  @override
  String get allSessionsCleared => '已清空所有会话';

  @override
  String get sessionCount => '会话';

  @override
  String get messageCount => '消息';

  @override
  String get refresh => '刷新';

  @override
  String get clearAllSessions => '清空所有会话';

  @override
  String get noSavedSessions => '暂无已保存的会话';

  @override
  String get sessionsAutoSaveHint => '在聊天中发送消息后，会话将自动保存到此处';

  @override
  String get searchSessions => '搜索会话…';

  @override
  String messageCountWithUnit(int count) {
    return '$count 条';
  }

  @override
  String get rename => '重命名';

  @override
  String get selectSessionToView => '选择一个会话查看详情';

  @override
  String messagesCreatedAt(int count) {
    return '$count 条消息 · 创建于';
  }

  @override
  String get roleYou => '你';

  @override
  String get roleAI => 'AI';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get featureToggles => '功能开关';

  @override
  String get featureTogglesDesc => '快速启用或停用 Agent 功能模块，选中即可直接使用';

  @override
  String get featureWebSearch => '网页搜索';

  @override
  String get featureWebSearchDesc => '搜索互联网获取最新信息';

  @override
  String get featureWebFetch => '网页抓取';

  @override
  String get featureWebFetchDesc => '抓取网页内容和提取文本';

  @override
  String get featureBrowser => '浏览器自动化';

  @override
  String get featureBrowserDesc => '自动化浏览器操作和交互';

  @override
  String get featureHttpRequest => 'HTTP 请求';

  @override
  String get featureHttpRequestDesc => '发送 API 请求 (GET/POST/PUT/DELETE)';

  @override
  String get featureMemory => '自动记忆';

  @override
  String get featureMemoryDesc => '自动保存对话中的重要信息';

  @override
  String get featureCostTracking => '费用追踪';

  @override
  String get featureCostTrackingDesc => '追踪 API 调用费用并设置限额';

  @override
  String get featureSkillsOpen => '社区技能';

  @override
  String get featureSkillsOpenDesc => '启用开源社区技能扩展';

  @override
  String get featureEnabled => '已启用';

  @override
  String get featureDisabled => '已停用';

  @override
  String get operationFailed => '操作失败';

  @override
  String get builtInTools => '内置工具';

  @override
  String get toolApprovalHint => '点击审批状态标签快速切换工具权限';

  @override
  String get autoApproval => '自动审批';

  @override
  String get requireConfirmation => '需要确认';

  @override
  String get defaultApproval => '默认';

  @override
  String get categoryCore => '核心工具';

  @override
  String get categoryVcs => '版本控制';

  @override
  String get categoryWeb => '网络 & Web';

  @override
  String get categoryMemoryTools => '记忆 & 存储';

  @override
  String get categoryCron => '定时任务';

  @override
  String get categoryFile => '文件处理';

  @override
  String get categoryAgentTools => 'Agent 委派';

  @override
  String channelConfigSaved(String name) {
    return '$name 配置已保存';
  }

  @override
  String saveFailedWithError(String error) {
    return '保存失败: $error';
  }

  @override
  String disableChannelTitle(String name) {
    return '禁用 $name';
  }

  @override
  String get disableChannelConfirm => '确定要禁用此频道？配置将被清除。';

  @override
  String get disable => '禁用';

  @override
  String channelDisabled(String name) {
    return '$name 已禁用';
  }

  @override
  String operationFailedWithError(String error) {
    return '操作失败: $error';
  }

  @override
  String activeCount(int count) {
    return '$count 个已激活';
  }

  @override
  String get noChannelsAvailable => '暂无可用频道';

  @override
  String get activeChannels => '已激活频道';

  @override
  String get availableChannels => '可用频道';

  @override
  String get statusActive => '已激活';

  @override
  String get statusInactive => '未激活';

  @override
  String configureChannel(String name) {
    return '配置 $name';
  }

  @override
  String disableChannel(String name) {
    return '禁用 $name';
  }

  @override
  String get skillsConfig => '技能配置';

  @override
  String get localSkills => '本地技能';

  @override
  String get communitySkills => '社区技能';

  @override
  String get openSourceSkills => '社区开源技能';

  @override
  String get openSourceSkillsDesc => '启用后将自动从 GitHub 同步社区技能';

  @override
  String get promptInjectionMode => '提示词注入模式';

  @override
  String get fullMode => '完整模式';

  @override
  String get fullModeDesc => '将技能的完整指令和工具信息注入系统提示词';

  @override
  String get compactMode => '精简模式';

  @override
  String get compactModeDesc => '仅注入技能摘要，按需加载详情';

  @override
  String get noSkillsAvailable => '暂无可用技能';

  @override
  String get noSkillsHint =>
      '在工作区的 skills/ 目录下创建 SKILL.toml 或 SKILL.md 文件来添加自定义技能，或启用社区开源技能来获取更多能力。';

  @override
  String get quickStartSkill => '快速开始：创建 SKILL.toml';

  @override
  String get sourceLocal => '本地';

  @override
  String get sourceCommunity => '社区';

  @override
  String get includedTools => '自带工具';

  @override
  String get prompts => '指令';

  @override
  String promptsWithCount(int count) {
    return '指令 ($count)';
  }

  @override
  String communitySkillsToggled(String status) {
    return '社区技能已$status';
  }

  @override
  String injectionModeUpdated(String mode) {
    return '注入模式已更新为 $mode';
  }

  @override
  String get installSkill => '安装技能';

  @override
  String get installSkillHint => '输入 Git URL 或本地路径';

  @override
  String get installSkillPlaceholder =>
      'https://github.com/user/skill-repo 或 /path/to/skill';

  @override
  String get installing => '安装中...';

  @override
  String skillInstalled(String name) {
    return '技能 \'$name\' 安装成功';
  }

  @override
  String installFailed(String error) {
    return '安装失败: $error';
  }

  @override
  String get removeSkill => '移除';

  @override
  String get removeSkillTitle => '移除技能';

  @override
  String removeSkillConfirm(String name) {
    return '确定移除技能 \'$name\'？此操作不可撤销。';
  }

  @override
  String skillRemoved(String name) {
    return '技能 \'$name\' 已移除';
  }

  @override
  String removeFailed(String error) {
    return '移除失败: $error';
  }

  @override
  String get gitUrlExample => '例如 https://github.com/user/my-skill';

  @override
  String get supportedSources => '支持 Git URL（https/ssh）或本地目录路径';

  @override
  String get deleteCronJobTitle => '删除定时任务';

  @override
  String get deleteCronJobConfirm => '确定删除此定时任务？此操作不可撤销。';

  @override
  String get deleted => '已删除';

  @override
  String deleteFailedWithError(String error) {
    return '删除失败: $error';
  }

  @override
  String get cronJobEnabled => '已启用';

  @override
  String get cronJobPaused => '已暂停';

  @override
  String get executionSuccess => '执行成功';

  @override
  String executionFailedWithError(String error) {
    return '执行失败: $error';
  }

  @override
  String executionErrorWithError(String error) {
    return '执行出错: $error';
  }

  @override
  String get totalCount => '总数';

  @override
  String get running => '运行中';

  @override
  String get paused => '已暂停';

  @override
  String get newTask => '新建任务';

  @override
  String get noCronJobs => '暂无定时任务';

  @override
  String get noCronJobsHint => '点击上方「新建任务」来创建 Shell 或 AI Agent 定时任务';

  @override
  String get mainSession => '主会话';

  @override
  String get runNow => '立即执行';

  @override
  String get collapseHistory => '收起历史';

  @override
  String get runHistory => '运行历史';

  @override
  String get nextExecution => '下次执行:';

  @override
  String get lastRun => '上次:';

  @override
  String get oneTime => '一次性';

  @override
  String get noRunHistory => '暂无运行记录';

  @override
  String runHistoryRecent(int count) {
    return '运行历史 (最近 $count 条)';
  }

  @override
  String get newCronJob => '新建定时任务';

  @override
  String get taskNameOptional => '任务名称（可选）';

  @override
  String get taskType => '任务类型';

  @override
  String get shellCommand => 'Shell 命令';

  @override
  String get aiAgent => 'AI Agent';

  @override
  String get scheduleType => '调度方式';

  @override
  String get interval => '间隔';

  @override
  String get scheduled => '定时';

  @override
  String get cronExpression => 'Cron 表达式';

  @override
  String get intervalMs => '间隔（毫秒）';

  @override
  String get executionTime => '执行时间 (RFC3339)';

  @override
  String get shellCommandLabel => 'Shell 命令';

  @override
  String get aiPromptLabel => 'AI 提示词';

  @override
  String get modelOptional => '模型（可选）';

  @override
  String get useDefaultModel => '留空使用默认模型';

  @override
  String get sessionTarget => '会话目标';

  @override
  String get isolated => '隔离';

  @override
  String get deleteAfterRun => '执行后删除';

  @override
  String get deleteAfterRunDesc => '仅执行一次后自动删除任务';

  @override
  String get create => '创建';

  @override
  String get cronJobCreated => '已创建定时任务';

  @override
  String createFailedWithError(String error) {
    return '创建失败: $error';
  }

  @override
  String get pageEnvironments => '环境';

  @override
  String get navKnowledge => '知识库';

  @override
  String get pageKnowledge => '知识库管理';

  @override
  String get knowledgeOverview => '知识库概览';

  @override
  String get totalEntries => '总条目';

  @override
  String get healthy => '健康';

  @override
  String get unhealthy => '异常';

  @override
  String get searchKnowledge => '搜索知识条目…';

  @override
  String get addKnowledge => '添加条目';

  @override
  String get knowledgeEntries => '知识条目';

  @override
  String get noKnowledgeEntries => '暂无知识条目';

  @override
  String get noKnowledgeHint => '添加知识条目可以帮助 AI 助手记住重要信息、事实和上下文。';

  @override
  String get knowledgeEntryAdded => '知识条目已添加';

  @override
  String get knowledgeEntryDeleted => '知识条目已删除';

  @override
  String get deleteKnowledgeTitle => '删除条目';

  @override
  String get deleteKnowledgeConfirm => '确定删除此知识条目？此操作不可撤销。';

  @override
  String get knowledgeKeyLabel => '键 / 标题';

  @override
  String get knowledgeKeyHint => '例如: user-preferences, project-guidelines';

  @override
  String get knowledgeContentLabel => '内容';

  @override
  String get knowledgeContentHint => '输入知识内容…';

  @override
  String get knowledgeCategoryLabel => '分类';

  @override
  String get knowledgeCategoryAll => '全部分类';

  @override
  String get knowledgeCategoryCore => '核心';

  @override
  String get knowledgeCategoryDaily => '日常';

  @override
  String get knowledgeCategoryConversation => '对话';

  @override
  String get copyMessage => '复制';

  @override
  String get editMessage => '编辑';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get expandHistory => '展开历史';

  @override
  String get saveEdit => '保存';

  @override
  String get cancelEdit => '取消';

  @override
  String get navAgents => '子代理';

  @override
  String get pageAgents => '子代理管理';

  @override
  String get agentOverview => '子代理概览';

  @override
  String get agentOverviewDesc =>
      '配置委派子代理，实现多代理协作。主代理可以将研究、编码、摘要等专项任务委派给这些子代理。';

  @override
  String get agentAgenticCount => '自主模式';

  @override
  String get agentNew => '新建子代理';

  @override
  String get agentEdit => '编辑子代理';

  @override
  String get agentNoAgents => '暂无子代理';

  @override
  String get agentNoAgentsHint => '创建子代理可将研究、编码或总结等专项任务委派给不同的 AI 模型执行。';

  @override
  String get agentNameLabel => '代理名称';

  @override
  String get agentSystemPrompt => '系统提示词';

  @override
  String get agentSystemPromptHint => '例如：你是一个研究助手。';

  @override
  String get agentMaxDepth => '最大深度';

  @override
  String get agentMaxIterations => '最大迭代次数';

  @override
  String get agentAgenticMode => '自主模式';

  @override
  String get agentAgenticModeDesc => '启用多轮工具调用循环，子代理可迭代使用工具完成复杂任务。';

  @override
  String get agentAllowedTools => '允许的工具';

  @override
  String get agentAgentic => '自主';

  @override
  String get agentOptional => '可选';

  @override
  String get agentDeleteTitle => '删除子代理';

  @override
  String agentDeleteConfirm(String name) {
    return '确定删除子代理 \'$name\'？此操作不可撤销。';
  }

  @override
  String agentDeleted(String name) {
    return '子代理 \'$name\' 已删除';
  }

  @override
  String agentCreated(String name) {
    return '子代理 \'$name\' 已创建';
  }

  @override
  String agentUpdated(String name) {
    return '子代理 \'$name\' 已更新';
  }
}
