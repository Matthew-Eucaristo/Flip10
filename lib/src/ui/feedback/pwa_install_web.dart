import 'dart:async';
import 'dart:js_interop';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

/// Web implementation of the PWA install hook.
class PwaInstallSupport {
  PwaInstallSupport._();

  static const _prefsDismissed = 'flip10.pwaBannerDismissed';
  static const _prefsInstalled = 'flip10.pwaInstalled';

  // Cached prompt event from `beforeinstallprompt`.
  static _BeforeInstallPromptEvent? _cachedPrompt;

  static bool isInstalled() {
    try {
      final standalone = web.window.matchMedia('(display-mode: standalone)');
      return standalone.matches;
    } catch (_) {
      return false;
    }
  }

  static bool isIOS() {
    try {
      final ua = web.window.navigator.userAgent.toLowerCase();
      return ua.contains('iphone') ||
          ua.contains('ipad') ||
          ua.contains('ipod');
    } catch (_) {
      return false;
    }
  }

  static void attachListeners({
    required void Function() onPromptReady,
    required Future<void> Function() onInstalled,
  }) {
    try {
      web.window.addEventListener(
        'beforeinstallprompt',
        ((web.Event e) {
          e.preventDefault();
          _cachedPrompt = e as _BeforeInstallPromptEvent;
          onPromptReady();
        }).toJS,
      );
      web.window.addEventListener(
        'appinstalled',
        ((web.Event _) {
          // Fire-and-forget: toJS wrappers cannot return a Future.
          // ignore: unawaited_futures
          () async {
            await markInstalled();
            await onInstalled();
          }();
        }).toJS,
      );
    } catch (_) {
      // Best-effort only.
    }
  }

  /// Triggers the deferred install prompt and waits for user choice.
  /// Returns `true` if the user accepted, `false` otherwise.
  static Future<bool?> promptInstall() async {
    final event = _cachedPrompt;
    if (event == null) {
      return null;
    }
    try {
      event.prompt();
      final jsPromise = event.userChoice;
      final completer = Completer<_UserChoice>();
      jsPromise.toDart.then(
        ((JSAny v) => completer.complete(v as _UserChoice)),
        onError: ((JSAny e) => completer.completeError(e)),
      );
      final choice = await completer.future;
      _cachedPrompt = null;
      return choice.outcome == 'accepted';
    } catch (_) {
      return null;
    }
  }

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
}

extension type _BeforeInstallPromptEvent._(JSObject _obj)
    implements JSObject {
  external JSPromise<_UserChoice> get userChoice;
  external void prompt();
}

extension type _UserChoice._(JSObject _) implements JSObject {
  external String get outcome;
}
