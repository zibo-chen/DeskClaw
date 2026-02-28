import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/cron_api.dart' as cron_api;

/// Cron Jobs management page - list, add, edit, delete scheduled tasks
class CronJobsPage extends ConsumerStatefulWidget {
  const CronJobsPage({super.key});

  @override
  ConsumerState<CronJobsPage> createState() => _CronJobsPageState();
}

class _CronJobsPageState extends ConsumerState<CronJobsPage> {
  cron_api.CronConfigDto? _config;
  List<cron_api.CronJobDto> _jobs = [];
  bool _loading = true;
  String? _message;
  String? _expandedJobId; // For viewing run history
  List<cron_api.CronRunDto> _runs = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final config = await cron_api.getCronConfig();
    final jobs = await cron_api.listCronJobs();
    if (mounted) {
      setState(() {
        _config = config;
        _jobs = jobs;
        _loading = false;
      });
    }
  }

  Future<void> _loadRuns(String jobId) async {
    if (_expandedJobId == jobId) {
      setState(() {
        _expandedJobId = null;
        _runs = [];
      });
      return;
    }
    final runs = await cron_api.listCronRuns(jobId: jobId, limit: 20);
    setState(() {
      _expandedJobId = jobId;
      _runs = runs;
    });
  }

  Future<void> _deleteJob(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除定时任务'),
        content: const Text('确定删除此定时任务？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await cron_api.removeCronJob(jobId: jobId);
      if (result == 'ok') {
        _showMessage('已删除');
        _loadAll();
      } else {
        _showMessage('删除失败: $result');
      }
    }
  }

  Future<void> _toggleJob(String jobId, bool enabled) async {
    final result = enabled
        ? await cron_api.resumeCronJob(jobId: jobId)
        : await cron_api.pauseCronJob(jobId: jobId);
    if (result == 'ok') {
      _showMessage(enabled ? '已启用' : '已暂停');
      _loadAll();
    } else {
      _showMessage('操作失败: $result');
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<_NewJobData>(
      context: context,
      builder: (ctx) => const _AddJobDialog(),
    );
    if (result == null) return;

    String apiResult;
    if (result.jobType == 'shell') {
      apiResult = await cron_api.addShellCronJob(
        name: result.name.isNotEmpty ? result.name : null,
        scheduleType: result.scheduleType,
        expression: result.expression,
        command: result.command,
      );
    } else {
      apiResult = await cron_api.addAgentCronJob(
        name: result.name.isNotEmpty ? result.name : null,
        scheduleType: result.scheduleType,
        expression: result.expression,
        prompt: result.prompt,
        sessionTarget: result.sessionTarget,
        model: result.model.isNotEmpty ? result.model : null,
        deleteAfterRun: result.deleteAfterRun,
      );
    }

    if (!apiResult.startsWith('error')) {
      _showMessage('已创建定时任务');
      _loadAll();
    } else {
      _showMessage('创建失败: $apiResult');
    }
  }

  void _showMessage(String msg) {
    setState(() => _message = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.chatListBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.pageCronJobs,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          if (_config != null) ...[
            _statBadge('${_config!.totalJobs}', '总数'),
            const SizedBox(width: 8),
            _statBadge(
              '${_config!.activeJobs}',
              '运行中',
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            if (_config!.pausedJobs > 0)
              _statBadge(
                '${_config!.pausedJobs}',
                '已暂停',
                color: AppColors.warning,
              ),
          ],
          const Spacer(),
          if (_message != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _message!,
                style: const TextStyle(color: AppColors.success, fontSize: 13),
              ),
            ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: '刷新',
            onPressed: _loadAll,
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新建任务'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, {Color? color}) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildContent() {
    if (_jobs.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _jobs.length,
      itemBuilder: (ctx, i) => _buildJobCard(_jobs[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无定时任务',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击上方「新建任务」来创建 Shell 或 AI Agent 定时任务',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('新建任务'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(cron_api.CronJobDto job) {
    final isAgent = job.jobType == 'agent';
    final isExpanded = _expandedJobId == job.id;
    final nextRun = DateTime.fromMillisecondsSinceEpoch(job.nextRun * 1000);
    final nextRunStr = _formatDateTime(nextRun);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Job header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    // Type icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isAgent
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isAgent ? Icons.smart_toy : Icons.terminal,
                        size: 20,
                        color: isAgent ? AppColors.primary : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.name.isNotEmpty ? job.name : job.id,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _chipLabel(
                                isAgent ? 'Agent' : 'Shell',
                                color: isAgent
                                    ? AppColors.primary
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 6),
                              _chipLabel(
                                job.scheduleDisplay,
                                color: AppColors.textSecondary,
                              ),
                              if (isAgent && job.sessionTarget == 'main') ...[
                                const SizedBox(width: 6),
                                _chipLabel('主会话', color: AppColors.success),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status + actions
                    Switch(
                      value: job.enabled,
                      activeTrackColor: AppColors.success,
                      onChanged: (v) => _toggleJob(job.id, v),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      onSelected: (action) {
                        if (action == 'history') _loadRuns(job.id);
                        if (action == 'delete') _deleteJob(job.id);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'history',
                          child: Row(
                            children: [
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(isExpanded ? '收起历史' : '运行历史'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '删除',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Command/prompt
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mainBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.chatListBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    isAgent ? job.prompt : job.command,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFamily: isAgent ? null : 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Info row
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '下次执行: $nextRunStr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    if (job.lastStatus.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(
                        job.lastStatus == 'ok'
                            ? Icons.check_circle
                            : Icons.error,
                        size: 14,
                        color: job.lastStatus == 'ok'
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '上次: ${job.lastStatus}',
                        style: TextStyle(
                          fontSize: 12,
                          color: job.lastStatus == 'ok'
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                    if (isAgent && job.model.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.memory, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        job.model,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                    if (job.deleteAfterRun) ...[
                      const SizedBox(width: 16),
                      _chipLabel('一次性', color: AppColors.warning),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Run history (expandable)
          if (isExpanded) _buildRunHistory(),
        ],
      ),
    );
  }

  Widget _chipLabel(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRunHistory() {
    if (_runs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.chatListBorder, width: 1),
          ),
        ),
        child: const Center(
          child: Text(
            '暂无运行记录',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.chatListBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '运行历史 (最近 ${_runs.length} 条)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ..._runs.map((r) => _buildRunItem(r)),
        ],
      ),
    );
  }

  Widget _buildRunItem(cron_api.CronRunDto run) {
    final started = DateTime.fromMillisecondsSinceEpoch(run.startedAt * 1000);
    final isOk = run.status == 'ok';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.chatListBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: isOk ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Text(
            _formatDateTime(started),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${run.durationMs}ms',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              run.output,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────── Add Job Dialog ───────────────────

class _NewJobData {
  final String name;
  final String jobType;
  final String scheduleType;
  final String expression;
  final String command;
  final String prompt;
  final String sessionTarget;
  final String model;
  final bool deleteAfterRun;

  _NewJobData({
    required this.name,
    required this.jobType,
    required this.scheduleType,
    required this.expression,
    required this.command,
    required this.prompt,
    required this.sessionTarget,
    required this.model,
    required this.deleteAfterRun,
  });
}

class _AddJobDialog extends StatefulWidget {
  const _AddJobDialog();

  @override
  State<_AddJobDialog> createState() => _AddJobDialogState();
}

class _AddJobDialogState extends State<_AddJobDialog> {
  String _jobType = 'shell';
  String _scheduleType = 'cron';
  String _sessionTarget = 'isolated';
  bool _deleteAfterRun = false;

  final _nameCtl = TextEditingController();
  final _exprCtl = TextEditingController(text: '*/5 * * * *');
  final _commandCtl = TextEditingController();
  final _promptCtl = TextEditingController();
  final _modelCtl = TextEditingController();

  @override
  void dispose() {
    _nameCtl.dispose();
    _exprCtl.dispose();
    _commandCtl.dispose();
    _promptCtl.dispose();
    _modelCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建定时任务'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                  labelText: '任务名称（可选）',
                  hintText: 'my-backup-task',
                ),
              ),
              const SizedBox(height: 16),
              // Job type
              const Text(
                '任务类型',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'shell',
                    label: Text('Shell 命令'),
                    icon: Icon(Icons.terminal, size: 18),
                  ),
                  ButtonSegment(
                    value: 'agent',
                    label: Text('AI Agent'),
                    icon: Icon(Icons.smart_toy, size: 18),
                  ),
                ],
                selected: {_jobType},
                onSelectionChanged: (v) => setState(() => _jobType = v.first),
              ),
              const SizedBox(height: 16),
              // Schedule type
              const Text(
                '调度方式',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cron', label: Text('Cron')),
                  ButtonSegment(value: 'every', label: Text('间隔')),
                  ButtonSegment(value: 'at', label: Text('定时')),
                ],
                selected: {_scheduleType},
                onSelectionChanged: (v) {
                  setState(() {
                    _scheduleType = v.first;
                    if (v.first == 'cron') {
                      _exprCtl.text = '*/5 * * * *';
                    } else if (v.first == 'every') {
                      _exprCtl.text = '60000';
                    } else {
                      _exprCtl.text = '';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              // Expression
              TextField(
                controller: _exprCtl,
                decoration: InputDecoration(
                  labelText: _scheduleType == 'cron'
                      ? 'Cron 表达式'
                      : _scheduleType == 'every'
                      ? '间隔（毫秒）'
                      : '执行时间 (RFC3339)',
                  hintText: _scheduleType == 'cron'
                      ? '*/5 * * * *'
                      : _scheduleType == 'every'
                      ? '60000'
                      : '2025-12-31T23:59:00Z',
                ),
              ),
              const SizedBox(height: 16),
              // Shell-specific
              if (_jobType == 'shell')
                TextField(
                  controller: _commandCtl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Shell 命令',
                    hintText: 'echo "hello world"',
                  ),
                ),
              // Agent-specific
              if (_jobType == 'agent') ...[
                TextField(
                  controller: _promptCtl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'AI Prompt',
                    hintText: '检查系统日志并总结异常...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelCtl,
                  decoration: const InputDecoration(
                    labelText: '模型（可选）',
                    hintText: '留空使用默认模型',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('会话目标', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'isolated', label: Text('隔离')),
                        ButtonSegment(value: 'main', label: Text('主会话')),
                      ],
                      selected: {_sessionTarget},
                      onSelectionChanged: (v) =>
                          setState(() => _sessionTarget = v.first),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('执行后删除', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    '仅执行一次后自动删除任务',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _deleteAfterRun,
                  activeTrackColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _deleteAfterRun = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _canSubmit() ? _submit : null,
          child: const Text('创建'),
        ),
      ],
    );
  }

  bool _canSubmit() {
    if (_exprCtl.text.isEmpty) return false;
    if (_jobType == 'shell' && _commandCtl.text.isEmpty) return false;
    if (_jobType == 'agent' && _promptCtl.text.isEmpty) return false;
    return true;
  }

  void _submit() {
    Navigator.pop(
      context,
      _NewJobData(
        name: _nameCtl.text.trim(),
        jobType: _jobType,
        scheduleType: _scheduleType,
        expression: _exprCtl.text.trim(),
        command: _commandCtl.text.trim(),
        prompt: _promptCtl.text.trim(),
        sessionTarget: _sessionTarget,
        model: _modelCtl.text.trim(),
        deleteAfterRun: _deleteAfterRun,
      ),
    );
  }
}
