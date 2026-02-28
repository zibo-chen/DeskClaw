import 'package:flutter/material.dart';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(icon: Icons.pets, bgColor: AppColors.textPrimary),
          const SizedBox(width: 8),
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  16,
                ).copyWith(bottomLeft: const Radius.circular(4)),
                border: Border.all(color: AppColors.chatListBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tool calls if any
                  if (message.toolCalls != null) ...[
                    for (final tc in message.toolCalls!) _buildToolCallCard(tc),
                    const SizedBox(height: 8),
                  ],

                  // Message content
                  if (message.content.isNotEmpty)
                    MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                        code: TextStyle(
                          fontSize: 13,
                          backgroundColor: AppColors.inputBg,
                          color: AppColors.primaryDark,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        strong: const TextStyle(fontWeight: FontWeight.w600),
                        listBullet: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
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

  Widget _buildToolCallCard(ToolCallInfo toolCall) {
    final statusColor = switch (toolCall.status) {
      ToolCallStatus.pending => AppColors.textHint,
      ToolCallStatus.running => AppColors.warning,
      ToolCallStatus.completed => AppColors.success,
      ToolCallStatus.failed => AppColors.error,
    };

    final statusIcon = switch (toolCall.status) {
      ToolCallStatus.pending => Icons.hourglass_empty,
      ToolCallStatus.running => Icons.sync,
      ToolCallStatus.completed => Icons.check_circle,
      ToolCallStatus.failed => Icons.error,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.chatListBorder),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Icon(Icons.build, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            toolCall.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (toolCall.result != null) ...[
            const Spacer(),
            Text(
              toolCall.success == true ? 'Success' : 'Failed',
              style: TextStyle(fontSize: 12, color: statusColor),
            ),
          ],
        ],
      ),
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
