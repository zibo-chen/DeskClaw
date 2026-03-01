import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/models/models.dart';
import 'package:deskclaw/providers/providers.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/views/chat/message_bubble.dart';
import 'package:deskclaw/views/chat/input_bar.dart';
import 'package:deskclaw/src/rust/api/agent_api.dart' as agent_api;
import 'package:deskclaw/src/rust/api/sessions_api.dart' as sessions_api;

/// Main chat view (right main area in reference)
class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final ScrollController _scrollController = ScrollController();
  DeskClawColors get c => DeskClawColors.of(context);

  static const int _totalSuggestions = 8;
  late List<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    final pool = List<int>.generate(_totalSuggestions, (i) => i)
      ..shuffle(Random());
    _selectedIndices = pool.take(2).toList();
  }

  void _randomizeSuggestions() {
    final pool = List<int>.generate(_totalSuggestions, (i) => i)
      ..shuffle(Random());
    setState(() {
      _selectedIndices = pool.take(2).toList();
    });
  }

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

  /// Only scroll if the given session is the currently active one
  void _scrollToBottomIfActive(String sessionId) {
    if (ref.read(activeSessionIdProvider) == sessionId) {
      _scrollToBottom();
    }
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;

    // Ensure there's an active session
    var sessionId = ref.read(activeSessionIdProvider);
    if (sessionId == null) {
      sessionId = ref.read(sessionsProvider.notifier).createSession();
      ref.read(activeSessionIdProvider.notifier).state = sessionId;
    }

    // Check if THIS session is already processing
    final processingSessions = ref.read(processingSessionsProvider);
    if (processingSessions.contains(sessionId)) return;

    // Add user message
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    // Save current messages to cache before adding (ensures cache is in sync)
    ref.read(messagesProvider.notifier).saveToCache(sessionId);
    ref
        .read(messagesProvider.notifier)
        .addMessageForSession(
          sessionId,
          ref.read(activeSessionIdProvider) ?? '',
          userMsg,
        );
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
    // Mark this session as processing
    ref.read(processingSessionsProvider.notifier).state = {
      ...ref.read(processingSessionsProvider),
      sessionId,
    };

    // Add streaming placeholder to this session
    final assistantMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    ref
        .read(messagesProvider.notifier)
        .addMessageForSession(
          sessionId,
          ref.read(activeSessionIdProvider) ?? '',
          assistantMsg,
        );
    _scrollToBottomIfActive(sessionId);

    try {
      // Get the last user message from this session's cache
      final messagesNotifier = ref.read(messagesProvider.notifier);
      final sessionMessages = messagesNotifier.getCachedMessages(sessionId);
      final lastUserMsg = sessionMessages.lastWhere((m) => m.isUser);

      // Helper to get current active session ID
      String activeId() => ref.read(activeSessionIdProvider) ?? '';

      // Use the streaming API for real-time updates
      final toolCalls = <ToolCallInfo>[];
      final responseBuffer = StringBuffer();

      final stream = agent_api.sendMessageStream(
        sessionId: sessionId,
        message: lastUserMsg.content,
      );

      await for (final event in stream) {
        if (!mounted) break;
        event.when(
          thinking: () {
            if (!mounted) return;
            // Show thinking indicator
            final l10n = AppLocalizations.of(context)!;
            ref
                .read(messagesProvider.notifier)
                .updateAssistantMessageForSession(
                  sessionId,
                  activeId(),
                  l10n.thinking,
                  isStreaming: true,
                );
            _scrollToBottomIfActive(sessionId);
          },
          textDelta: (text) {
            responseBuffer.write(text);
            if (!mounted) return;
            ref
                .read(messagesProvider.notifier)
                .updateAssistantMessageForSession(
                  sessionId,
                  activeId(),
                  responseBuffer.toString(),
                  isStreaming: true,
                  toolCalls: toolCalls.isNotEmpty ? List.from(toolCalls) : null,
                );
            _scrollToBottomIfActive(sessionId);
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
            if (!mounted) return;
            ref
                .read(messagesProvider.notifier)
                .updateAssistantMessageForSession(
                  sessionId,
                  activeId(),
                  responseBuffer.toString(),
                  isStreaming: true,
                  toolCalls: List.from(toolCalls),
                );
            _scrollToBottomIfActive(sessionId);
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
            if (!mounted) return;
            ref
                .read(messagesProvider.notifier)
                .updateAssistantMessageForSession(
                  sessionId,
                  activeId(),
                  responseBuffer.toString(),
                  isStreaming: true,
                  toolCalls: List.from(toolCalls),
                );
            _scrollToBottomIfActive(sessionId);
          },
          messageComplete: (inputTokens, outputTokens) {
            // Message is complete
          },
          error: (message) {
            if (!mounted) return;
            final l10n = AppLocalizations.of(context)!;
            responseBuffer.clear();
            responseBuffer.write(l10n.errorOccurred(message));
          },
        );
      }

      // Mark as complete
      if (mounted) {
        ref
            .read(messagesProvider.notifier)
            .updateAssistantMessageForSession(
              sessionId,
              activeId(),
              responseBuffer.toString(),
              isStreaming: false,
              toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
            );
        ref.read(sessionsProvider.notifier).incrementMessageCount(sessionId);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ref
            .read(messagesProvider.notifier)
            .updateAssistantMessageForSession(
              sessionId,
              ref.read(activeSessionIdProvider) ?? '',
              l10n.errorGeneric(e.toString()),
              isStreaming: false,
            );
      }
    } finally {
      if (mounted) {
        // Remove this session from the processing set
        final current = ref.read(processingSessionsProvider);
        ref.read(processingSessionsProvider.notifier).state = {...current}
          ..remove(sessionId);
        _scrollToBottomIfActive(sessionId);
      }
      _persistCurrentSession(sessionId);
    }
  }

  void _handleSuggestion(String text) {
    _handleSend(text);
  }

  /// Persist the current session & messages to disk via Rust
  Future<void> _persistCurrentSession(String sessionId) async {
    if (!mounted) return;
    try {
      // Use cached messages for the specific session to support background persistence
      final messagesNotifier = ref.read(messagesProvider.notifier);
      final messages = messagesNotifier.getCachedMessages(sessionId);
      final sessions = ref.read(sessionsProvider);
      final session = sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => ChatSession(
          id: sessionId,
          title: 'Chat',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final sessionMessages = messages
          .map(
            (m) => sessions_api.SessionMessage(
              id: m.id,
              role: m.role,
              content: m.content,
              timestamp: m.timestamp.millisecondsSinceEpoch ~/ 1000,
            ),
          )
          .toList();

      await sessions_api.saveSession(
        sessionId: sessionId,
        title: session.title,
        messages: sessionMessages,
      );
    } catch (e) {
      debugPrint('Failed to persist session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    ref.listen(activeSessionIdProvider, (prev, next) {
      if (prev != next) _randomizeSuggestions();
    });
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Top bar
        _buildTopBar(l10n),

        // Main content
        Expanded(
          child: messages.isEmpty
              ? _buildWelcomeView(l10n)
              : _buildMessageList(messages),
        ),

        // Input bar
        ChatInputBar(onSend: _handleSend),
      ],
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: c.surfaceBg,
        border: Border(bottom: BorderSide(color: c.chatListBorder, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            l10n.chatTitle,
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

  Widget _buildWelcomeView(AppLocalizations l10n) {
    final allSuggestions = [
      l10n.suggestionWhatCanYouDo,
      l10n.suggestionWriteArticle,
      l10n.suggestionExplainML,
      l10n.suggestionWriteEmail,
      l10n.suggestionImproveProductivity,
      l10n.suggestionRecommendBooks,
      l10n.suggestionPlanTrip,
      l10n.suggestionBrainstorm,
    ];
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo icon
            _buildWelcomeLogo(),
            const SizedBox(height: 20),

            // Welcome text
            Text(
              l10n.welcomeTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.welcomeSubtitle,
              style: TextStyle(fontSize: 14, color: c.textSecondary),
            ),
            const SizedBox(height: 32),

            // Suggestion cards (2 random from all)
            _buildSuggestionCard(allSuggestions[_selectedIndices[0]]),
            _buildSuggestionCard(allSuggestions[_selectedIndices[1]]),
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
            color: c.textPrimary,
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
              border: Border.all(color: c.chatListBorder),
              color: c.surfaceBg,
            ),
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(fontSize: 14, color: c.textPrimary),
                  ),
                ),
                Icon(Icons.arrow_forward, size: 16, color: c.textHint),
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
