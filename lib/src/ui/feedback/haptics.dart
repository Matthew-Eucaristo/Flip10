import 'package:flutter/services.dart';

/// Centralized haptics. We keep this thin so future mute/preferences are easy.
class FlipHaptics {
  const FlipHaptics._();

  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
}
