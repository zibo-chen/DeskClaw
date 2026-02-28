import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/constants.dart';
import 'package:deskclaw/models/models.dart';
import 'package:deskclaw/providers/providers.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/views/chat/message_bubble.dart';
import 'package:deskclaw/views/chat/input_bar.dart';
import 'package:deskclaw/src/rust/api/agent_api.dart' as agent_api;

/// Main chat view (right main area in reference)
class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;

    final isProcessing = ref.read(isProcessingProvider);
    if (isProcessing) return;

    // Ensure there's an active session
    var sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) {
      sessionId = ref.read(sessionsProvider.notifier).createSession();
      ref.read(activeSessionIdProvider.notifier).state = sessionId;
    }

    // Add user message
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    ref.read(messagesProvider.notifier).addMessage(userMsg);
    ref.read(sessionsProvider.notifier).incrementMessageCount(sessionId);

    // Update session title from first user message
    final sessions = ref.read(sessionsProvider);
    final session = sessions.firstWhere((s) => s.id == sessionId);
    if (session.messageCount <= 1) {
      final title = text.length > 30 ? '${text.substring(0, 30)}...' : text;
      ref.read(sessionsProvider.notifier).updateSessionTitle(sessionId, title);
    }

    _scrollToBottom();

    // Call the real zeroclaw agent
    _callAgent(sessionId);
  }

  Future<void> _callAgent(String sessionId) async {
    ref.read(isProcessingProvider.notifier).state = true;

    // Add streaming placeholder
    final assistantMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    ref.read(messagesProvider.notifier).addMessage(assistantMsg);
    _scrollToBottom();

    try {
      // Get the last user message
      final messages = ref.read(messagesProvider);
      final lastUserMsg = messages.lastWhere((m) => m.isUser);

      // Use the streaming API for real-time updates
      final toolCalls = <ToolCallInfo>[];
      final responseBuffer = StringBuffer();

      final stream = agent_api.sendMessageStream(
        sessionId: sessionId,
        message: lastUserMsg.content,
      );

      await for (final event in stream) {
        event.when(
          thinking: () {
            // Show thinking indicator
            ref
                .read(messagesProvider.notifier)
                .updateLastAssistantMessage(
                  '💭 Thinking...',
                  isStreaming: true,
                );
            _scrollToBottom();
          },
          textDelta: (text) {
            responseBuffer.write(text);
            ref
                .read(messagesProvider.notifier)
                .updateLastAssistantMessage(
                  responseBuffer.toString(),
                  isStreaming: true,
                  toolCalls: toolCalls.isNotEmpty ? List.from(toolCalls) : null,
                );
            _scrollToBottom();
          },
          toolCallStart: (name, args) {
            toolCalls.add(
              ToolCallInfo(
                id: 'tc_${toolCalls.length}',
                name: name,
                arguments: args,
                status: ToolCallStatus.running,
              ),
            );
            ref
                .read(messagesProvider.notifier)
                .updateLastAssistantMessage(
                  responseBuffer.toString(),
                  isStreaming: true,
                  toolCalls: List.from(toolCalls),
                );
            _scrollToBottom();
          },
          toolCallEnd: (name, result, success) {
            final idx = toolCalls.lastIndexWhere((tc) => tc.name == name);
            if (idx >= 0) {
              toolCalls[idx] = toolCalls[idx].copyWith(
                result: result,
                success: success,
                status: success
                    ? ToolCallStatus.completed
                    : ToolCallStatus.failed,
              );
            }
            ref
                .read(messagesProvider.notifier)
                .updateLastAssistantMessage(
                  responseBuffer.toString(),
                  isStreaming: true,
                  toolCalls: List.from(toolCalls),
                );
            _scrollToBottom();
          },
          messageComplete: (inputTokens, outputTokens) {
            // Message is complete
          },
          error: (message) {
            responseBuffer.clear();
            responseBuffer.write(
              '⚠️ **Error:** $message\n\nPlease check your API key and provider settings.',
            );
          },
        );
      }

      // Mark as complete
      ref
          .read(messagesProvider.notifier)
          .updateLastAssistantMessage(
            responseBuffer.toString(),
            isStreaming: false,
            toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
          );
      ref.read(sessionsProvider.notifier).incrementMessageCount(sessionId);
    } catch (e) {
      ref
          .read(messagesProvider.notifier)
          .updateLastAssistantMessage(
            '⚠️ **Error:** ${e.toString()}\n\nPlease check your settings and try again.',
            isStreaming: false,
          );
    } finally {
      ref.read(isProcessingProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  void _handleSuggestion(String text) {
    _handleSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    ref.watch(activeSessionIdProvider);
    final language = ref.watch(languageProvider);

    return Column(
      children: [
        // Top bar
        _buildTopBar(language),

        // Main content
        Expanded(
          child: messages.isEmpty
              ? _buildWelcomeView()
              : _buildMessageList(messages),
        ),

        // Input bar
        ChatInputBar(onSend: _handleSend),
      ],
    );
  }

  Widget _buildTopBar(String language) {
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
          const Text(
            'Chat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Language selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.chatListBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  language,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo icon
            _buildWelcomeLogo(),
            const SizedBox(height: 20),

            // Welcome text
            const Text(
              AppConstants.welcomeTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppConstants.welcomeSubtitle,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Suggestion cards
            ...AppConstants.defaultSuggestions.map(
              (suggestion) => _buildSuggestionCard(suggestion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeLogo() {
    return Column(
      children: [
        // Three dots on top
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(AppColors.primary, 8),
            const SizedBox(width: 6),
            _buildDot(AppColors.primaryLight, 8),
          ],
        ),
        const SizedBox(height: 8),
        // Main circle
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textPrimary,
          ),
          child: const Icon(Icons.pets, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildSuggestionCard(String suggestion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSuggestion(suggestion),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.chatListBorder),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  }
}
