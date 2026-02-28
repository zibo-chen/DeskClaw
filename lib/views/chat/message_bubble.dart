import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:deskclaw/models/models.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Individual message bubble
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    }
    return _buildAssistantBubble(context);
  }

  Widget _buildUserBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(
                  16,
                ).copyWith(bottomRight: const Radius.circular(4)),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildAvatar(icon: Icons.person, bgColor: AppColors.primaryLight),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    final c = DeskClawColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(icon: Icons.pets, bgColor: c.textPrimary),
          const SizedBox(width: 8),
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.surfaceBg,
                borderRadius: BorderRadius.circular(
                  16,
                ).copyWith(bottomLeft: const Radius.circular(4)),
                border: Border.all(color: c.chatListBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tool calls if any (expandable)
                  if (message.toolCalls != null) ...[
                    for (final tc in message.toolCalls!)
                      _ToolCallCard(toolCall: tc),
                    const SizedBox(height: 8),
                  ],

                  // Message content
                  if (message.content.isNotEmpty)
                    MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: c.textPrimary,
                        ),
                        code: TextStyle(
                          fontSize: 13,
                          backgroundColor: c.inputBg,
                          color: AppColors.primaryDark,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: c.inputBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        strong: const TextStyle(fontWeight: FontWeight.w600),
                        listBullet: TextStyle(
                          fontSize: 14,
                          color: c.textPrimary,
                        ),
                      ),
                      selectable: true,
                    ),

                  // Streaming indicator
                  if (message.isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildStreamingDots(),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildAvatar({required IconData icon, required Color bgColor}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }

  Widget _buildStreamingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(0),
        const SizedBox(width: 4),
        _dot(1),
        const SizedBox(width: 4),
        _dot(2),
      ],
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}

/// Expandable tool call card showing name, status, arguments, and result
class _ToolCallCard extends StatefulWidget {
  final ToolCallInfo toolCall;

  const _ToolCallCard({required this.toolCall});

  @override
  State<_ToolCallCard> createState() => _ToolCallCardState();
}

class _ToolCallCardState extends State<_ToolCallCard> {
  bool _expanded = false;

  ToolCallInfo get toolCall => widget.toolCall;

  Color _statusColor(DeskClawColors c) => switch (toolCall.status) {
    ToolCallStatus.pending => c.textHint,
    ToolCallStatus.running => AppColors.warning,
    ToolCallStatus.completed => AppColors.success,
    ToolCallStatus.failed => AppColors.error,
  };

  IconData get _statusIcon => switch (toolCall.status) {
    ToolCallStatus.pending => Icons.hourglass_empty,
    ToolCallStatus.running => Icons.sync,
    ToolCallStatus.completed => Icons.check_circle,
    ToolCallStatus.failed => Icons.error,
  };

  /// Try to pretty-print JSON, fall back to raw string
  String _formatJson(String raw) {
    try {
      final obj = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DeskClawColors.of(context);
    final statusColor = _statusColor(c);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.chatListBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — always visible, clickable
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(_statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Icon(Icons.build, size: 14, color: c.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      toolCall.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (toolCall.result != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        toolCall.success == true
                            ? AppLocalizations.of(context)!.toolCallSuccess
                            : AppLocalizations.of(context)!.toolCallFailed,
                        style: TextStyle(fontSize: 12, color: statusColor),
                      ),
                    ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 18, color: c.textHint),
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetails(c),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(DeskClawColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Arguments section
          if (toolCall.arguments.isNotEmpty) ...[
            _buildSectionHeader(c, 'Arguments'),
            const SizedBox(height: 4),
            _buildCodeBlock(c, _formatJson(toolCall.arguments)),
          ],

          // Result section
          if (toolCall.result != null && toolCall.result!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionHeader(c, 'Result'),
            const SizedBox(height: 4),
            _buildCodeBlock(c, toolCall.result!),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(DeskClawColors c, String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        // Copy button
        SizedBox(
          height: 22,
          width: 22,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 14,
            icon: Icon(Icons.copy, color: c.textHint),
            tooltip: title == 'Arguments' ? 'Copy arguments' : 'Copy result',
            onPressed: () {
              final text = title == 'Arguments'
                  ? _formatJson(toolCall.arguments)
                  : toolCall.result ?? '';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBlock(DeskClawColors c, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: c.mainBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.chatListBorder),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          content,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            height: 1.5,
            color: c.textPrimary,
          ),
        ),
      ),
    );
  }
}
