import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coraldesk/l10n/app_localizations.dart';
import 'package:coraldesk/theme/app_theme.dart';
import 'package:coraldesk/providers/providers.dart';
import 'package:coraldesk/src/rust/api/agent_workspace_api.dart'
    as workspace_api;
import 'package:coraldesk/src/rust/api/agent_api.dart' as agent_api;
import 'package:coraldesk/views/settings/widgets/settings_scaffold.dart';
import 'package:coraldesk/views/settings/widgets/desktop_dialog.dart';

/// Agent Workspaces page — consistent with other settings pages
/// Uses SettingsScaffold and modal dialogs for editing
class AgentWorkspacesPage extends ConsumerStatefulWidget {
  const AgentWorkspacesPage({super.key});

  @override
  ConsumerState<AgentWorkspacesPage> createState() =>
      _AgentWorkspacesPageState();
}

class _AgentWorkspacesPageState extends ConsumerState<AgentWorkspacesPage> {
  bool _loading = true;
  String? _message;
  bool _isError = false;

  CoralDeskColors get c => CoralDeskColors.of(context);

  @override
  void initState() {
    super.initState();
    _loadWorkspaces();
  }

  Future<void> _loadWorkspaces() async {
    setState(() => _loading = true);
    await ref.read(agentWorkspacesProvider.notifier).load();
    if (mounted) setState(() => _loading = false);
  }

