import 'package:flutter/material.dart';
import 'package:coraldesk/theme/app_theme.dart';

/// A wide desktop-optimised dialog shell that replaces the standard
/// [AlertDialog] for settings/configuration forms.
///
/// Features:
///  - Wider max-width (default 720 px) to take advantage of wide screens
///  - Custom title bar with optional icon
///  - Themed background, border-radius, and consistent padding
///  - Scrollable content area with proper max-height
///  - Sticky action buttons
class DesktopDialog extends StatelessWidget {
  const DesktopDialog({
    super.key,
    required this.title,
    this.icon,
    required this.content,
    required this.actions,
    this.width = 720,
    this.maxHeight,
  });

  final String title;
  final IconData? icon;
  final Widget content;
  final List<Widget> actions;
  final double width;

  /// If null, the dialog takes up to 85 % of the viewport height.
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final c = CoralDeskColors.of(context);
    final mq = MediaQuery.of(context);
    final effectiveMaxH = maxHeight ?? mq.size.height * 0.85;

    return Dialog(
      backgroundColor: c.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: effectiveMaxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: c.chatListBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  // Close button
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: c.textHint),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: content,
              ),
            ),

            // ── Action bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.chatListBorder, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    actions[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Section header — groups related fields visually
// ──────────────────────────────────────────────────────────────

class DialogSection extends StatelessWidget {
  const DialogSection({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    required this.children,
    this.padding = const EdgeInsets.only(bottom: 20),
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = CoralDeskColors.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  FieldRow — places 2-3 fields side by side
// ──────────────────────────────────────────────────────────────

class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.children, this.spacing = 16});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  FieldColumn — single field with bottom margin
// ──────────────────────────────────────────────────────────────

class FieldColumn extends StatelessWidget {
  const FieldColumn({super.key, required this.child, this.bottomMargin = 14});

  final Widget child;
  final double bottomMargin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomMargin),
      child: child,
    );
  }
}
