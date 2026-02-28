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
import 'package:deskclaw/views/settings/sessions_page.dart';
import 'package:deskclaw/views/settings/cron_jobs_page.dart';
import 'package:deskclaw/views/placeholder_page.dart';

/// Root layout shell: Sidebar | Chat List (when in chat) | Main Content
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNav = ref.watch(currentNavProvider);
    final showChatList = currentNav == NavSection.chat;

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar navigation
          const SidebarNav(),

          // Chat list panel (only visible in Chat section)
          if (showChatList) const ChatListPanel(),

          // Main content area
          Expanded(child: _buildMainContent(context, currentNav)),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, NavSection section) {
    return switch (section) {
      NavSection.chat => const ChatView(),
      NavSection.models => const ModelsPage(),
      NavSection.channels => const ChannelsPage(),
      NavSection.workspace => const WorkspacePage(),
      NavSection.configuration => const ConfigurationPage(),
      NavSection.sessions => const SessionsPage(),
      NavSection.cronJobs => const CronJobsPage(),
      NavSection.skills => const SkillsPage(),
      NavSection.mcp => const ToolsPage(),
      NavSection.environments => PlaceholderPage(
        title: AppLocalizations.of(context)!.pageEnvironments,
        icon: Icons.language,
        description: AppLocalizations.of(context)!.environmentsDescription,
      ),
    };
  }
}
