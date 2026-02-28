import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/constants.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/providers/providers.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/agent_api.dart' as agent_api;

/// Chat session list panel (middle panel in reference)
class ChatListPanel extends ConsumerWidget {
  const ChatListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final activeId = ref.watch(activeSessionIdProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: AppConstants.chatListWidth,
      decoration: const BoxDecoration(
        color: AppColors.chatListBg,
        border: Border(
          right: BorderSide(color: AppColors.chatListBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              children: [
                Text(
                  l10n.workWithDeskClaw,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_all, size: 18),
                  color: AppColors.textHint,
                  onPressed: () {},
                  tooltip: l10n.tooltipCopy,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // New Chat button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final id = ref
                      .read(sessionsProvider.notifier)
                      .createSession();
                  ref.read(activeSessionIdProvider.notifier).state = id;
                  ref.read(messagesProvider.notifier).clear();
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  l10n.newChat,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Session list
          Expanded(
            child: sessions.isEmpty
                ? _buildEmptyState(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isActive = session.id == activeId;
                      return _ChatSessionTile(
                        session: session,
                        isActive: isActive,
                        onTap: () {
                          ref.read(activeSessionIdProvider.notifier).state =
                              session.id;
                          // Switch Rust-side agent session
                          agent_api.switchSession(sessionId: session.id);
                        },
                        onDelete: () {
                          ref
                              .read(sessionsProvider.notifier)
                              .deleteSession(session.id);
                          if (isActive) {
                            ref.read(activeSessionIdProvider.notifier).state =
                                null;
                            ref.read(messagesProvider.notifier).clear();
                            // Clear Rust-side agent session
                            agent_api.clearSession();
                          }
                        },
                      );
                    },
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
          const Icon(
            Icons.chat_bubble_outline,
            size: 40,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noConversationsYet,
            style: const TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.startNewChat,
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChatSessionTile extends StatefulWidget {
  final dynamic session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatSessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ChatSessionTile> createState() => _ChatSessionTileState();
}

class _ChatSessionTileState extends State<_ChatSessionTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: widget.isActive
                    ? AppColors.sidebarActiveBg
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: widget.isActive
                        ? AppColors.sidebarActiveText
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isActive
                            ? AppColors.sidebarActiveText
                            : AppColors.textPrimary,
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (_hovering)
                    InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(4),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.textHint,
                      ),
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
