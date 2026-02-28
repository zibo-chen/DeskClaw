import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/models/models.dart';
import 'package:deskclaw/src/rust/api/agent_api.dart' as agent_api;
import 'package:deskclaw/src/rust/api/config_api.dart' as config_api;

/// Navigation section for sidebar
enum NavSection {
  chat,
  channels,
  sessions,
  cronJobs,
  workspace,
  skills,
  mcp,
  configuration,
  models,
  environments,
}

/// Current navigation state
final currentNavProvider = StateProvider<NavSection>((ref) => NavSection.chat);

/// Current active session ID
final activeSessionIdProvider = StateProvider<String?>((ref) => null);

/// Runtime status
final runtimeStatusProvider = FutureProvider<agent_api.RuntimeStatus>((
  ref,
) async {
  return await agent_api.getRuntimeStatus();
});

/// Current config from Rust
final configProvider = FutureProvider<config_api.AppConfig>((ref) async {
  return await config_api.loadConfig();
});

/// All chat sessions
final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, List<ChatSession>>((ref) {
      return SessionsNotifier();
    });

class SessionsNotifier extends StateNotifier<List<ChatSession>> {
  SessionsNotifier() : super([]);

  String createSession() {
    final now = DateTime.now();
    final id = 'session_${now.millisecondsSinceEpoch}';
    final session = ChatSession(
      id: id,
      title: 'New Chat',
      createdAt: now,
      updatedAt: now,
    );
    state = [session, ...state];
    return id;
  }

  void updateSessionTitle(String id, String title) {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(title: title, updatedAt: DateTime.now());
      }
      return s;
    }).toList();
  }

  void deleteSession(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  void incrementMessageCount(String id) {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(
          messageCount: s.messageCount + 1,
          updatedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();
  }
}

/// Messages for the active session
final messagesProvider =
    StateNotifierProvider<MessagesNotifier, List<ChatMessage>>((ref) {
      return MessagesNotifier();
    });

class MessagesNotifier extends StateNotifier<List<ChatMessage>> {
  MessagesNotifier() : super([]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void updateLastAssistantMessage(
    String content, {
    bool? isStreaming,
    List<ToolCallInfo>? toolCalls,
  }) {
    if (state.isEmpty) return;
    final last = state.last;
    if (last.isAssistant) {
      state = [
        ...state.sublist(0, state.length - 1),
        last.copyWith(
          content: content,
          isStreaming: isStreaming ?? last.isStreaming,
          toolCalls: toolCalls ?? last.toolCalls,
        ),
      ];
    }
  }

  void clear() {
    state = [];
  }
}

/// Whether the agent is currently processing
final isProcessingProvider = StateProvider<bool>((ref) => false);

/// Language setting
final languageProvider = StateProvider<String>((ref) => 'English');

/// Theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