  void _showMessage(String msg, {bool isError = false}) {
    setState(() {
      _message = msg;
      _isError = isError;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = null);
    });
  }

  Future<void> _openEditor({workspace_api.AgentWorkspaceDto? existing}) async {
    final result = await showDialog<workspace_api.AgentWorkspaceDto>(
      context: context,
      builder: (ctx) => _WorkspaceEditorDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final saveResult = await workspace_api.upsertAgentWorkspace(workspace: result);
    if (!mounted) return;
    
    if (saveResult == 'ok') {
      _showMessage(
        existing == null
            ? l10n.agentWorkspaceCreated(result.name)
            : l10n.agentWorkspaceSaved(result.name),
      );
      await ref.read(agentWorkspacesProvider.notifier).refresh();
    } else {
      _showMessage('${l10n.operationFailed}: $saveResult', isError: true);
    }
  }

  Future<void> _deleteWorkspace(workspace_api.AgentWorkspaceSummary ws) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.agentWorkspaceDeleteTitle),
        content: Text(l10n.agentWorkspaceDeleteConfirm(ws.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await workspace_api.deleteAgentWorkspace(workspaceId: ws.id);
    if (!mounted) return;
    if (result == 'ok') {
      _showMessage(l10n.agentWorkspaceDeleted(ws.name));
      await ref.read(agentWorkspacesProvider.notifier).refresh();
    } else {
      _showMessage('${l10n.operationFailed}: $result', isError: true);
    }
  }

  Future<void> _openWorkspaceFolder(String workspaceId) async {
    final dir = await workspace_api.getAgentWorkspaceDir(workspaceId: workspaceId);
    await agent_api.openInSystem(path: dir);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workspaces = ref.watch(agentWorkspacesProvider);

    return SettingsScaffold(
      title: l10n.agentWorkspaces,
      isLoading: _loading,
      useScrollView: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: l10n.refresh,
          onPressed: _loadWorkspaces,
        ),
        const SizedBox(width: 4),
        FilledButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.agentWorkspaceNew),
          onPressed: () => _openEditor(),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status message
          if (_message != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: _isError
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    size: 18,
                    color: _isError ? Colors.red : Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _message!,
                    style: TextStyle(
                      color: _isError ? Colors.red : Colors.green[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                            Icon(Icons.workspaces_outline, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.agentWorkspaceOverview,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.agentWorkspaceOverviewDesc,
                          style: TextStyle(fontSize: 13, color: c.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatChip(
                              label: l10n.totalCount,
                              value: '${workspaces.length}',
                              color: AppColors.primary,
                              c: c,
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              label: l10n.enabled,
                              value: '${workspaces.where((w) => w.enabled).length}',
                              color: Colors.green,
                              c: c,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Workspaces grid
                  Expanded(
                    child: workspaces.isEmpty
                        ? _buildEmptyState(l10n)
                        : _buildWorkspacesGrid(workspaces, l10n),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspaces_outline, size: 64, color: c.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            l10n.agentWorkspaceNoWorkspaces,
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.agentWorkspaceNoWorkspacesHint,
            style: TextStyle(fontSize: 13, color: c.textHint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.agentWorkspaceNew),
            onPressed: () => _openEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspacesGrid(
    List<workspace_api.AgentWorkspaceSummary> workspaces,
    AppLocalizations l10n,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 160,
      ),
      itemCount: workspaces.length,
      itemBuilder: (ctx, i) => _WorkspaceCard(
        workspace: workspaces[i],
        onEdit: () async {
          final fullDto = await workspace_api.getAgentWorkspace(
            workspaceId: workspaces[i].id,
          );
          if (fullDto != null && mounted) {
            _openEditor(existing: fullDto);
          }
        },
        onDelete: () => _deleteWorkspace(workspaces[i]),
        onOpenFolder: () => _openWorkspaceFolder(workspaces[i].id),
        c: c,
        l10n: l10n,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Workspace Card
// ═══════════════════════════════════════════════════════════════

class _WorkspaceCard extends StatefulWidget {
  final workspace_api.AgentWorkspaceSummary workspace;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenFolder;
  final CoralDeskColors c;
  final AppLocalizations l10n;

  const _WorkspaceCard({
    required this.workspace,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenFolder,
    required this.c,
    required this.l10n,
  });

  @override
  State<_WorkspaceCard> createState() => _WorkspaceCardState();
}

class _WorkspaceCardState extends State<_WorkspaceCard> {
  bool _hovering = false;

  Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final ws = widget.workspace;
    final tagColor = _parseColor(ws.colorTag) ?? AppColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovering ? tagColor.withValues(alpha: 0.5) : c.chatListBorder,
            width: _hovering ? 1.5 : 1,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: tagColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ws.avatar.isNotEmpty ? ws.avatar : '🤖',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ws.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ws.enabled ? c.textPrimary : c.textHint,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!ws.enabled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'OFF',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: c.textHint,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (ws.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        ws.description,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Open folder button
                      IconButton(
                        icon: Icon(
                          Icons.folder_open_outlined,
                          size: 18,
                          color: _hovering ? c.textSecondary : c.textHint,
                        ),
                        onPressed: widget.onOpenFolder,
                        tooltip: widget.l10n.openWorkspaceFolder,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      // Edit button
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: _hovering ? c.textSecondary : c.textHint,
                        ),
                        onPressed: widget.onEdit,
                        tooltip: widget.l10n.editMessage,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      // Delete button
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: _hovering ? Colors.red.withValues(alpha: 0.7) : c.textHint,
                        ),
                        onPressed: widget.onDelete,
                        tooltip: widget.l10n.delete,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Stat Chip
// ═══════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CoralDeskColors c;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Workspace Editor Dialog — Modal dialog for editing workspaces
// ═══════════════════════════════════════════════════════════════

class _WorkspaceEditorDialog extends StatefulWidget {
  final workspace_api.AgentWorkspaceDto? existing;

  const _WorkspaceEditorDialog({this.existing});

  @override
  State<_WorkspaceEditorDialog> createState() => _WorkspaceEditorDialogState();
}

class _WorkspaceEditorDialogState extends State<_WorkspaceEditorDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _soulMdCtrl;
  late final TextEditingController _agentsMdCtrl;
  late final TextEditingController _userMdCtrl;
  late final TextEditingController _identityMdCtrl;
  late String _avatar;
  late String _colorTag;
  late bool _enabled;
  late TabController _tabController;

  CoralDeskColors get c => CoralDeskColors.of(context);

  bool get isNew => widget.existing == null;

  static const _defaultAvatarOptions = [
    '🤖', '👩‍💼', '👨‍💻', '🧑‍🔬', '🎨', '📝', '🔧', '🧠',
    '🦊', '🐙', '🦉', '🐬', '🌟', '💡', '🎯', '🔮',
  ];

  static const _colorOptions = [
    '#2196F3', '#4CAF50', '#FF9800', '#E91E63',
    '#9C27B0', '#009688', '#FF5722', '#795548',
    '#607D8B', '#F44336', '#3F51B5', '#00BCD4',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _soulMdCtrl = TextEditingController(text: e?.soulMd ?? '');
    _agentsMdCtrl = TextEditingController(text: e?.agentsMd ?? '');
    _userMdCtrl = TextEditingController(text: e?.userMd ?? '');
    _identityMdCtrl = TextEditingController(text: e?.identityMd ?? '');
    _avatar = e?.avatar ?? '🤖';
    _colorTag = e?.colorTag ?? '#2196F3';
    _enabled = e?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _soulMdCtrl.dispose();
    _agentsMdCtrl.dispose();
    _userMdCtrl.dispose();
    _identityMdCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final dto = workspace_api.AgentWorkspaceDto(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      avatar: _avatar,
      workspaceDir: widget.existing?.workspaceDir ?? '',
      enabled: _enabled,
      systemPrompt: '',
      soulMd: _soulMdCtrl.text,
      agentsMd: _agentsMdCtrl.text,
      userMd: _userMdCtrl.text,
      identityMd: _identityMdCtrl.text,
      colorTag: _colorTag,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.pop(context, dto);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DesktopDialog(
      title: isNew ? l10n.agentWorkspaceNew : l10n.agentWorkspaceEdit,
      icon: Icons.workspaces_outline,
      width: 900,
      maxHeight: MediaQuery.of(context).size.height * 0.9,
      content: SizedBox(
        height: 600,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════════
            // LEFT: Basic info (280px)
            // ═══════════════════════════════════════════════════
            SizedBox(
              width: 260,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    _buildLabel(l10n.agentWorkspaceNameLabel),
                    const SizedBox(height: 6),
                    _buildTextField(_nameCtrl, l10n.agentWorkspaceNameHint),
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel(l10n.agentWorkspaceDescLabel),
                    const SizedBox(height: 6),
                    _buildTextField(_descCtrl, l10n.agentWorkspaceDescHint, maxLines: 2),
                    const SizedBox(height: 16),

                    // Avatar
                    _buildLabel(l10n.agentWorkspaceAvatarLabel),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _defaultAvatarOptions.map((emoji) {
                        final selected = _avatar == emoji;
                        return GestureDetector(
                          onTap: () => setState(() => _avatar = emoji),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : c.inputBg,
                              borderRadius: BorderRadius.circular(6),
                              border: selected
                                  ? Border.all(color: AppColors.primary, width: 2)
                                  : Border.all(color: c.chatListBorder),
                            ),
                            alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 16)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Color tag
                    _buildLabel(l10n.agentWorkspaceColorLabel),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _colorOptions.map((hex) {
                        final color = Color(
                          int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                        );
                        final selected = _colorTag == hex;
                        return GestureDetector(
                          onTap: () => setState(() => _colorTag = hex),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                              border: selected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              boxShadow: selected
                                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Enabled toggle
                    Row(
                      children: [
                        Text(
                          l10n.agentWorkspaceEnabled,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _enabled,
                            onChanged: (v) => setState(() => _enabled = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Vertical divider
            Container(
              width: 1,
              color: c.chatListBorder,
            ),

            const SizedBox(width: 20),

            // ═══════════════════════════════════════════════════
            // RIGHT: Code editor with tabs
            // ═══════════════════════════════════════════════════
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.chatListBorder)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: c.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'SOUL.md'),
                        Tab(text: 'AGENTS.md'),
                        Tab(text: 'USER.md'),
                        Tab(text: 'IDENTITY.md'),
                      ],
                    ),
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _CodeEditor(
                          controller: _soulMdCtrl,
                          hint: l10n.agentWorkspaceSoulMdHint,
                          title: 'SOUL.md',
                          subtitle: l10n.agentWorkspaceSoulMd.split('—').last.trim(),
                        ),
                        _CodeEditor(
                          controller: _agentsMdCtrl,
                          hint: l10n.agentWorkspaceAgentsMdHint,
                          title: 'AGENTS.md',
                          subtitle: l10n.agentWorkspaceAgentsMd.split('—').last.trim(),
                        ),
                        _CodeEditor(
                          controller: _userMdCtrl,
                          hint: l10n.agentWorkspaceUserMdHint,
                          title: 'USER.md',
                          subtitle: l10n.agentWorkspaceUserMd.split('—').last.trim(),
                        ),
                        _CodeEditor(
                          controller: _identityMdCtrl,
                          hint: l10n.agentWorkspaceIdentityMdHint,
                          title: 'IDENTITY.md',
                          subtitle: l10n.agentWorkspaceIdentityMd.split('—').last.trim(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.save, size: 16),
          label: Text(l10n.save),
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.chatListBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.chatListBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: c.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: TextStyle(fontSize: 13, color: c.textPrimary),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  VSCode-style Code Editor with line numbers
// ═══════════════════════════════════════════════════════════════

class _CodeEditor extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String title;
  final String subtitle;

  const _CodeEditor({
    required this.controller,
    required this.hint,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<_CodeEditor> {
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();
  int _lineCount = 1;

  CoralDeskColors get c => CoralDeskColors.of(context);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateLineCount);
    _updateLineCount();
    _editorScrollController.addListener(_syncScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLineCount);
    _editorScrollController.removeListener(_syncScroll);
    _editorScrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  void _syncScroll() {
    if (_lineNumberScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_editorScrollController.offset);
    }
  }

  void _updateLineCount() {
    final newCount = '\n'.allMatches(widget.controller.text).length + 1;
    if (newCount != _lineCount) {
      setState(() => _lineCount = newCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: c.surfaceBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: c.inputBg.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(color: c.chatListBorder.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 14, color: c.textHint),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '— ${widget.subtitle}',
                    style: TextStyle(fontSize: 11, color: c.textHint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$_lineCount lines',
                  style: TextStyle(fontSize: 11, color: c.textHint),
                ),
              ],
            ),
          ),

          // Editor with line numbers
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line numbers gutter
                Container(
                  width: 48,
                  color: c.inputBg.withValues(alpha: 0.3),
                  child: SingleChildScrollView(
                    controller: _lineNumberScrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, right: 8, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          _lineCount.clamp(1, 9999),
                          (i) => SizedBox(
                            height: 21,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: c.textHint,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Editor area
                Expanded(
                  child: SingleChildScrollView(
                    controller: _editorScrollController,
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      minLines: 20,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: c.textHint.withValues(alpha: 0.5),
                          fontFamily: 'monospace',
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        filled: false,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: c.textPrimary,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
