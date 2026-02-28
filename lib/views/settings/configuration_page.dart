import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/workspace_api.dart' as ws_api;

/// Configuration page showing autonomy settings and tool permissions
class ConfigurationPage extends ConsumerStatefulWidget {
  const ConfigurationPage({super.key});

  @override
  ConsumerState<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends ConsumerState<ConfigurationPage> {
  ws_api.AutonomyConfig? _autonomy;
  List<ws_api.ToolInfo>? _tools;
  bool _loading = true;
  DeskClawColors get c => DeskClawColors.of(context);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final autonomy = await ws_api.getAutonomyConfig();
    final tools = await ws_api.listToolsWithStatus();
    if (mounted) {
      setState(() {
        _autonomy = autonomy;
        _tools = tools;
        _loading = false;
      });
    }
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
      decoration: BoxDecoration(
        color: c.surfaceBg,
        border: Border(bottom: BorderSide(color: c.chatListBorder, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.settings, size: 20, color: AppColors.primary),
          SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.pageConfiguration,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
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
          _buildAutonomySection(),
          const SizedBox(height: 24),
          _buildToolsSection(),
        ],
      ),
    );
  }

  Widget _buildAutonomySection() {
    final a = _autonomy;
    if (a == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.chatListBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Autonomy & Security',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Autonomy level selector
          Text(
            'Autonomy Level',
            style: TextStyle(
              fontSize: 13,
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLevelChip(
                'read_only',
                'Read Only',
                Icons.visibility,
                a.level,
              ),
              const SizedBox(width: 8),
              _buildLevelChip(
                'supervised',
                'Supervised',
                Icons.supervisor_account,
                a.level,
              ),
              const SizedBox(width: 8),
              _buildLevelChip('full', 'Full', Icons.bolt, a.level),
            ],
          ),
          const SizedBox(height: 16),

          // Settings
          _buildInfoRow('Workspace Only', a.workspaceOnly ? 'Yes' : 'No'),
          _buildInfoRow(
            'Require Approval (Medium Risk)',
            a.requireApprovalForMediumRisk ? 'Yes' : 'No',
          ),
          _buildInfoRow(
            'Block High Risk',
            a.blockHighRiskCommands ? 'Yes' : 'No',
          ),
          _buildInfoRow('Max Actions/Hour', '${a.maxActionsPerHour}'),
          _buildInfoRow('Max Cost/Day', '${a.maxCostPerDayCents}¢'),

          if (a.allowedCommands.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Allowed Commands',
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: a.allowedCommands
                  .map(
                    (c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 11)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],

          if (a.autoApprove.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Auto-Approved Tools',
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: a.autoApprove
                  .map(
                    (t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.green.shade50,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelChip(
    String value,
    String label,
    IconData icon,
    String current,
  ) {
    final isSelected = current == value;
    return InkWell(
      onTap: () async {
        await ws_api.updateAutonomyLevel(level: value);
        _loadAll();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : c.inputBg,
          border: Border.all(
            color: isSelected ? AppColors.primary : c.chatListBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : c.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection() {
    final tools = _tools;
    if (tools == null || tools.isEmpty) return const SizedBox.shrink();

    // Group by category
    final categories = <String, List<ws_api.ToolInfo>>{};
    for (final tool in tools) {
      categories.putIfAbsent(tool.category, () => []).add(tool);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.chatListBorder),
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
              Text(
                'Tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${tools.length} tools',
                style: TextStyle(fontSize: 12, color: c.textHint),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.entries.map(
            (entry) => _buildToolCategory(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCategory(String category, List<ws_api.ToolInfo> tools) {
    final categoryLabels = {
      'core': 'Core Tools',
      'vcs': 'Version Control',
      'web': 'Web & Network',
      'memory': 'Memory',
      'system': 'System',
      'file': 'File Processing',
      'agent': 'Agent',
      'cron': 'Scheduling',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryLabels[category] ?? category.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textHint,
              letterSpacing: 0.5,
            ),
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
          Icon(_toolIcon(tool.category), size: 16, color: c.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: Text(
              tool.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                color: c.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              tool.description,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ),
          if (tool.autoApproved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Auto',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (tool.alwaysAsk)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Ask',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _toolIcon(String category) {
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: c.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
