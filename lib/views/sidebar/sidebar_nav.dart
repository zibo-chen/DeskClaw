import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/constants.dart';
import 'package:deskclaw/providers/providers.dart';
import 'package:deskclaw/theme/app_theme.dart';

/// Left sidebar navigation matching the reference design
class SidebarNav extends ConsumerWidget {
  const SidebarNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNav = ref.watch(currentNavProvider);

    return Container(
      width: AppConstants.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          right: BorderSide(color: AppColors.chatListBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          _buildLogo(),
          const SizedBox(height: 8),

          // Chat section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavSection(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    isExpanded: true,
                    children: [
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.circle_outlined,
                        label: 'Chat',
                        section: NavSection.chat,
                        isActive: currentNav == NavSection.chat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Control section
                  _buildNavSection(
                    icon: Icons.wifi_tethering,
                    title: 'Control',
                    isExpanded: true,
                    children: [
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.wifi,
                        label: 'Channels',
                        section: NavSection.channels,
                        isActive: currentNav == NavSection.channels,
                      ),
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.people_outline,
                        label: 'Sessions',
                        section: NavSection.sessions,
                        isActive: currentNav == NavSection.sessions,
                      ),
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.schedule,
                        label: 'Cron Jobs',
                        section: NavSection.cronJobs,
                        isActive: currentNav == NavSection.cronJobs,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Agent section
                  _buildNavSection(
                    icon: Icons.auto_awesome,
                    title: 'Agent',
                    isExpanded: true,
                    children: [
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.business,
                        label: 'Workspace',
                        section: NavSection.workspace,
                        isActive: currentNav == NavSection.workspace,
                      ),
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.psychology,
                        label: 'Skills',
                        section: NavSection.skills,
                        isActive: currentNav == NavSection.skills,
                      ),
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.extension,
                        label: 'MCP',
                        section: NavSection.mcp,
                        isActive: currentNav == NavSection.mcp,
                      ),
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.settings,
                        label: 'Configuration',
                        section: NavSection.configuration,
                        isActive: currentNav == NavSection.configuration,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Settings section
                  _buildNavSection(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    isExpanded: true,
                    children: [
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.model_training,
                        label: 'Models',
                        section: NavSection.models,
                        isActive: currentNav == NavSection.models,
                      ),
                      _buildNavItem(
                        ref: ref,
                        icon: Icons.language,
                        label: 'Environments',
                        section: NavSection.environments,
                        isActive: currentNav == NavSection.environments,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Theme toggle at bottom
          _buildThemeToggle(ref),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          // Logo icon - claw paw
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                AppConstants.appVersion,
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavSection({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.sidebarSection),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sidebarSection,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: AppColors.sidebarSection,
              ),
            ],
          ),
        ),
        if (isExpanded) ...children,
      ],
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required NavSection section,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            ref.read(currentNavProvider.notifier).state = section;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isActive ? AppColors.sidebarActiveBg : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? AppColors.sidebarActiveText
                      : AppColors.sidebarText,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.sidebarActiveText
                        : AppColors.sidebarText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.chatListBorder, width: 1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ref.read(themeModeProvider.notifier).state = isDark
              ? ThemeMode.light
              : ThemeMode.dark;
        },
        child: Row(
          children: [
            Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 18,
              color: AppColors.sidebarText,
            ),
            const SizedBox(width: 10),
            Text(
              isDark ? 'Dark Mode' : 'Light Mode',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.sidebarText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
