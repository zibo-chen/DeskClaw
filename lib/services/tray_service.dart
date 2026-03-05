import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// macOS-only: toggle Dock icon visibility via a native MethodChannel.
class _DockIcon {
  static const _channel = MethodChannel('com.coraldesk/dock');

  static Future<void> hide() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('hide');
    } catch (_) {}
  }

  static Future<void> show() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('show');
    } catch (_) {}
  }
}

/// Manages the system-tray icon and its context menu on macOS / Windows / Linux.
///
/// Call [TrayService.instance.init] once during startup (after windowManager is
/// ready). The service listens for tray events and toggles window visibility or
/// quits the application accordingly.
class TrayService with TrayListener {
  TrayService._();
  static final TrayService instance = TrayService._();

  bool _initialized = false;

  /// Initialise the tray icon and menu.
  ///
  /// Must be called on the main isolate after [windowManager.ensureInitialized].
  Future<void> init() async {
    if (_initialized) return;

    // Choose the correct icon path per platform.
    final String iconPath = _resolveTrayIconPath();

    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('CoralDesk – Running in background');

    // Build a minimal right-click menu.
    await _rebuildMenu(isVisible: true);

    trayManager.addListener(this);
    _initialized = true;
  }

  /// Tear down the tray icon (optional, for cleanup).
  Future<void> destroy() async {
    trayManager.removeListener(this);
    await trayManager.destroy();
    _initialized = false;
  }

  // ── TrayListener overrides ──────────────────────────────

  @override
  void onTrayIconMouseDown() {
    // Left-click: toggle window visibility.
    _toggleWindowVisibility();
  }

  @override
  void onTrayIconRightMouseDown() {
    // Right-click: show context menu (standard on Windows / Linux).
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
        break;
      case 'hide':
        _hideWindow();
        break;
      case 'quit':
        _quitApp();
        break;
    }
  }

  // ── Helpers ─────────────────────────────────────────────

  Future<void> _toggleWindowVisibility() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await _hideWindow();
    } else {
      await _showWindow();
    }
  }

  /// Public entry-point used both by tray-menu actions and the window's own
  /// close button (via [onWindowClose] in AppShell).
  Future<void> showWindow() async {
    // Restore Dock icon before showing the window so it appears in the
    // switcher and Mission Control as a normal app again.
    await _DockIcon.show();
    await windowManager.show();
    await windowManager.focus();
    await _rebuildMenu(isVisible: true);
  }

  /// Public entry-point – hides window AND removes Dock icon on macOS.
  Future<void> hideWindow() async {
    await windowManager.hide();
    // Hide Dock icon after the window is gone so the app becomes a
    // pure menu-bar accessory while running in the background.
    await _DockIcon.hide();
    await _rebuildMenu(isVisible: false);
  }

  Future<void> _showWindow() => showWindow();
  Future<void> _hideWindow() => hideWindow();

  Future<void> _quitApp() async {
    // Disable prevent-close so the window can actually be destroyed.
    await windowManager.setPreventClose(false);
    await destroy();
    await windowManager.close();
    // Fallback: if windowManager.close() didn't terminate the process.
    exit(0);
  }

  Future<void> _rebuildMenu({required bool isVisible}) async {
    final menu = Menu(
      items: [
        MenuItem(
          key: isVisible ? 'hide' : 'show',
          label: isVisible ? 'Hide CoralDesk' : 'Show CoralDesk',
        ),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit CoralDesk'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  /// Resolve the icon path – `tray_manager` expects an **absolute** file path
  /// (not a Flutter asset key). On release builds the assets live alongside the
  /// executable; on debug builds Flutter hot-reloads them into a build dir.
  String _resolveTrayIconPath() {
    if (Platform.isMacOS) {
      // On macOS the tray icon should ideally be a "template image"
      // (monochrome, named with 'Template' suffix). We fall through to the
      // generic icon which still works — macOS will render it in the menu bar.
      return _resolveAssetPath('assets/icons/tray_icon_macos.png');
    }
    // Windows & Linux
    return _resolveAssetPath('assets/icons/tray_icon.png');
  }

  String _resolveAssetPath(String relativePath) {
    // In release mode the asset is bundled next to the executable.
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    if (Platform.isMacOS) {
      // macOS bundle: Runner.app/Contents/MacOS/coraldesk
      // Assets are at: Runner.app/Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/<path>
      final frameworkAssets =
          '${File(Platform.resolvedExecutable).parent.parent.path}/Frameworks/App.framework/Versions/A/Resources/flutter_assets/$relativePath';
      if (File(frameworkAssets).existsSync()) return frameworkAssets;
    }

    if (Platform.isWindows) {
      // Windows: <exe_dir>/data/flutter_assets/<path>
      final winAssets = '$exeDir/data/flutter_assets/$relativePath';
      if (File(winAssets).existsSync()) return winAssets;
    }

    if (Platform.isLinux) {
      // Linux: <exe_dir>/data/flutter_assets/<path>
      final linuxAssets = '$exeDir/data/flutter_assets/$relativePath';
      if (File(linuxAssets).existsSync()) return linuxAssets;
    }

    // Debug fallback – assets are at the project root.
    final projectRoot = Directory.current.path;
    final debug = '$projectRoot/$relativePath';
    if (File(debug).existsSync()) return debug;

    // Last resort – return relative path and let tray_manager try its luck.
    debugPrint('TrayService: could not resolve icon path for $relativePath');
    return relativePath;
  }
}
