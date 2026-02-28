import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/sessions_api.dart' as sessions_api;

/// Sessions management page - view, rename, delete persisted sessions
class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> {
  List<sessions_api.SessionSummary> _sessions = [];
  sessions_api.SessionStats? _stats;
  sessions_api.SessionDetail? _selectedDetail;
  bool _loading = true;
  String? _message;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await sessions_api.initSessionStore();
    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final sessions = await sessions_api.listSessions();
    final stats = await sessions_api.getSessionStats();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _stats = stats;
        _loading = false;
      });
    }
  }

  Future<void> _selectSession(String id) async {
    final detail = await sessions_api.getSessionDetail(sessionId: id);
    if (mounted) {
      setState(() => _selectedDetail = detail);
    }
  }

  Future<void> _deleteSession(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除会话'),
        content: const Text('确定删除此会话？此操作不可撤销。'),
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
      await sessions_api.deleteSession(sessionId: id);
      _showMessage('已删除会话');
      if (_selectedDetail?.id == id) {
        setState(() => _selectedDetail = null);
      }
      _loadAll();
    }
  }

  Future<void> _renameSession(String id, String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '会话标题'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty && newTitle != currentTitle) {
      await sessions_api.renameSession(sessionId: id, newTitle: newTitle);
      _showMessage('已重命名');
      _loadAll();
      if (_selectedDetail?.id == id) {
        _selectSession(id);
      }
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空所有会话'),
        content: const Text('确定删除所有已保存的会话？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('全部删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await sessions_api.clearAllSessions();
      _showMessage('已清空所有会话');
      setState(() => _selectedDetail = null);
      _loadAll();
    }
  }

  void _showMessage(String msg) {
    setState(() => _message = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = null);
    });
  }

  List<sessions_api.SessionSummary> get _filteredSessions {
    if (_searchQuery.isEmpty) return _sessions;
    final q = _searchQuery.toLowerCase();
    return _sessions.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.lastMessagePreview.toLowerCase().contains(q);
    }).toList();
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
          const Icon(Icons.history, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          const Text(
            'Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          if (_stats != null) ...[
            _statBadge('${_stats!.totalSessions}', '会话'),
            const SizedBox(width: 8),
            _statBadge('${_stats!.totalMessages}', '消息'),
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
          if (_sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, size: 20),
              tooltip: '清空所有会话',
              color: AppColors.error,
              onPressed: _clearAll,
            ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_sessions.isEmpty) {
      return _buildEmptyState();
    }
    return Row(
      children: [
        // Session list
        SizedBox(width: 360, child: _buildSessionList()),
        const VerticalDivider(width: 1),
        // Session detail
        Expanded(child: _buildDetail()),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无已保存的会话',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '在聊天中发送消息后，会话将自动保存到此处',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    final filtered = _filteredSessions;
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索会话...',
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: AppColors.textHint,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => _buildSessionItem(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionItem(sessions_api.SessionSummary session) {
    final isSelected = _selectedDetail?.id == session.id;
    final date = DateTime.fromMillisecondsSinceEpoch(session.updatedAt * 1000);
    final dateStr = _formatDate(date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.sidebarActiveBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: isSelected,
        onTap: () => _selectSession(session.id),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session.lastMessagePreview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  session.lastMessagePreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${session.messageCount} 条',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            size: 18,
            color: AppColors.textHint,
          ),
          onSelected: (action) {
            if (action == 'rename') {
              _renameSession(session.id, session.title);
            } else if (action == 'delete') {
              _deleteSession(session.id);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('重命名'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail() {
    if (_selectedDetail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 48,
              color: AppColors.textHint.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              '选择一个会话查看详情',
              style: TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final detail = _selectedDetail!;
    return Column(
      children: [
        // Detail header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.chatListBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${detail.messageCount} 条消息 · 创建于 ${_formatDate(DateTime.fromMillisecondsSinceEpoch(detail.createdAt * 1000))}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: '重命名',
                onPressed: () => _renameSession(detail.id, detail.title),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: '删除',
                color: AppColors.error,
                onPressed: () => _deleteSession(detail.id),
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: detail.messages.length,
            itemBuilder: (ctx, i) => _buildMessageBubble(detail.messages[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(sessions_api.SessionMessage msg) {
    final isUser = msg.role == 'user';
    final time = DateTime.fromMillisecondsSinceEpoch(msg.timestamp * 1000);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUser ? Icons.person : Icons.smart_toy,
              size: 18,
              color: isUser ? AppColors.primary : AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isUser ? '你' : 'AI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isUser ? AppColors.primary : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary.withValues(alpha: 0.04)
                        : AppColors.mainBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.chatListBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: SelectableText(
                    msg.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${date.month}/${date.day}';
  }
}
