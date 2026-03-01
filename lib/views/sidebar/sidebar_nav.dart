import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/constants.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/providers/providers.dart';
import 'package:deskclaw/theme/app_theme.dart';

/// Left sidebar navigation matching the reference design
class SidebarNav extends ConsumerWidget {
  const SidebarNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNav = ref.watch(currentNavProvider);
    final l10n = AppLocalizations.of(context)!;
    final c = DeskClawColors.of(context);

    return Container(
      width: AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: c.sidebarBg,
        border: Border(right: BorderSide(color: c.chatListBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          _buildLogo(c),
          const SizedBox(height: 8),

          // Chat section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavSection(
                    c,
                    icon: Icons.chat_bubble_outline,
                    title: l10n.navSectionChat,
                    isExpanded: true,
                    children: [
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.circle_outlined,
                        label: l10n.navChat,
                        section: NavSection.chat,
                        isActive: currentNav == NavSection.chat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Control section
                  _buildNavSection(
                    c,
                    icon: Icons.wifi_tethering,
                    title: l10n.navSectionControl,
                    isExpanded: true,
                    children: [
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.wifi,
                        label: l10n.navChannels,
                        section: NavSection.channels,
                        isActive: currentNav == NavSection.channels,
                      ),
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.people_outline,
                        label: l10n.navSessions,
                        section: NavSection.sessions,
                        isActive: currentNav == NavSection.sessions,
                      ),
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.schedule,
                        label: l10n.navCronJobs,
                        section: NavSection.cronJobs,
                        isActive: currentNav == NavSection.cronJobs,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Agent section
                  _buildNavSection(
                    c,
                    icon: Icons.auto_awesome,
                    title: l10n.navSectionAgent,
                    isExpanded: true,
                    children: [
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.business,
                        label: l10n.navWorkspace,
                        section: NavSection.workspace,
                        isActive: currentNav == NavSection.workspace,
                      ),
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.menu_book,
                        label: l10n.navKnowledge,
                        section: NavSection.knowledge,
                        isActive: currentNav == NavSection.knowledge,
                      ),
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.psychology,
                        label: l10n.navSkills,
                        section: NavSection.skills,
                        isActive: currentNav == NavSection.skills,
                      ),
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.extension,
                        label: l10n.navMcp,
                        section: NavSection.mcp,
                        isActive: currentNav == NavSection.mcp,
                      ),
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.settings,
                        label: l10n.navConfiguration,
                        section: NavSection.configuration,
                        isActive: currentNav == NavSection.configuration,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Settings section
                  _buildNavSection(
                    c,
                    icon: Icons.settings_outlined,
                    title: l10n.navSectionSettings,
                    isExpanded: true,
                    children: [
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.model_training,
                        label: l10n.navModels,
                        section: NavSection.models,
                        isActive: currentNav == NavSection.models,
                      ),
                      _buildNavItem(
                        c,
                        ref: ref,
                        icon: Icons.language,
                        label: l10n.navEnvironments,
                        section: NavSection.environments,
                        isActive: currentNav == NavSection.environments,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar: language toggle + theme toggle
          _buildBottomBar(context, ref, l10n, c),
        ],
      ),
    );
  }

  Widget _buildLogo(DeskClawColors c) {
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
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                AppConstants.appVersion,
                style: TextStyle(fontSize: 11, color: c.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavSection(
    DeskClawColors c, {
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
              Icon(icon, size: 16, color: c.sidebarSection),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.sidebarSection,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: c.sidebarSection,
              ),
            ],
          ),
        ),
        if (isExpanded) ...children,
      ],
    );
  }

  Widget _buildNavItem(
    DeskClawColors c, {
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
              color: isActive ? c.sidebarActiveBg : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? c.sidebarActiveText : c.sidebarText,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? c.sidebarActiveText : c.sidebarText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DeskClawColors c,
  ) {
    final locale = ref.watch(localeProvider);
    final isZh = locale.languageCode == 'zh';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.chatListBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language toggle
          Row(
            children: [
              Icon(Icons.language, size: 16, color: c.sidebarText),
              const SizedBox(width: 8),
              _buildLangChip(
                c,
                label: 'EN',
                selected: !isZh,
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('en');
                },
              ),
              const SizedBox(width: 4),
              _buildLangChip(
                c,
                label: '中文',
                selected: isZh,
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('zh');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Theme toggle
          _buildThemeToggle(context, ref, c),
        ],
      ),
    );
  }

  Widget _buildLangChip(
    DeskClawColors c, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : c.chatListBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c.sidebarText,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    WidgetRef ref,
    DeskClawColors c,
  ) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return InkWell(
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
            color: c.sidebarText,
          ),
          const SizedBox(width: 10),
          Text(
            isDark
                ? AppLocalizations.of(context)!.darkMode
                : AppLocalizations.of(context)!.lightMode,
            style: TextStyle(fontSize: 13, color: c.sidebarText),
          ),
        ],
      ),
    );
  }
}
