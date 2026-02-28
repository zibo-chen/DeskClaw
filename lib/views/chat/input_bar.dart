import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/constants.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/providers/providers.dart';
import 'package:deskclaw/theme/app_theme.dart';

/// Chat input bar at the bottom of the chat view
class ChatInputBar extends ConsumerStatefulWidget {
  final Function(String) onSend;

  const ChatInputBar({super.key, required this.onSend});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  DeskClawColors get c => DeskClawColors.of(context);
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(isCurrentSessionProcessingProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(40, 8, 40, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(
              minHeight: 56,
              maxHeight: _isExpanded ? 200 : 120,
            ),
            decoration: BoxDecoration(
              color: c.surfaceBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.chatListBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      // Enter to send, Shift+Enter for newline
                      // Skip if IME is composing (e.g. pinyin input)
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed &&
                          !_controller.value.composing.isValid) {
                        _send();
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      maxLength: AppConstants.maxInputLength,
                      enabled: !isProcessing,
                      decoration: InputDecoration(
                        hintText: isProcessing
                            ? l10n.processing
                            : l10n.typeYourMessage,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          8,
                        ),
                        counterText: '',
                        filled: false,
                        hintStyle: TextStyle(color: c.textHint, fontSize: 14),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: c.textPrimary,
                        height: 1.5,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),
                // Bottom toolbar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      // Expand button
                      IconButton(
                        icon: Icon(
                          _isExpanded
                              ? Icons.close_fullscreen
                              : Icons.open_in_full,
                          size: 16,
                        ),
                        color: c.textHint,
                        onPressed: () {
                          setState(() => _isExpanded = !_isExpanded);
                        },
                        tooltip: _isExpanded ? l10n.collapse : l10n.expand,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      const Spacer(),
                      // Character count
                      Text(
                        '${_controller.text.length}/${AppConstants.maxInputLength}',
                        style: TextStyle(fontSize: 12, color: c.textHint),
                      ),
                      const SizedBox(width: 12),
                      // Send button
                      InkWell(
                        onTap:
                            _controller.text.trim().isNotEmpty && !isProcessing
                            ? _send
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color:
                                _controller.text.trim().isNotEmpty &&
                                    !isProcessing
                                ? AppColors.primary
                                : c.inputBg,
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color:
                                _controller.text.trim().isNotEmpty &&
                                    !isProcessing
                                ? Colors.white
                                : c.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tagline
          Text(
            l10n.appTagline,
            style: TextStyle(fontSize: 12, color: c.textHint),
          ),
        ],
      ),
    );
  }
}
