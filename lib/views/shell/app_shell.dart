import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/providers/providers.dart';
import 'package:deskclaw/views/sidebar/sidebar_nav.dart';
import 'package:deskclaw/views/chat/chat_list_panel.dart';
import 'package:deskclaw/views/chat/chat_view.dart';
import 'package:deskclaw/views/settings/models_page.dart';
import 'package:deskclaw/views/settings/workspace_page.dart';
import 'package:deskclaw/views/settings/configuration_page.dart';
import 'package:deskclaw/views/settings/channels_page.dart';
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
          Expanded(child: _buildMainContent(currentNav)),
        ],
      ),
    );
  }

  Widget _buildMainContent(NavSection section) {
    return switch (section) {
      NavSection.chat => const ChatView(),
      NavSection.models => const ModelsPage(),
      NavSection.channels => const ChannelsPage(),
      NavSection.workspace => const WorkspacePage(),
      NavSection.configuration => const ConfigurationPage(),
      NavSection.sessions => const PlaceholderPage(
        title: 'Sessions',
        icon: Icons.people_outline,
        description: 'View and manage active agent sessions.',
      ),
      NavSection.cronJobs => const PlaceholderPage(
        title: 'Cron Jobs',
        icon: Icons.schedule,
        description: 'Schedule and manage recurring tasks.',
      ),
      NavSection.skills => const PlaceholderPage(
        title: 'Skills',
        icon: Icons.psychology,
        description: 'Manage agent skills and custom prompts.',
      ),
      NavSection.mcp => const PlaceholderPage(
        title: 'MCP',
        icon: Icons.extension,
        description: 'Model Context Protocol server configuration.',
      ),
      NavSection.environments => const PlaceholderPage(
        title: 'Environments',
        icon: Icons.language,
        description: 'Manage environment variables and deployment profiles.',
      ),
    };
  }
}
