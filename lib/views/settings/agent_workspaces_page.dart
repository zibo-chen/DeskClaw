import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coraldesk/l10n/app_localizations.dart';
import 'package:coraldesk/theme/app_theme.dart';
import 'package:coraldesk/providers/providers.dart';
import 'package:coraldesk/src/rust/api/agent_workspace_api.dart'
    as workspace_api;

/// Agent Workspaces page — split-panel desktop layout
/// Left: Workspace list | Right: Editor with code editor for identity files
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
  workspace_api.AgentWorkspaceDto? _selectedWorkspace;
  bool _isCreatingNew = false;

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

  Future<void> _selectWorkspace(workspace_api.AgentWorkspaceSummary ws) async {
    final fullDto = await workspace_api.getAgentWorkspace(workspaceId: ws.id);
    if (mounted) {
      setState(() {
        _selectedWorkspace = fullDto;
        _isCreatingNew = false;
      });
    }
  }

  void _createNew() {
    setState(() {
      _selectedWorkspace = null;
      _isCreatingNew = true;
    });
  }

  Future<void> _saveWorkspace(workspace_api.AgentWorkspaceDto dto) async {
    final l10n = AppLocalizations.of(context)!;
    final saveResult = await workspace_api.upsertAgentWorkspace(workspace: dto);
    if (!mounted) return;

    if (saveResult == 'ok') {
      _showMessage(
        _isCreatingNew
            ? l10n.agentWorkspaceCreated(dto.name)
            : l10n.agentWorkspaceSaved(dto.name),
      );
      await ref.read(agentWorkspacesProvider.notifier).refresh();
      // Reload the saved workspace to get the generated ID
      final workspaces = ref.read(agentWorkspacesProvider);
      final saved = workspaces.firstWhere(
        (w) => w.name == dto.name,
        orElse: () => workspaces.first,
      );
      await _selectWorkspace(saved);
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
      setState(() {
        _selectedWorkspace = null;
        _isCreatingNew = false;
      });
    } else {
      _showMessage('${l10n.operationFailed}: $result', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workspaces = ref.watch(agentWorkspacesProvider);

    return Container(
      color: c.surfaceBg,
      child: Column(
        children: [
          // Status message bar
          if (_message != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

          // Main split layout
          Expanded(
            child: Row(
              children: [
                // ═══════════════════════════════════════════════════
                // LEFT PANEL: Workspace list (300px)
                // ═══════════════════════════════════════════════════
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    border: Border(right: BorderSide(color: c.chatListBorder)),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: c.chatListBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.workspaces_outline,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.agentWorkspaces,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: _loadWorkspaces,
                              tooltip: l10n.refresh,
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: _createNew,
                              tooltip: l10n.agentWorkspaceNew,
                              color: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),

                      // Workspace list
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : workspaces.isEmpty
                            ? _buildEmptyList(l10n)
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: workspaces.length,
                                itemBuilder: (ctx, i) =>
                                    _buildWorkspaceItem(workspaces[i], l10n),
                              ),
                      ),
                    ],
                  ),
                ),

                // ═══════════════════════════════════════════════════
                // RIGHT PANEL: Editor
                // ═══════════════════════════════════════════════════
                Expanded(
                  child: _selectedWorkspace != null || _isCreatingNew
                      ? _WorkspaceEditor(
                          key: ValueKey(_selectedWorkspace?.id ?? 'new'),
                          workspace: _selectedWorkspace,
                          isNew: _isCreatingNew,
                          onSave: _saveWorkspace,
                          onCancel: () => setState(() {
                            _selectedWorkspace = null;
                            _isCreatingNew = false;
                          }),
                        )
                      : _buildEmptyEditor(l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyList(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspaces_outline, size: 40, color: c.textHint),
            const SizedBox(height: 12),
            Text(
              l10n.agentWorkspaceNoWorkspaces,
              style: TextStyle(fontSize: 13, color: c.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.agentWorkspaceNew),
              onPressed: _createNew,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceItem(
    workspace_api.AgentWorkspaceSummary ws,
    AppLocalizations l10n,
  ) {
    final isSelected = _selectedWorkspace?.id == ws.id;
    final tagColor = _parseColor(ws.colorTag);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _selectWorkspace(ws),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (tagColor ?? AppColors.primary).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ws.avatar.isNotEmpty ? ws.avatar : '🤖',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),

                // Info
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
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ws.enabled ? c.textPrimary : c.textHint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!ws.enabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'OFF',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: c.textHint,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (ws.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ws.description,
                          style: TextStyle(fontSize: 11, color: c.textHint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 16, color: c.textHint),
                  onPressed: () => _deleteWorkspace(ws),
                  tooltip: l10n.delete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEditor(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_note,
            size: 64,
            color: c.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.agentWorkspaceNoWorkspacesHint,
            style: TextStyle(fontSize: 14, color: c.textHint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.agentWorkspaceNew),
            onPressed: _createNew,
          ),
        ],
      ),
    );
  }

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
}

// ═══════════════════════════════════════════════════════════════
//  Workspace Editor — right panel with code editor
// ═══════════════════════════════════════════════════════════════

class _WorkspaceEditor extends StatefulWidget {
  final workspace_api.AgentWorkspaceDto? workspace;
  final bool isNew;
  final Function(workspace_api.AgentWorkspaceDto) onSave;
  final VoidCallback onCancel;

  const _WorkspaceEditor({
    super.key,
    this.workspace,
    required this.isNew,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_WorkspaceEditor> createState() => _WorkspaceEditorState();
}

class _WorkspaceEditorState extends State<_WorkspaceEditor>
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

  static const _defaultAvatarOptions = [
    '🤖',
    '👩‍💼',
    '👨‍💻',
    '🧑‍🔬',
    '🎨',
    '📝',
    '🔧',
    '🧠',
    '🦊',
    '🐙',
    '🦉',
    '🐬',
    '🌟',
    '💡',
    '🎯',
    '🔮',
  ];

  static const _colorOptions = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#E91E63',
    '#9C27B0',
    '#009688',
    '#FF5722',
    '#795548',
    '#607D8B',
    '#F44336',
    '#3F51B5',
    '#00BCD4',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final e = widget.workspace;
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
      id: widget.workspace?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      avatar: _avatar,
      workspaceDir: widget.workspace?.workspaceDir ?? '',
      enabled: _enabled,
      systemPrompt: '',
      soulMd: _soulMdCtrl.text,
      agentsMd: _agentsMdCtrl.text,
      userMd: _userMdCtrl.text,
      identityMd: _identityMdCtrl.text,
      colorTag: _colorTag,
      createdAt: widget.workspace?.createdAt ?? now,
      updatedAt: now,
    );
    widget.onSave(dto);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // ── Header bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: c.cardBg,
            border: Border(bottom: BorderSide(color: c.chatListBorder)),
          ),
          child: Row(
            children: [
              Text(
                widget.isNew ? l10n.agentWorkspaceNew : l10n.agentWorkspaceEdit,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: widget.onCancel, child: Text(l10n.cancel)),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.save, size: 16),
                label: Text(l10n.save),
                onPressed: _save,
              ),
            ],
          ),
        ),

        // ── Content: Left-Right split ──
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════
              // LEFT: Basic info panel (280px)
              // ═══════════════════════════════════════════════════
              Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: c.chatListBorder)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      _buildLabel(l10n.agentWorkspaceNameLabel),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: l10n.agentWorkspaceNameHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 13, color: c.textPrimary),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _buildLabel(l10n.agentWorkspaceDescLabel),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: l10n.agentWorkspaceDescHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 13, color: c.textPrimary),
                      ),
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
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : Border.all(color: c.chatListBorder),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
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
                            int.parse(
                              'FF${hex.replaceFirst('#', '')}',
                              radix: 16,
                            ),
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
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
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

              // ═══════════════════════════════════════════════════
              // RIGHT: Code editor panel (flexible)
              // ═══════════════════════════════════════════════════
              Expanded(
                child: Column(
                  children: [
                    // Tab bar
                    Container(
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        border: Border(
                          bottom: BorderSide(color: c.chatListBorder),
                        ),
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

                    // Code editor views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _CodeEditor(
                            controller: _soulMdCtrl,
                            hint: l10n.agentWorkspaceSoulMdHint,
                            title: 'SOUL.md',
                            subtitle: l10n.agentWorkspaceSoulMd
                                .split('—')
                                .last
                                .trim(),
                          ),
                          _CodeEditor(
                            controller: _agentsMdCtrl,
                            hint: l10n.agentWorkspaceAgentsMdHint,
                            title: 'AGENTS.md',
                            subtitle: l10n.agentWorkspaceAgentsMd
                                .split('—')
                                .last
                                .trim(),
                          ),
                          _CodeEditor(
                            controller: _userMdCtrl,
                            hint: l10n.agentWorkspaceUserMdHint,
                            title: 'USER.md',
                            subtitle: l10n.agentWorkspaceUserMd
                                .split('—')
                                .last
                                .trim(),
                          ),
                          _CodeEditor(
                            controller: _identityMdCtrl,
                            hint: l10n.agentWorkspaceIdentityMdHint,
                            title: 'IDENTITY.md',
                            subtitle: l10n.agentWorkspaceIdentityMd
                                .split('—')
                                .last
                                .trim(),
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
    // Synchronize scroll between line numbers and editor
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
                bottom: BorderSide(
                  color: c.chatListBorder.withValues(alpha: 0.5),
                ),
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
                      padding: const EdgeInsets.only(
                        top: 12,
                        right: 8,
                        bottom: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          _lineCount.clamp(1, 9999),
                          (i) => SizedBox(
                            height: 21, // Match line height (14 * 1.5)
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
                      minLines: 25,
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
