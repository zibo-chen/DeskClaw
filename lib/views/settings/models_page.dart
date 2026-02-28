import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/src/rust/api/config_api.dart' as config_api;
import 'package:deskclaw/src/rust/api/agent_api.dart' as agent_api;

/// Models settings page — real config management
class ModelsPage extends ConsumerStatefulWidget {
  const ModelsPage({super.key});

  @override
  ConsumerState<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends ConsumerState<ModelsPage> {
  late List<config_api.ProviderInfo> _providers;
  String _selectedProviderId = 'openrouter';
  String _selectedModel = 'anthropic/claude-sonnet-4-20250514';
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiBaseController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  double _temperature = 0.7;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _saveMessage;

  /// Providers that allow custom model name input
  static const _customModelProviders = {'compatible', 'ollama', 'openrouter'};

  @override
  void initState() {
    super.initState();
    _providers = config_api.listProviders();
    _loadConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiBaseController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  bool get _supportsCustomModel =>
      _customModelProviders.contains(_selectedProviderId);

  Future<void> _loadConfig() async {
    final config = await config_api.loadConfig();
    setState(() {
      _selectedProviderId = config.provider;
      _selectedModel = config.model;
      _modelController.text = config.model;
      _apiKeyController.text = config.apiKey;
      _apiBaseController.text = config.apiBase ?? '';
      _temperature = config.temperature;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    setState(() {
      _isSaving = true;
      _saveMessage = null;
    });

    final modelToSave = _supportsCustomModel
        ? _modelController.text.trim()
        : _selectedModel;

    final success = await config_api.saveConfig(
      config: config_api.AppConfig(
        provider: _selectedProviderId,
        model: modelToSave,
        apiKey: _apiKeyController.text.trim(),
        apiBase: _apiBaseController.text.trim().isEmpty
            ? null
            : _apiBaseController.text.trim(),
        temperature: _temperature,
        maxToolIterations: 10,
        language: 'en',
      ),
    );

    setState(() {
      _isSaving = false;
      _saveMessage = success ? 'Configuration saved!' : 'Failed to save config';
    });

    // Clear message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _saveMessage = null);
    });
  }

  config_api.ProviderInfo get _currentProvider {
    return _providers.firstWhere(
      (p) => p.id == _selectedProviderId,
      orElse: () => _providers.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _SettingsPageScaffold(
      title: 'Models',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Provider Configuration',
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.chatListBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider dropdown
                  _buildDropdownRow(
                    'Provider',
                    _selectedProviderId,
                    _providers.map((p) => p.id).toList(),
                    _providers.map((p) => p.name).toList(),
                    (value) {
                      setState(() {
                        _selectedProviderId = value!;
                        // Auto-select first model of new provider
                        final provider = _currentProvider;
                        if (provider.models.isNotEmpty) {
                          _selectedModel = provider.models.first;
                          _modelController.text = _selectedModel;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Model selector — dropdown for known providers, editable for custom
                  if (_supportsCustomModel)
                    _buildEditableModelRow()
                  else
                    _buildDropdownRow(
                      'Model',
                      _currentProvider.models.contains(_selectedModel)
                          ? _selectedModel
                          : _currentProvider.models.first,
                      _currentProvider.models,
                      _currentProvider.models,
                      (value) {
                        setState(() {
                          _selectedModel = value!;
                          _modelController.text = value;
                        });
                      },
                    ),
                  const SizedBox(height: 16),

                  // API Key
                  if (_currentProvider.requiresApiKey) ...[
                    _buildTextFieldRow(
                      'API Key',
                      'Enter your API key...',
                      _apiKeyController,
                      obscure: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // API Base URL
                  if (_currentProvider.requiresApiBase) ...[
                    _buildTextFieldRow(
                      'API Base URL',
                      _selectedProviderId == 'ollama'
                          ? 'http://localhost:11434'
                          : 'https://api.example.com/v1',
                      _apiBaseController,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Temperature
                  _buildSliderRow('Temperature', _temperature, (value) {
                    setState(() => _temperature = value);
                  }),

                  const SizedBox(height: 24),

                  // Save button
                  Row(
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
                        label: Text(_isSaving ? 'Saving...' : 'Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (_saveMessage != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          _saveMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _saveMessage!.contains('Failed')
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Runtime status
          FutureBuilder<agent_api.RuntimeStatus>(
            future: agent_api.getRuntimeStatus(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final status = snapshot.data!;
              return _buildSection(
                title: 'Runtime Status',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.chatListBorder),
                  ),
                  child: Column(
                    children: [
                      _buildStatusRow(
                        'Initialized',
                        status.initialized ? 'Yes' : 'No',
                        status.initialized
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      _buildStatusRow(
                        'API Key',
                        status.hasApiKey ? 'Configured' : 'Missing',
                        status.hasApiKey
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      _buildStatusRow('Active Provider', status.provider, null),
                      _buildStatusRow('Active Model', status.model, null),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  /// Editable model field with autocomplete suggestions for custom providers
  Widget _buildEditableModelRow() {
    final suggestions = _currentProvider.models;
    return Row(
      children: [
        const SizedBox(
          width: 140,
          child: Text(
            'Model',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Autocomplete<String>(
            initialValue: TextEditingValue(text: _modelController.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return suggestions;
              }
              return suggestions.where(
                (s) => s.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
            },
            onSelected: (String selection) {
              _modelController.text = selection;
              setState(() => _selectedModel = selection);
            },
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController fieldController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  // Sync field controller with our model controller
                  if (fieldController.text != _modelController.text &&
                      !focusNode.hasFocus) {
                    fieldController.text = _modelController.text;
                  }
                  return TextField(
                    controller: fieldController,
                    focusNode: focusNode,
                    onChanged: (value) {
                      _modelController.text = value;
                      _selectedModel = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter model name or select from list...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        padding: EdgeInsets.zero,
                        tooltip: 'Show suggestions',
                        onSelected: (value) {
                          fieldController.text = value;
                          _modelController.text = value;
                          setState(() => _selectedModel = value);
                        },
                        itemBuilder: (context) => suggestions
                            .map(
                              (s) => PopupMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 400,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow(
    String label,
    String value,
    List<String> values,
    List<String> displayNames,
    ValueChanged<String?> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inputBorder),
              color: AppColors.inputBg,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: values.contains(value) ? value : values.first,
                isExpanded: true,
                isDense: true,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                items: List.generate(values.length, (i) {
                  return DropdownMenuItem(
                    value: values[i],
                    child: Text(displayNames[i]),
                  );
                }),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldRow(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 2.0,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  onChanged: onChanged,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: valueColor != null
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic settings page scaffold
class _SettingsPageScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsPageScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.chatListBorder, width: 1),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ],
    );
  }
}
