import 'package:shared_preferences/shared_preferences.dart';

/// Web-only hook for the PWA banner logic. Implemented on web via
/// `dart:js_interop` + `package:web`; stubbed on other platforms.
class PwaInstallSupport {
  PwaInstallSupport._();

  static const _prefsDismissed = 'flip10.pwaBannerDismissed';
  static const _prefsInstalled = 'flip10.pwaInstalled';

  /// Returns true if the host page is running as an installed PWA.
  static bool isInstalled() => false;

  /// Returns true on iOS Safari (where `beforeinstallprompt` never fires).
  static bool isIOS() => false;

  /// Subscribes to the browser's `beforeinstallprompt` and `appinstalled`
  /// events. The callbacks fire on the web platform only.
  static void attachListeners({
    required void Function() onPromptReady,
    required Future<void> Function() onInstalled,
  }) {}

  static Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsDismissed, true);
  }

  static Future<bool> wasDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsDismissed) ?? false;
  }

  static Future<void> markInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsInstalled, true);
  }

  /// Triggers the deferred install prompt and returns whether the user
  /// accepted. No-op on non-web platforms.
  static Future<bool?> promptInstall() async => null;
}
