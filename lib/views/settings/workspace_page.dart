import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/workspace_api.dart' as ws_api;

/// Workspace & Agent Configuration page
class WorkspacePage extends ConsumerStatefulWidget {
  const WorkspacePage({super.key});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  WorkspaceConfig? _workspace;
  AgentConfigDto? _agentConfig;
  MemoryConfigDto? _memoryConfig;
  CostConfigDto? _costConfig;
  bool _loading = true;
  DeskClawColors get c => DeskClawColors.of(context);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final workspace = await ws_api.getWorkspaceConfig();
    final agent = await ws_api.getAgentConfig();
    final memory = await ws_api.getMemoryConfig();
    final cost = await ws_api.getCostConfig();
    if (mounted) {
      setState(() {
        _workspace = workspace;
        _agentConfig = agent;
        _memoryConfig = memory;
        _costConfig = cost;
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
          Icon(Icons.business, size: 20, color: AppColors.primary),
          SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.pageWorkspace,
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
          _buildWorkspaceSection(),
          const SizedBox(height: 24),
          _buildAgentSection(),
          const SizedBox(height: 24),
          _buildMemorySection(),
          const SizedBox(height: 24),
          _buildCostSection(),
        ],
      ),
    );
  }

  Widget _buildWorkspaceSection() {
    return _buildCard(
      title: 'Workspace Info',
      icon: Icons.folder_outlined,
      children: [
        _buildReadOnlyField(
          'Workspace Directory',
          _workspace?.workspaceDir ?? '',
        ),
        _buildReadOnlyField('Config File', _workspace?.configPath ?? ''),
      ],
    );
  }

  Widget _buildAgentSection() {
    final agent = _agentConfig;
    if (agent == null) return const SizedBox.shrink();

    return _buildCard(
      title: 'Agent Settings',
      icon: Icons.auto_awesome,
      children: [
        _buildNumberField('Max Tool Iterations', agent.maxToolIterations, (
          v,
        ) async {
          await ws_api.updateAgentConfig(maxToolIterations: v);
          _loadAll();
        }),
        _buildNumberField('Max History Messages', agent.maxHistoryMessages, (
          v,
        ) async {
          await ws_api.updateAgentConfig(maxHistoryMessages: v);
          _loadAll();
        }),
        _buildSwitchField('Parallel Tool Execution', agent.parallelTools, (
          v,
        ) async {
          await ws_api.updateAgentConfig(parallelTools: v);
          _loadAll();
        }),
        _buildSwitchField('Compact Context', agent.compactContext, (v) async {
          await ws_api.updateAgentConfig(compactContext: v);
          _loadAll();
        }),
        _buildReadOnlyField('Tool Dispatcher', agent.toolDispatcher),
      ],
    );
  }

  Widget _buildMemorySection() {
    final mem = _memoryConfig;
    if (mem == null) return const SizedBox.shrink();

    return _buildCard(
      title: 'Memory',
      icon: Icons.memory,
      children: [
        _buildReadOnlyField('Backend', mem.backend),
        _buildReadOnlyField('Auto Save', mem.autoSave ? 'Yes' : 'No'),
        _buildReadOnlyField(
          'Hygiene',
          mem.hygieneEnabled ? 'Enabled' : 'Disabled',
        ),
        _buildReadOnlyField('Archive After', '${mem.archiveAfterDays} days'),
        _buildReadOnlyField('Purge After', '${mem.purgeAfterDays} days'),
        _buildReadOnlyField('Embedding Provider', mem.embeddingProvider),
        _buildReadOnlyField('Embedding Model', mem.embeddingModel),
      ],
    );
  }

  Widget _buildCostSection() {
    final cost = _costConfig;
    if (cost == null) return const SizedBox.shrink();

    return _buildCard(
      title: 'Cost Tracking',
      icon: Icons.attach_money,
      children: [
        _buildReadOnlyField('Enabled', cost.enabled ? 'Yes' : 'No'),
        _buildReadOnlyField(
          'Daily Limit',
          '\$${cost.dailyLimitUsd.toStringAsFixed(2)}',
        ),
        _buildReadOnlyField(
          'Monthly Limit',
          '\$${cost.monthlyLimitUsd.toStringAsFixed(2)}',
        ),
        _buildReadOnlyField('Warn At', '${cost.warnAtPercent}%'),
      ],
    );
  }

  // ── Reusable widgets ──

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(fontSize: 13, color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onFieldSubmitted: (text) {
                final v = int.tryParse(text);
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Re-export the generated types used
typedef WorkspaceConfig = ws_api.WorkspaceConfig;
typedef AgentConfigDto = ws_api.AgentConfigDto;
typedef MemoryConfigDto = ws_api.MemoryConfigDto;
typedef CostConfigDto = ws_api.CostConfigDto;
