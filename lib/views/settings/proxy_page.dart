import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/proxy_api.dart' as proxy_api;

/// Proxy settings page — configure global outbound proxy
class ProxyPage extends ConsumerStatefulWidget {
  const ProxyPage({super.key});

  @override
  ConsumerState<ProxyPage> createState() => _ProxyPageState();
}

class _ProxyPageState extends ConsumerState<ProxyPage> {
  bool _enabled = false;
  proxy_api.ProxyScopeDto _scope = proxy_api.ProxyScopeDto.zeroclaw;
  final TextEditingController _httpProxyController = TextEditingController();
  final TextEditingController _httpsProxyController = TextEditingController();
  final TextEditingController _allProxyController = TextEditingController();
  final TextEditingController _noProxyController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _saveMessage;
  String? _httpError;
  String? _httpsError;
  String? _allError;
  DeskClawColors get c => DeskClawColors.of(context);

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _httpProxyController.dispose();
    _httpsProxyController.dispose();
    _allProxyController.dispose();
    _noProxyController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await proxy_api.getProxyConfig();
    if (!mounted) return;
    setState(() {
      _enabled = config.enabled;
      _scope = config.scope;
      _httpProxyController.text = config.httpProxy;
      _httpsProxyController.text = config.httpsProxy;
      _allProxyController.text = config.allProxy;
      _noProxyController.text = config.noProxy;
      _servicesController.text = config.services;
      _isLoading = false;
    });
  }

  String? _validateUrl(String url) {
    if (url.trim().isEmpty) return null;
    final result = proxy_api.validateProxyUrl(url: url);
    if (result == 'ok') return null;
    return result.replaceFirst('error: ', '');
  }

  Future<void> _saveConfig() async {
    // Validate URLs first
    final httpErr = _validateUrl(_httpProxyController.text);
    final httpsErr = _validateUrl(_httpsProxyController.text);
    final allErr = _validateUrl(_allProxyController.text);
    setState(() {
      _httpError = httpErr;
      _httpsError = httpsErr;
      _allError = allErr;
    });
    if (httpErr != null || httpsErr != null || allErr != null) return;

    setState(() {
      _isSaving = true;
      _saveMessage = null;
    });

    final dto = proxy_api.ProxyConfigDto(
      enabled: _enabled,
      httpProxy: _httpProxyController.text.trim(),
      httpsProxy: _httpsProxyController.text.trim(),
      allProxy: _allProxyController.text.trim(),
      noProxy: _noProxyController.text.trim(),
      scope: _scope,
      services: _servicesController.text.trim(),
    );

    // Apply to runtime
    final updateResult = await proxy_api.updateProxyConfig(config: dto);
    if (updateResult != 'ok') {
      setState(() {
        _isSaving = false;
        _saveMessage = updateResult;
      });
      return;
    }

    // Persist to disk
    final diskResult = await proxy_api.saveProxyToDisk();
    setState(() {
      _isSaving = false;
      _saveMessage = diskResult == 'ok'
          ? AppLocalizations.of(context)!.configSaved
          : AppLocalizations.of(context)!.configSaveFailed;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _saveMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildTopBar(l10n),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainSection(l10n),
                const SizedBox(height: 24),
                _buildScopeSection(l10n),
                if (_scope == proxy_api.ProxyScopeDto.services) ...[
                  const SizedBox(height: 24),
                  _buildServicesSection(l10n),
                ],
                const SizedBox(height: 24),
                _buildNoProxySection(l10n),
                const SizedBox(height: 24),
                _buildSaveButton(l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: c.surfaceBg,
        border: Border(bottom: BorderSide(color: c.chatListBorder, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.vpn_key, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            l10n.proxyPageTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection(AppLocalizations l10n) {
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
          // Enable toggle
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                l10n.proxyConfiguration,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Switch(
                value: _enabled,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.proxyDescription,
            style: TextStyle(fontSize: 12, color: c.textHint),
          ),
          const SizedBox(height: 20),

          // All Proxy (most common use case — shown first)
          _buildUrlField(
            label: l10n.proxyAllProxy,
            hint: 'socks5://127.0.0.1:1080',
            controller: _allProxyController,
            error: _allError,
            helpText: l10n.proxyAllProxyHelp,
          ),
          const SizedBox(height: 16),

          // HTTP Proxy
          _buildUrlField(
            label: l10n.proxyHttpProxy,
            hint: 'http://127.0.0.1:8080',
            controller: _httpProxyController,
            error: _httpError,
            helpText: l10n.proxyHttpProxyHelp,
          ),
          const SizedBox(height: 16),

          // HTTPS Proxy
          _buildUrlField(
            label: l10n.proxyHttpsProxy,
            hint: 'http://127.0.0.1:8080',
            controller: _httpsProxyController,
            error: _httpsError,
            helpText: l10n.proxyHttpsProxyHelp,
          ),
        ],
      ),
    );
  }

  Widget _buildUrlField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? error,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: c.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 2),
          Text(helpText, style: TextStyle(fontSize: 11, color: c.textHint)),
        ],
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 13, color: c.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: c.textHint),
            filled: true,
            fillColor: c.inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.chatListBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.chatListBorder),
            ),
            errorText: error,
            errorMaxLines: 2,
          ),
          onChanged: (_) {
            if (_httpError != null ||
                _httpsError != null ||
                _allError != null) {
              setState(() {
                _httpError = null;
                _httpsError = null;
                _allError = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildScopeSection(AppLocalizations l10n) {
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
          Text(
            l10n.proxyScope,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.proxyScopeDescription,
            style: TextStyle(fontSize: 12, color: c.textHint),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildScopeChip(
                proxy_api.ProxyScopeDto.zeroclaw,
                l10n.proxyScopeZeroclaw,
                Icons.bolt,
                l10n.proxyScopeZeroclawDesc,
              ),
              const SizedBox(width: 8),
              _buildScopeChip(
                proxy_api.ProxyScopeDto.services,
                l10n.proxyScopeServices,
                Icons.tune,
                l10n.proxyScopeServicesDesc,
              ),
              const SizedBox(width: 8),
              _buildScopeChip(
                proxy_api.ProxyScopeDto.environment,
                l10n.proxyScopeEnvironment,
                Icons.terminal,
                l10n.proxyScopeEnvironmentDesc,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopeChip(
    proxy_api.ProxyScopeDto value,
    String label,
    IconData icon,
    String description,
  ) {
    final isSelected = _scope == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _scope = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? AppColors.primary : c.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 11, color: c.textHint),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection(AppLocalizations l10n) {
    final services = proxy_api.listProxyServices();
    // Group by category
    final grouped = <String, List<proxy_api.ProxyServiceInfo>>{};
    for (final s in services) {
      grouped.putIfAbsent(s.category, () => []).add(s);
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
          Text(
            l10n.proxyServiceSelectors,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.proxyServiceSelectorsHelp,
            style: TextStyle(fontSize: 12, color: c.textHint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _servicesController,
            style: TextStyle(fontSize: 13, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'provider.*, channel.telegram',
              hintStyle: TextStyle(fontSize: 13, color: c.textHint),
              filled: true,
              fillColor: c.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.chatListBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.chatListBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick-select chips grouped by category
          ...grouped.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.textHint,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: entry.value.map((s) {
                      final current = _servicesController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toSet();
                      final isActive = current.contains(s.key);
                      return FilterChip(
                        label: Text(
                          s.key,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: isActive,
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        checkmarkColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onSelected: (selected) {
                          final items = _servicesController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toSet();
                          if (selected) {
                            items.add(s.key);
                          } else {
                            items.remove(s.key);
                          }
                          setState(() {
                            _servicesController.text = items.join(', ');
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProxySection(AppLocalizations l10n) {
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
          Text(
            l10n.proxyNoProxy,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.proxyNoProxyHelp,
            style: TextStyle(fontSize: 12, color: c.textHint),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noProxyController,
            style: TextStyle(fontSize: 13, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'localhost, 127.0.0.1, *.local',
              hintStyle: TextStyle(fontSize: 13, color: c.textHint),
              filled: true,
              fillColor: c.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.chatListBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.chatListBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveConfig,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? l10n.saving : l10n.save),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_saveMessage != null) ...[
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              _saveMessage!,
              style: TextStyle(
                fontSize: 13,
                color:
                    _saveMessage!.contains('error') ||
                        _saveMessage!.contains('Failed') ||
                        _saveMessage!.contains('失败')
                    ? AppColors.error
                    : AppColors.success,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
