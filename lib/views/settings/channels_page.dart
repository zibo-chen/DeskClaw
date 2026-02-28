import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/workspace_api.dart' as ws_api;

/// Channels configuration page — shows all available communication channels
class ChannelsPage extends ConsumerStatefulWidget {
  const ChannelsPage({super.key});

  @override
  ConsumerState<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends ConsumerState<ChannelsPage> {
  List<ws_api.ChannelSummary>? _channels;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    final channels = await ws_api.listChannels();
    if (mounted) {
      setState(() {
        _channels = channels;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.chatListBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          const Text(
            'Channels',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (_channels != null)
            Text(
              '${_channels!.where((c) => c.enabled).length} active',
              style: const TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final channels = _channels;
    if (channels == null || channels.isEmpty) {
      return const Center(
        child: Text(
          'No channels configured.\nEdit ~/.zeroclaw/config.toml to add channels.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enabled channels
          _buildSection(
            'Active Channels',
            channels.where((c) => c.enabled).toList(),
          ),
          const SizedBox(height: 24),
          // Available channels
          _buildSection(
            'Available Channels',
            channels.where((c) => !c.enabled).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<ws_api.ChannelSummary> channels) {
    if (channels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...channels.map(_buildChannelCard),
      ],
    );
  }

  Widget _buildChannelCard(ws_api.ChannelSummary channel) {
    final icon = _channelIcon(channel.channelType);
    final color = channel.enabled ? AppColors.primary : AppColors.textHint;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: channel.enabled
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.chatListBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  channel.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: channel.enabled
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
            ),
            child: Text(
              channel.enabled ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: channel.enabled
                    ? Colors.green.shade700
                    : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _channelIcon(String type) {
    return switch (type) {
      'cli' => Icons.terminal,
      'telegram' => Icons.send,
      'discord' => Icons.headset_mic,
      'slack' => Icons.tag,
      'matrix' => Icons.grid_on,
      'webhook' => Icons.webhook,
      'email' => Icons.email_outlined,
      'lark' => Icons.flight,
      'dingtalk' => Icons.notifications_active,
      'whatsapp' => Icons.chat,
      'signal' => Icons.security,
      'irc' => Icons.forum,
      _ => Icons.wifi,
    };
  }
}
