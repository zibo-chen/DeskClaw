import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/providers/providers.dart';
import 'package:deskclaw/views/sidebar/sidebar_nav.dart';
import 'package:deskclaw/views/chat/chat_list_panel.dart';
import 'package:deskclaw/views/chat/chat_view.dart';
import 'package:deskclaw/views/settings/models_page.dart';
import 'package:deskclaw/views/settings/workspace_page.dart';
import 'package:deskclaw/views/settings/configuration_page.dart';
import 'package:deskclaw/views/settings/channels_page.dart';
import 'package:deskclaw/views/settings/skills_page.dart';
import 'package:deskclaw/views/settings/tools_page.dart';
import 'package:deskclaw/views/settings/agents_page.dart';
import 'package:deskclaw/views/settings/sessions_page.dart';
import 'package:deskclaw/views/settings/cron_jobs_page.dart';
import 'package:deskclaw/views/settings/knowledge_page.dart';
import 'package:deskclaw/views/placeholder_page.dart';

/// Root layout shell: Sidebar | Chat List (when in chat) | Main Content
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Load persisted sessions from Rust store on startup
    Future.microtask(() {
      ref.read(sessionsProvider.notifier).loadPersistedSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentNav = ref.watch(currentNavProvider);
    final isChatSection = currentNav == NavSection.chat;
    final isCollapsed = ref.watch(chatListCollapsedProvider);
    final showChatList = isChatSection && !isCollapsed;

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar navigation
          const SidebarNav(),

          // Chat list panel (only visible in Chat section & not collapsed)
          if (showChatList) const ChatListPanel(),

          // Main content area
          Expanded(child: _buildMainContent(context, currentNav)),
        ],
      ),
    );
  }

  static Widget _buildMainContent(BuildContext context, NavSection section) {
    return switch (section) {
      NavSection.chat => const ChatView(),
      NavSection.models => const ModelsPage(),
      NavSection.channels => const ChannelsPage(),
      NavSection.workspace => const WorkspacePage(),
      NavSection.configuration => const ConfigurationPage(),
      NavSection.sessions => const SessionsPage(),
      NavSection.cronJobs => const CronJobsPage(),
      NavSection.knowledge => const KnowledgePage(),
      NavSection.skills => const SkillsPage(),
      NavSection.mcp => const ToolsPage(),
      NavSection.agents => const AgentsPage(),
      NavSection.environments => PlaceholderPage(
        title: AppLocalizations.of(context)!.pageEnvironments,
        icon: Icons.language,
        description: AppLocalizations.of(context)!.environmentsDescription,
      ),
    };
  }
}
