import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/workspace_api.dart' as ws_api;

/// Tools & MCP management page — enable/disable tools and features with one click
class ToolsPage extends ConsumerStatefulWidget {
  const ToolsPage({super.key});

  @override
  ConsumerState<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends ConsumerState<ToolsPage> {
  ws_api.FeatureToggles? _features;
  List<ws_api.ToolInfo> _tools = [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final features = await ws_api.getFeatureToggles();
    final tools = await ws_api.listToolsWithStatus();
    if (mounted) {
      setState(() {
        _features = features;
        _tools = tools;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFeature(String feature, bool enabled) async {
    final result = await ws_api.updateFeatureToggle(
      feature: feature,
      enabled: enabled,
    );
    if (result == 'ok') {
      _showMessage('已${enabled ? "启用" : "停用"}');
      _loadAll();
    } else {
      _showMessage('操作失败');
    }
  }

  Future<void> _setToolApproval(String toolName, String approval) async {
    final result = await ws_api.setToolApproval(
      toolName: toolName,
      approval: approval,
    );
    if (result == 'ok') {
      _loadAll();
    } else {
      _showMessage('操作失败');
    }
  }

  void _showMessage(String msg) {
    setState(() => _message = msg);
    Future.delayed(const Duration(seconds: 2), () {
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.chatListBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.extension, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.pageTools,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (_message != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _message!,
                style: const TextStyle(fontSize: 12, color: AppColors.success),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureTogglesSection(),
          const SizedBox(height: 24),
          _buildToolsSection(),
        ],
      ),
    );
  }

  Widget _buildFeatureTogglesSection() {
    final f = _features;
    if (f == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.chatListBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.toggle_on_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                '功能开关',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '快速启用或停用 Agent 功能模块，选中即可直接使用',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),

          // Feature grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFeatureCard(
                'web_search',
                '网页搜索',
                '搜索互联网获取最新信息',
                Icons.search,
                f.webSearchEnabled,
              ),
              _buildFeatureCard(
                'web_fetch',
                '网页抓取',
                '抓取网页内容和提取文本',
                Icons.download,
                f.webFetchEnabled,
              ),
              _buildFeatureCard(
                'browser',
                '浏览器自动化',
                '自动化浏览器操作和交互',
                Icons.open_in_browser,
                f.browserEnabled,
              ),
              _buildFeatureCard(
                'http_request',
                'HTTP 请求',
                '发送 API 请求 (GET/POST/PUT/DELETE)',
                Icons.http,
                f.httpRequestEnabled,
              ),
              _buildFeatureCard(
                'memory_auto_save',
                '自动记忆',
                '自动保存对话中的重要信息',
                Icons.memory,
                f.memoryAutoSave,
              ),
              _buildFeatureCard(
                'cost_tracking',
                '费用追踪',
                '追踪 API 调用费用并设置限额',
                Icons.attach_money,
                f.costTrackingEnabled,
              ),
              _buildFeatureCard(
                'skills_open',
                '社区技能',
                '启用开源社区技能扩展',
                Icons.public,
                f.skillsOpenEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String feature,
    String title,
    String description,
    IconData icon,
    bool enabled,
  ) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: () => _toggleFeature(feature, !enabled),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.inputBg,
            border: Border.all(
              color: enabled ? AppColors.primary : AppColors.inputBorder,
              width: enabled ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: enabled ? AppColors.primary : AppColors.textHint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                enabled ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: enabled ? AppColors.success : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsSection() {
    if (_tools.isEmpty) return const SizedBox.shrink();

    // Group by category
    final categories = <String, List<ws_api.ToolInfo>>{};
    for (final tool in _tools) {
      categories.putIfAbsent(tool.category, () => []).add(tool);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.chatListBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.build_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                '内置工具',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_tools.length} 个工具',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '点击审批状态标签快速切换工具权限',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          // Legend
          _buildApprovalLegend(),
          const SizedBox(height: 16),
          ...categories.entries.map(
            (entry) => _buildToolCategory(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalLegend() {
    return Row(
      children: [
        _buildLegendItem('自动审批', Colors.green.shade50, Colors.green),
        const SizedBox(width: 12),
        _buildLegendItem('需要确认', Colors.orange.shade50, Colors.orange),
        const SizedBox(width: 12),
        _buildLegendItem('默认', Colors.grey.shade100, AppColors.textHint),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color bg, Color fg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: fg, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: fg)),
      ],
    );
  }

  Widget _buildToolCategory(String category, List<ws_api.ToolInfo> tools) {
    final categoryLabels = {
      'core': '核心工具',
      'vcs': '版本控制',
      'web': '网络 & Web',
      'memory': '记忆 & 存储',
      'system': '系统',
      'file': '文件处理',
      'agent': 'Agent 委派',
      'cron': '定时任务',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _categoryIcon(category),
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                categoryLabels[category] ?? category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${tools.length})',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tools.map(_buildToolRow),
        ],
      ),
    );
  }

  Widget _buildToolRow(ws_api.ToolInfo tool) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            _categoryIcon(tool.category),
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: Text(
              tool.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              tool.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Approval toggle chips
          _buildApprovalChip(tool, 'auto', '自动', Colors.green),
          const SizedBox(width: 4),
          _buildApprovalChip(tool, 'ask', '确认', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildApprovalChip(
    ws_api.ToolInfo tool,
    String approval,
    String label,
    Color color,
  ) {
    final isActive =
        (approval == 'auto' && tool.autoApproved) ||
        (approval == 'ask' && tool.alwaysAsk);

    return InkWell(
      onTap: () {
        // Toggle: if already active, set to default; otherwise set to this approval
        final newApproval = isActive ? 'default' : approval;
        _setToolApproval(tool.name, newApproval);
      },
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? color : AppColors.chatListBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? color : AppColors.textHint,
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'core' => Icons.terminal,
      'vcs' => Icons.merge_type,
      'web' => Icons.language,
      'memory' => Icons.memory,
      'system' => Icons.computer,
      'file' => Icons.description,
      'agent' => Icons.smart_toy,
      'cron' => Icons.schedule,
      _ => Icons.extension,
    };
  }
}
