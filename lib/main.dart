import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:deskclaw/l10n/app_localizations.dart';
import 'package:deskclaw/src/rust/frb_generated.dart';
import 'package:deskclaw/src/rust/api/agent_api.dart' as agent_api;
import 'package:deskclaw/src/rust/api/sessions_api.dart' as sessions_api;
import 'package:deskclaw/theme/app_theme.dart';
import 'package:deskclaw/views/shell/app_shell.dart';
import 'package:deskclaw/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // Initialize Zeroclaw runtime (loads config from ~/.zeroclaw/config.toml)
  final status = await agent_api.initRuntime();
  debugPrint('DeskClaw runtime: $status');

  // Initialize session persistence store
  final sessionsStatus = await sessions_api.initSessionStore();
  debugPrint('DeskClaw sessions: $sessionsStatus');

  runApp(const ProviderScope(child: DeskClawApp()));
}

class DeskClawApp extends ConsumerWidget {
  const DeskClawApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'DeskClaw',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('zh')],
      home: const AppShell(),
    );
  }
}
