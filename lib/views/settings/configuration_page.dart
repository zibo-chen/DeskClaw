import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coraldesk/l10n/app_localizations.dart';
import 'package:coraldesk/theme/app_theme.dart';
import 'package:coraldesk/src/rust/api/workspace_api.dart' as ws_api;
import 'package:coraldesk/views/settings/widgets/settings_scaffold.dart';

/// Configuration page showing autonomy settings and tool permissions
class ConfigurationPage extends ConsumerStatefulWidget {
  const ConfigurationPage({super.key});

  @override
  ConsumerState<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends ConsumerState<ConfigurationPage> {
  ws_api.AutonomyConfig? _autonomy;
  List<ws_api.ToolInfo>? _tools;
  bool _loading = true;
  bool _savingWebSearch = false;
  bool _savingWebFetch = false;
  bool _savingBrowser = false;
  bool _savingHttpRequest = false;
  bool _messageIsError = false;
  bool _showWebSearchApiKey = false;
  bool _showWebFetchApiKey = false;
  String? _message;
  String _webSearchProvider = 'duckduckgo';
  String _webFetchProvider = 'fast_html2md';
  late final TextEditingController _webSearchApiKeyCtrl;
  late final TextEditingController _webSearchApiUrlCtrl;
  late final TextEditingController _webFetchApiKeyCtrl;
  late final TextEditingController _webFetchApiUrlCtrl;
  late final TextEditingController _browserAllowedDomainsCtrl;
  late final TextEditingController _httpRequestAllowedDomainsCtrl;
  late final TextEditingController _webFetchAllowedDomainsCtrl;
  late final TextEditingController _webFetchBlockedDomainsCtrl;
  CoralDeskColors get c => CoralDeskColors.of(context);

  @override
  void initState() {
    super.initState();
    _webSearchApiKeyCtrl = TextEditingController();
    _webSearchApiUrlCtrl = TextEditingController();
    _webFetchApiKeyCtrl = TextEditingController();
    _webFetchApiUrlCtrl = TextEditingController();
    _browserAllowedDomainsCtrl = TextEditingController();
    _httpRequestAllowedDomainsCtrl = TextEditingController();
    _webFetchAllowedDomainsCtrl = TextEditingController();
    _webFetchBlockedDomainsCtrl = TextEditingController();
    _loadAll();
  }

  @override
  void dispose() {
    _webSearchApiKeyCtrl.dispose();
    _webSearchApiUrlCtrl.dispose();
    _webFetchApiKeyCtrl.dispose();
    _webFetchApiUrlCtrl.dispose();
    _browserAllowedDomainsCtrl.dispose();
    _httpRequestAllowedDomainsCtrl.dispose();
    _webFetchAllowedDomainsCtrl.dispose();
    _webFetchBlockedDomainsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final autonomy = await ws_api.getAutonomyConfig();
    final tools = await ws_api.listToolsWithStatus();
    final webSearchConfig = _decodeToolConfig(
      await ws_api.getToolConfig(toolName: 'web_search'),
      fallback: const {'provider': 'duckduckgo', 'api_key': '', 'api_url': ''},
    );
    final webFetchConfig = _decodeToolConfig(
      await ws_api.getToolConfig(toolName: 'web_fetch'),
      fallback: const {
        'provider': 'fast_html2md',
        'api_key': '',
        'api_url': '',
        'allowed_domains': <String>[],
        'blocked_domains': <String>[],
      },
    );
    final browserConfig = _decodeToolConfig(
      await ws_api.getToolConfig(toolName: 'browser'),
      fallback: const {
        'enabled': true,
        'backend': 'agent_browser',
        'agent_browser_command': '',
        'allowed_domains': <String>[],
      },
    );
    final httpRequestConfig = _decodeToolConfig(
      await ws_api.getToolConfig(toolName: 'http_request'),
      fallback: const {'enabled': false, 'allowed_domains': <String>[]},
    );

    if (mounted) {
      setState(() {
        _autonomy = autonomy;
        _tools = tools;
        _webSearchProvider =
            (webSearchConfig['provider'] as String?) ?? 'duckduckgo';
        _webFetchProvider =
            (webFetchConfig['provider'] as String?) ?? 'fast_html2md';
        _webSearchApiKeyCtrl.text =
            (webSearchConfig['api_key'] as String?) ?? '';
        _webSearchApiUrlCtrl.text =
            (webSearchConfig['api_url'] as String?) ?? '';
        _webFetchApiKeyCtrl.text = (webFetchConfig['api_key'] as String?) ?? '';
        _webFetchApiUrlCtrl.text = (webFetchConfig['api_url'] as String?) ?? '';
        _browserAllowedDomainsCtrl.text = _joinDomains(
          browserConfig['allowed_domains'],
        );
        _httpRequestAllowedDomainsCtrl.text = _joinDomains(
          httpRequestConfig['allowed_domains'],
        );
        _webFetchAllowedDomainsCtrl.text = _joinDomains(
          webFetchConfig['allowed_domains'],
        );
        _webFetchBlockedDomainsCtrl.text = _joinDomains(
          webFetchConfig['blocked_domains'],
        );
        _loading = false;
      });
    }
  }

  String _joinDomains(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .join(', ');
    }
    return '';
  }

