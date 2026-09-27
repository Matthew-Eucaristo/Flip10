import 'package:flutter/services.dart';

/// Centralized haptics. We keep this thin so future mute/preferences are easy.
/// [enabled] is wired to the persisted setting from [AppStore] at startup
/// and from the settings sheet toggle.
class FlipHaptics {
  const FlipHaptics._();

  static bool enabled = true;

  static Future<void> selection() =>
      enabled ? HapticFeedback.selectionClick() : Future.value();
  static Future<void> light() =>
      enabled ? HapticFeedback.lightImpact() : Future.value();
  static Future<void> medium() =>
      enabled ? HapticFeedback.mediumImpact() : Future.value();
  static Future<void> heavy() =>
      enabled ? HapticFeedback.heavyImpact() : Future.value();
}
