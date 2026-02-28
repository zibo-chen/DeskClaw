import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/skills_api.dart' as skills_api;

/// Skills management page - browse, enable/disable skills
class SkillsPage extends ConsumerStatefulWidget {
  const SkillsPage({super.key});

  @override
  ConsumerState<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends ConsumerState<SkillsPage> {
  skills_api.SkillsConfigDto? _config;
  List<skills_api.SkillDto> _skills = [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final config = await skills_api.getSkillsConfig();
    final skills = await skills_api.listSkills();
    if (mounted) {
      setState(() {
        _config = config;
        _skills = skills;
        _loading = false;
      });
    }
  }

  Future<void> _toggleOpenSkills(bool enabled) async {
    final result = await skills_api.toggleOpenSkills(enabled: enabled);
    if (result == 'ok') {
      _showMessage('社区技能已${enabled ? '启用' : '停用'}');
      _loadAll();
    } else {
      _showMessage('操作失败: $result');
    }
  }

  Future<void> _updateInjectionMode(String mode) async {
    final result = await skills_api.updatePromptInjectionMode(mode: mode);
    if (result == 'ok') {
      _showMessage('注入模式已更新为 $mode');
      _loadAll();
    } else {
      _showMessage('操作失败: $result');
    }
  }

  void _showMessage(String msg) {
    setState(() => _message = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = null);
    });
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
          const Icon(Icons.psychology, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          const Text(
            'Skills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (_message != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _message!.contains('失败')
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _message!,
                style: TextStyle(
                  fontSize: 12,
                  color: _message!.contains('失败')
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigSection(),
          const SizedBox(height: 24),
          _buildSkillsList(),
        ],
      ),
    );
  }

  Widget _buildConfigSection() {
    final config = _config;
    if (config == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.chatListBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                '技能配置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary stats row
          Row(
            children: [
              _buildStatChip(
                '本地技能',
                '${config.localSkillsCount}',
                Icons.folder_outlined,
                AppColors.primary,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                '社区技能',
                '${config.communitySkillsCount}',
                Icons.public,
                config.openSkillsEnabled
                    ? AppColors.success
                    : AppColors.textHint,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Open Skills toggle
          _buildToggleRow(
            '社区开源技能',
            '启用后将自动从 GitHub 同步社区技能',
            config.openSkillsEnabled,
            _toggleOpenSkills,
          ),
          const SizedBox(height: 12),

          // Injection mode
          const Text(
            '提示词注入模式',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildModeChip(
                'full',
                '完整模式',
                '将技能的完整指令和工具信息注入系统提示词',
                config.promptInjectionMode,
              ),
              const SizedBox(width: 8),
              _buildModeChip(
                'compact',
                '精简模式',
                '仅注入技能摘要，按需加载详情',
                config.promptInjectionMode,
              ),
            ],
          ),

          if (config.skillsDir.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.folder_open,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    config.skillsDir,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsList() {
    if (_skills.isEmpty) {
      return _buildEmptySkills();
    }

    // Group by source
    final localSkills = _skills.where((s) => s.source == 'local').toList();
    final communitySkills = _skills
        .where((s) => s.source == 'community')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (localSkills.isNotEmpty) ...[
          _buildSkillGroupHeader('本地技能', localSkills.length, Icons.folder),
          const SizedBox(height: 12),
          ...localSkills.map(_buildSkillCard),
        ],
        if (communitySkills.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSkillGroupHeader('社区技能', communitySkills.length, Icons.public),
          const SizedBox(height: 12),
          ...communitySkills.map(_buildSkillCard),
        ],
      ],
    );
  }

  Widget _buildEmptySkills() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.chatListBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无可用技能',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '在工作区的 skills/ 目录下创建 SKILL.toml 或 SKILL.md 文件来添加自定义技能，\n或启用社区开源技能来获取更多能力。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '快速开始：创建 SKILL.toml',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '[skill]\n'
                  'name = "my-skill"\n'
                  'description = "技能描述"\n'
                  'version = "0.1.0"\n'
                  'tags = ["productivity"]\n'
                  '\n'
                  '[[tools]]\n'
                  'name = "my_tool"\n'
                  'description = "工具描述"\n'
                  'kind = "shell"\n'
                  'command = "echo hello"',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillGroupHeader(String title, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillCard(skills_api.SkillDto skill) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.chatListBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (skill.description.isNotEmpty)
                        Text(
                          skill.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Source badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: skill.source == 'local'
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    skill.source == 'local' ? '本地' : '社区',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: skill.source == 'local'
                          ? AppColors.primary
                          : Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            // Meta info
            if (skill.version.isNotEmpty || skill.author.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (skill.version.isNotEmpty) ...[
                    Icon(Icons.tag, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'v${skill.version}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (skill.author.isNotEmpty) ...[
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      skill.author,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Tags
            if (skill.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: skill.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Tools
            if (skill.tools.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '自带工具',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ...skill.tools.map(
                (tool) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      _toolKindIcon(tool.kind),
                      const SizedBox(width: 8),
                      Text(
                        tool.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tool.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Prompts preview
            if (skill.prompts.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: Text(
                  '指令 (${skill.prompts.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 4),
                dense: true,
                children: skill.prompts.take(5).map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '•  ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            prompt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toolKindIcon(String kind) {
    final (IconData icon, Color color) = switch (kind) {
      'shell' => (Icons.terminal, Colors.orange),
      'http' => (Icons.http, Colors.blue),
      'script' => (Icons.code, Colors.purple),
      _ => (Icons.extension, AppColors.textHint),
    };
    return Icon(icon, size: 14, color: color);
  }

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildModeChip(
    String value,
    String label,
    String description,
    String current,
  ) {
    final isSelected = current == value;
    return Expanded(
      child: InkWell(
        onTap: () => _updateInjectionMode(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.inputBg,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.inputBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 16,
                    color: isSelected ? AppColors.primary : AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