  List<String> _parseDomainList(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Map<String, dynamic> _decodeToolConfig(
    String raw, {
    required Map<String, dynamic> fallback,
  }) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return {...fallback, ...decoded};
      }
      if (decoded is Map) {
        return {...fallback, ...decoded.cast<String, dynamic>()};
      }
    } catch (_) {
      // Ignore invalid payloads and use defaults.
    }
    return {...fallback};
  }

  Future<void> _removeCommand(String command) async {
    await ws_api.removeAllowedCommand(command: command);
    _loadAll();
  }

  Future<void> _saveWebToolConfig(String toolName) async {
    final l10n = AppLocalizations.of(context)!;
    final isWebSearch = toolName == 'web_search';

    setState(() {
      if (isWebSearch) {
        _savingWebSearch = true;
      } else {
        _savingWebFetch = true;
      }
    });

    final result = await ws_api.saveToolConfig(
      toolName: toolName,
      configJson: jsonEncode({
        'provider': isWebSearch ? _webSearchProvider : _webFetchProvider,
        'api_key': _trimOrNull(
          isWebSearch ? _webSearchApiKeyCtrl.text : _webFetchApiKeyCtrl.text,
        ),
        'api_url': _trimOrNull(
          isWebSearch ? _webSearchApiUrlCtrl.text : _webFetchApiUrlCtrl.text,
        ),
        if (!isWebSearch)
          'allowed_domains': _parseDomainList(_webFetchAllowedDomainsCtrl.text),
        if (!isWebSearch)
          'blocked_domains': _parseDomainList(_webFetchBlockedDomainsCtrl.text),
      }),
    );

    if (!mounted) return;
    setState(() {
      if (isWebSearch) {
        _savingWebSearch = false;
      } else {
        _savingWebFetch = false;
      }
    });

    if (result == 'ok') {
      _showMessage(l10n.configSaved);
      _loadAll();
    } else {
      _showMessage(l10n.saveFailedWithError(result), isError: true);
    }
  }

  Future<void> _saveDomainToolConfig(String toolName) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      if (toolName == 'browser') {
        _savingBrowser = true;
      } else {
        _savingHttpRequest = true;
      }
    });

    final result = await ws_api.saveToolConfig(
      toolName: toolName,
      configJson: jsonEncode({
        'allowed_domains': _parseDomainList(
          toolName == 'browser'
              ? _browserAllowedDomainsCtrl.text
              : _httpRequestAllowedDomainsCtrl.text,
        ),
      }),
    );

    if (!mounted) return;
    setState(() {
      if (toolName == 'browser') {
        _savingBrowser = false;
      } else {
        _savingHttpRequest = false;
      }
    });

    if (result == 'ok') {
      _showMessage(l10n.configSaved);
      _loadAll();
    } else {
      _showMessage(l10n.saveFailedWithError(result), isError: true);
    }
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(String msg, {bool isError = false}) {
    setState(() {
      _message = msg;
      _messageIsError = isError;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _message = null;
        _messageIsError = false;
      });
    });
  }

  Future<void> _showAddCommandDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addCommand),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.commandNameHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ws_api.addAllowedCommand(command: result);
      _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: AppLocalizations.of(context)!.pageConfiguration,
      icon: Icons.settings,
      isLoading: _loading,
      actions: [
        if (_message != null)
          StatusLabel(text: _message!, isError: _messageIsError),
      ],
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAutonomySection(),
        const SizedBox(height: 24),
        _buildToolConfigsSection(),
        const SizedBox(height: 24),
        _buildToolsSection(),
      ],
    );
  }

  Widget _buildToolConfigsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.chatListBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                l10n.providerConfiguration,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Web Search / Web Fetch Provider, API Key, API URL',
            style: TextStyle(fontSize: 12, color: c.textHint),
          ),
          const SizedBox(height: 16),
          _buildDomainToolCard(
            title: l10n.featureBrowser,
            description: l10n.featureBrowserDesc,
            icon: Icons.language,
            controller: _browserAllowedDomainsCtrl,
            saving: _savingBrowser,
            onSave: () => _saveDomainToolConfig('browser'),
          ),
          const SizedBox(height: 12),
          _buildDomainToolCard(
            title: l10n.featureHttpRequest,
            description: l10n.featureHttpRequestDesc,
            icon: Icons.http,
            controller: _httpRequestAllowedDomainsCtrl,
            saving: _savingHttpRequest,
            onSave: () => _saveDomainToolConfig('http_request'),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final cardWidth = wide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildWebToolCard(
                      title: l10n.featureWebSearch,
                      description: l10n.featureWebSearchDesc,
                      icon: Icons.search,
                      provider: _webSearchProvider,
                      providers: const [
                        _ToolProviderOption('duckduckgo', 'DuckDuckGo'),
                        _ToolProviderOption('brave', 'Brave'),
                        _ToolProviderOption('firecrawl', 'Firecrawl'),
                        _ToolProviderOption('tavily', 'Tavily'),
                        _ToolProviderOption('perplexity', 'Perplexity'),
                        _ToolProviderOption('exa', 'Exa'),
                        _ToolProviderOption('jina', 'Jina'),
                      ],
                      apiKeyController: _webSearchApiKeyCtrl,
                      apiUrlController: _webSearchApiUrlCtrl,
                      saving: _savingWebSearch,
                      obscureApiKey: !_showWebSearchApiKey,
                      onToggleObscure: () {
                        setState(
                          () => _showWebSearchApiKey = !_showWebSearchApiKey,
                        );
                      },
                      onProviderChanged: (value) {
                        if (value == null) return;
                        setState(() => _webSearchProvider = value);
                      },
                      onSave: () => _saveWebToolConfig('web_search'),
                      requiresApiKey: _requiresApiKey(
                        'web_search',
                        _webSearchProvider,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildWebToolCard(
                      title: l10n.featureWebFetch,
                      description: l10n.featureWebFetchDesc,
                      icon: Icons.download,
                      provider: _webFetchProvider,
                      providers: const [
                        _ToolProviderOption('fast_html2md', 'Fast HTML2MD'),
                        _ToolProviderOption('nanohtml2text', 'Nano HTML2Text'),
                        _ToolProviderOption('firecrawl', 'Firecrawl'),
                        _ToolProviderOption('tavily', 'Tavily'),
                      ],
                      apiKeyController: _webFetchApiKeyCtrl,
                      apiUrlController: _webFetchApiUrlCtrl,
                      saving: _savingWebFetch,
                      obscureApiKey: !_showWebFetchApiKey,
                      onToggleObscure: () {
                        setState(
                          () => _showWebFetchApiKey = !_showWebFetchApiKey,
                        );
                      },
                      onProviderChanged: (value) {
                        if (value == null) return;
                        setState(() => _webFetchProvider = value);
                      },
                      onSave: () => _saveWebToolConfig('web_fetch'),
                      requiresApiKey: _requiresApiKey(
                        'web_fetch',
                        _webFetchProvider,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  bool _requiresApiKey(String toolName, String provider) {
    return switch (toolName) {
      'web_search' => provider != 'duckduckgo',
      'web_fetch' => provider == 'firecrawl' || provider == 'tavily',
      _ => false,
    };
  }

  Widget _buildWebToolCard({
    required String title,
    required String description,
    required IconData icon,
    required String provider,
    required List<_ToolProviderOption> providers,
    required TextEditingController apiKeyController,
    required TextEditingController apiUrlController,
    required bool saving,
    required bool obscureApiKey,
    required VoidCallback onToggleObscure,
    required ValueChanged<String?> onProviderChanged,
    required VoidCallback onSave,
    required bool requiresApiKey,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasApiKey = apiKeyController.text.trim().isNotEmpty;
    final statusText = requiresApiKey
        ? (hasApiKey ? l10n.configured : l10n.missing)
        : l10n.agentOptional;
    final statusColor = requiresApiKey
        ? (hasApiKey ? AppColors.success : AppColors.warning)
        : c.textHint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 11, color: c.textHint),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(provider),
            initialValue: provider,
            decoration: InputDecoration(labelText: l10n.providerLabel),
            items: providers
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.value,
                    child: Text(item.label),
                  ),
                )
                .toList(),
            onChanged: onProviderChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: apiKeyController,
            obscureText: obscureApiKey,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: requiresApiKey
                  ? l10n.apiKeyLabel
                  : '${l10n.apiKeyLabel} (${l10n.agentOptional})',
              hintText: l10n.apiKeyHint,
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscureApiKey ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: apiUrlController,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: '${l10n.apiBaseUrlLabel} (${l10n.agentOptional})',
              hintText: _apiUrlHint(provider),
            ),
          ),
          if (title == l10n.featureWebFetch) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _webFetchAllowedDomainsCtrl,
              minLines: 1,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Allowed Domains',
                hintText: '*.example.com, docs.rs 或 *',
                helperText: _autonomy?.trustMe == true
                    ? '信任模式下运行时自动允许所有公开网站；这里用于非信任模式持久化配置。'
                    : '逗号分隔，留空时该工具将拒绝访问网站。',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _webFetchBlockedDomainsCtrl,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Blocked Domains',
                hintText: 'malware.example.com',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(saving ? l10n.saving : l10n.save),
            ),
          ),
        ],
      ),
    );
  }

  String _apiUrlHint(String provider) {
    return switch (provider) {
      'tavily' => 'https://api.tavily.com',
      'firecrawl' => 'https://api.firecrawl.dev',
      'perplexity' => 'https://api.perplexity.ai',
      'exa' => 'https://api.exa.ai',
      'jina' => 'https://s.jina.ai',
      _ => '',
    };
  }

  Widget _buildDomainToolCard({
    required String title,
    required String description,
    required IconData icon,
    required TextEditingController controller,
    required bool saving,
    required VoidCallback onSave,
  }) {
    final trustMeEnabled = _autonomy?.trustMe == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 11, color: c.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Allowed Domains',
              hintText: 'example.com, docs.rs 或 *',
              helperText: trustMeEnabled
                  ? '信任模式下运行时直接允许所有公开网站；当前列表作为关闭信任模式后的持久化配置。'
                  : '逗号分隔；留空表示不允许访问任何网站。',
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(
                saving
                    ? AppLocalizations.of(context)!.saving
                    : AppLocalizations.of(context)!.save,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutonomySection() {
    final a = _autonomy;
    if (a == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.chatListBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.autonomySecurity,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Autonomy level selector
          Text(
            AppLocalizations.of(context)!.autonomyLevel,
            style: TextStyle(
              fontSize: 13,
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLevelChip(
                'read_only',
                AppLocalizations.of(context)!.readOnly,
                Icons.visibility,
                a.level,
              ),
              const SizedBox(width: 8),
              _buildLevelChip(
                'supervised',
                AppLocalizations.of(context)!.supervised,
                Icons.supervisor_account,
                a.level,
              ),
              const SizedBox(width: 8),
              _buildLevelChip(
                'full',
                AppLocalizations.of(context)!.fullAutonomy,
                Icons.bolt,
                a.level,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Trust Me mode toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.trustMeMode,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.trustMeDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: a.trustMe,
                activeTrackColor: Colors.orange,
                onChanged: (value) async {
                  await ws_api.updateTrustMe(enabled: value);
                  _loadAll();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Settings
          _buildInfoRow(
            AppLocalizations.of(context)!.workspaceOnly,
            a.workspaceOnly
                ? AppLocalizations.of(context)!.yes
                : AppLocalizations.of(context)!.no,
          ),
          _buildInfoRow(
            AppLocalizations.of(context)!.requireApprovalMediumRisk,
            a.requireApprovalForMediumRisk
                ? AppLocalizations.of(context)!.yes
                : AppLocalizations.of(context)!.no,
          ),
          _buildInfoRow(
            AppLocalizations.of(context)!.blockHighRisk,
            a.blockHighRiskCommands
                ? AppLocalizations.of(context)!.yes
                : AppLocalizations.of(context)!.no,
          ),
          _buildInfoRow(
            AppLocalizations.of(context)!.maxActionsPerHour,
            '${a.maxActionsPerHour}',
          ),
          _buildInfoRow(
            AppLocalizations.of(context)!.maxCostPerDay,
            '${a.maxCostPerDayCents}¢',
          ),

          if (a.allowedCommands.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.allowedCommands,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showAddCommandDialog(),
                  tooltip: AppLocalizations.of(context)!.addCommand,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: a.allowedCommands
                  .map(
                    (cmd) => Chip(
                      label: Text(cmd, style: const TextStyle(fontSize: 11)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _removeCommand(cmd),
                    ),
                  )
                  .toList(),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.allowedCommands,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showAddCommandDialog(),
                  tooltip: AppLocalizations.of(context)!.addCommand,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.noCommandsConfigured,
              style: TextStyle(
                fontSize: 11,
                color: c.textSecondary.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if (a.autoApprove.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.autoApprovedTools,
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: a.autoApprove
                  .map(
                    (t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.green.shade50,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelChip(
    String value,
    String label,
    IconData icon,
    String current,
  ) {
    final isSelected = current == value;
    return InkWell(
      onTap: () async {
        await ws_api.updateAutonomyLevel(level: value);
        _loadAll();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : c.inputBg,
          border: Border.all(
            color: isSelected ? AppColors.primary : c.chatListBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : c.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection() {
    final tools = _tools;
    if (tools == null || tools.isEmpty) return const SizedBox.shrink();

    // Group by category
    final categories = <String, List<ws_api.ToolInfo>>{};
    for (final tool in tools) {
      categories.putIfAbsent(tool.category, () => []).add(tool);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.chatListBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.build_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.toolsSection,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.toolCountLabel(tools.length),
                style: TextStyle(fontSize: 12, color: c.textHint),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.entries.map(
            (entry) => _buildToolCategory(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCategory(String category, List<ws_api.ToolInfo> tools) {
    final categoryLabels = {
      'core': AppLocalizations.of(context)!.categoryCoreTools,
      'vcs': AppLocalizations.of(context)!.categoryVersionControl,
      'web': AppLocalizations.of(context)!.categoryWebNetwork,
      'memory': AppLocalizations.of(context)!.categoryMemory,
      'system': AppLocalizations.of(context)!.categorySystem,
      'file': AppLocalizations.of(context)!.categoryFileProcessing,
      'agent': AppLocalizations.of(context)!.categoryAgent,
      'cron': AppLocalizations.of(context)!.categoryScheduling,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryLabels[category] ?? category.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textHint,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...tools.map(_buildToolRow),
        ],
      ),
    );
  }

  Widget _buildToolRow(ws_api.ToolInfo tool) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(_toolIcon(tool.category), size: 16, color: c.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: Text(
              tool.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                color: c.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              tool.description,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ),
          if (tool.autoApproved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                AppLocalizations.of(context)!.approvalAuto,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (tool.alwaysAsk)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                AppLocalizations.of(context)!.approvalAsk,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _toolIcon(String category) {
    return switch (category) {
      'core' => Icons.terminal,
      'vcs' => Icons.merge_type,
      'web' => Icons.language,
      'memory' => Icons.memory,
      'system' => Icons.computer,
      'file' => Icons.description,
      'agent' => Icons.smart_toy,
      'cron' => Icons.schedule,
      _ => Icons.extension,
    };
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: c.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolProviderOption {
  final String value;
  final String label;

  const _ToolProviderOption(this.value, this.label);
}
