import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coraldesk/constants.dart';
import 'package:coraldesk/l10n/app_localizations.dart';
import 'package:coraldesk/providers/providers.dart';
import 'package:coraldesk/services/update_service.dart';
import 'package:coraldesk/theme/app_theme.dart';
import 'package:coraldesk/views/settings/widgets/settings_scaffold.dart';

/// Application preferences page — language, theme, shortcuts, etc.
class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsScaffold(
      title: l10n.appSettingsTitle,
      icon: Icons.tune_rounded,
      isLoading: false,
      body: _AppSettingsBody(),
    );
  }
}

class _AppSettingsBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppSettingsBody> createState() => _AppSettingsBodyState();
}

class _AppSettingsBodyState extends ConsumerState<_AppSettingsBody> {
  bool _isCheckingUpdate = false;
  UpdateCheckResult? _updateResult;

  Future<void> _checkForUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateResult = null;
    });
    final result = await UpdateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        _updateResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = CoralDeskColors.of(context);
    final localeSetting = ref.watch(localeSettingProvider);
    final themeSetting = ref.watch(themeSettingProvider);
    final sendShortcut = ref.watch(sendShortcutProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Appearance Section ──
              _SectionHeader(
                icon: Icons.palette_outlined,
                title: l10n.settingSectionAppearance,
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _DropdownSettingTile<String>(
                    icon: Icons.language_rounded,
                    title: l10n.settingLanguage,
                    subtitle: l10n.settingLanguageDesc,
                    value: localeSetting,
                    items: [
                      _DropdownItem(
                        value: 'system',
                        label: l10n.followSystem,
                        icon: Icons.devices_rounded,
                      ),
                      _DropdownItem(
                        value: 'en',
                        label: l10n.english,
                        icon: null,
                      ),
                      _DropdownItem(
                        value: 'zh',
                        label: l10n.chinese,
                        icon: null,
                      ),
                    ],
                    onChanged: (v) {
                      ref.read(localeSettingProvider.notifier).state = v;
                    },
                  ),
                  _divider(c),
                  _DropdownSettingTile<String>(
                    icon: Icons.contrast_rounded,
                    title: l10n.settingTheme,
                    subtitle: l10n.settingThemeDesc,
                    value: themeSetting,
                    items: [
                      _DropdownItem(
                        value: 'system',
                        label: l10n.followSystem,
                        icon: Icons.devices_rounded,
                      ),
                      _DropdownItem(
                        value: 'light',
                        label: l10n.themeLight,
                        icon: Icons.light_mode_rounded,
                      ),
                      _DropdownItem(
                        value: 'dark',
                        label: l10n.themeDark,
                        icon: Icons.dark_mode_rounded,
                      ),
                    ],
                    onChanged: (v) {
                      ref.read(themeSettingProvider.notifier).state = v;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── General Section ──
              _SectionHeader(
                icon: Icons.settings_outlined,
                title: l10n.settingSectionGeneral,
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _DropdownSettingTile<String>(
                    icon: Icons.send_rounded,
                    title: l10n.settingSendShortcut,
                    subtitle: l10n.settingSendShortcutDesc,
                    value: sendShortcut,
                    items: [
                      _DropdownItem(
                        value: 'enter',
                        label: l10n.sendByEnter,
                        icon: Icons.keyboard_return_rounded,
                      ),
                      _DropdownItem(
                        value: 'ctrlEnter',
                        label: l10n.sendByCtrlEnter,
                        icon: Icons.keyboard_rounded,
                      ),
                    ],
                    onChanged: (v) {
                      ref.read(sendShortcutProvider.notifier).state = v;
                    },
                  ),
                  _divider(c),
                  _DropdownSettingTile<String>(
                    icon: Icons.view_sidebar_rounded,
                    title: l10n.settingSidebarDefault,
                    subtitle: l10n.settingSidebarDefaultDesc,
                    value: ref.watch(sidebarCollapsedProvider)
                        ? 'collapsed'
                        : 'expanded',
                    items: [
                      _DropdownItem(
                        value: 'expanded',
                        label: l10n.sidebarExpanded,
                        icon: Icons.menu_open_rounded,
                      ),
                      _DropdownItem(
                        value: 'collapsed',
                        label: l10n.sidebarCollapsed,
                        icon: Icons.menu_rounded,
                      ),
                    ],
                    onChanged: (v) {
                      ref.read(sidebarCollapsedProvider.notifier).state =
                          v == 'collapsed';
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── About Section ──
              _SectionHeader(
                icon: Icons.info_outline_rounded,
                title: l10n.settingSectionAbout,
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _InfoTile(
                    icon: Icons.tag_rounded,
                    title: l10n.aboutVersion,
                    trailing: Text(
                      AppConstants.appVersion,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _divider(c),
                  _InfoTile(
                    icon: Icons.code_rounded,
                    title: l10n.aboutBuildWith,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flutter_dash,
                          size: 18,
                          color: const Color(0xFF54C5F8),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.memory_rounded,
                          size: 18,
                          color: const Color(0xFFDEA584),
                        ),
                      ],
                    ),
                  ),
                  _divider(c),
                  _ActionTile(
                    icon: Icons.system_update_rounded,
                    title: l10n.aboutCheckUpdate,
                    subtitle: _updateResult != null
                        ? (_updateResult!.error != null
                              ? l10n.aboutUpdateError
                              : _updateResult!.hasUpdate
                              ? l10n.aboutUpdateAvailable(
                                  _updateResult!.latestVersion!,
                                )
                              : l10n.aboutUpdateCurrent)
                        : l10n.aboutCheckUpdateDesc,
                    subtitleColor: _updateResult != null
                        ? (_updateResult!.error != null
                              ? Colors.red
                              : _updateResult!.hasUpdate
                              ? Colors.orange
                              : Colors.green)
                        : null,
                    trailing: _isCheckingUpdate
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _updateResult?.hasUpdate == true
                        ? TextButton.icon(
                            onPressed: () {
                              launchUrl(Uri.parse(_updateResult!.releaseUrl!));
                            },
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: Text(l10n.aboutUpdateDownload),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : _SmallOutlinedButton(
                            onPressed: _checkForUpdate,
                            colors: c,
                          ),
                  ),
                  _divider(c),
                  _ActionTile(
                    icon: Icons.open_in_new_rounded,
                    title: l10n.aboutGitHub,
                    subtitle: l10n.aboutGitHubDesc,
                    onTap: () => launchUrl(Uri.parse(AppConstants.githubUrl)),
                  ),
                  _divider(c),
                  _ActionTile(
                    icon: Icons.description_outlined,
                    title: l10n.aboutLicense,
                    subtitle: AppConstants.licenseShort,
                    onTap: () => launchUrl(Uri.parse(AppConstants.licenseUrl)),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ────────────────────────────────────────

Widget _divider(CoralDeskColors c) {
  return Divider(
    height: 1,
    thickness: 1,
    color: c.chatListBorder.withValues(alpha: 0.5),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = CoralDeskColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = CoralDeskColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.chatListBorder.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _DropdownItem<T> {
  const _DropdownItem({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

class _DropdownSettingTile<T> extends StatelessWidget {
  const _DropdownSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final List<_DropdownItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = CoralDeskColors.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find current item label
    final currentItem = items.firstWhere(
      (i) => i.value == value,
      orElse: () => items.first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Dropdown button — custom styled
          _StyledDropdown<T>(
            value: value,
            currentLabel: currentItem.label,
            currentIcon: currentItem.icon,
            items: items,
            onChanged: onChanged,
            isDark: isDark,
            colors: c,
          ),
        ],
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.currentLabel,
    this.currentIcon,
    required this.items,
    required this.onChanged,
    required this.isDark,
    required this.colors,
  });

  final T value;
  final String currentLabel;
  final IconData? currentIcon;
  final List<_DropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final bool isDark;
  final CoralDeskColors colors;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: colors.cardBg,
      elevation: 8,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.chatListBorder.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentIcon != null) ...[
              Icon(currentIcon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              currentLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => items.map((item) {
        final isSelected = item.value == value;
        return PopupMenuItem<T>(
          value: item.value,
          height: 40,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 16,
                  color: isSelected ? AppColors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 8),
              ] else
                const SizedBox(width: 24),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : colors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });
  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final c = CoralDeskColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// A tappable tile with icon, title, subtitle, and optional custom trailing widget.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = CoralDeskColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor ?? c.textSecondary,
                      fontWeight: subtitleColor != null
                          ? FontWeight.w500
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: c.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Small outlined "check" button for the update row.
class _SmallOutlinedButton extends StatelessWidget {
  const _SmallOutlinedButton({required this.onPressed, required this.colors});
  final VoidCallback onPressed;
  final CoralDeskColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 14),
            const SizedBox(width: 4),
            Text(AppLocalizations.of(context)!.aboutCheckUpdate),
          ],
        ),
      ),
    );
  }
}
