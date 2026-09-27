import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'audio.dart';

/// Web [AudioService] backed by raw `HTMLAudioElement`.
///
/// `audioplayers_web` does not implement its global event channel, so we
/// drive `<audio>` elements directly via `dart:js_interop`. The browser's
/// autoplay policy requires the first `play()` call to happen inside a
/// user gesture, so we unlock the audio context lazily on the first
/// `play()` (which is always invoked from a tap/click handler).
class WebAudioService implements AudioService {
  WebAudioService._(this._elements);

  final Map<Sfx, web.HTMLAudioElement> _elements;
  bool _unlocked = false;

  static String _srcFor(Sfx cue) {
    switch (cue) {
      case Sfx.roll:
        return 'assets/assets/audio/roll.wav';
      case Sfx.flip:
        return 'assets/assets/audio/flip.wav';
      case Sfx.select:
        return 'assets/assets/audio/select.wav';
      case Sfx.deny:
        return 'assets/assets/audio/deny.wav';
      case Sfx.success:
        return 'assets/assets/audio/success.wav';
      case Sfx.blocked:
        return 'assets/assets/audio/blocked.wav';
    }
  }

  static Future<WebAudioService> create() async {
    final base = web.document.baseURI;
    final elements = <Sfx, web.HTMLAudioElement>{};
    for (final cue in Sfx.values) {
      final el = web.document.createElement('audio') as web.HTMLAudioElement;
      el.preload = 'auto';
      el.volume = 0.9;
      el.src = Uri.parse(base).resolve(_srcFor(cue)).toString();
      elements[cue] = el;
    }
    return WebAudioService._(elements);
  }

  @override
  Future<void> warmUp() async {
    // No-op. Unlocking happens on the first play() in a user gesture.
  }

  @override
  Future<void> play(Sfx cue) async {
    final el = _elements[cue];
    if (el == null) return;
    try {
      // Unlock the audio context once. Play-and-pause satisfies the
      // browser's user-gesture requirement for subsequent plays.
      if (!_unlocked) {
        _unlocked = true;
        try {
          el.currentTime = 0;
          await el.play().toDart;
          el.pause();
          el.currentTime = 0;
        } catch (_) {
          // Unlock is best-effort; subsequent plays will retry.
        }
      }
      el.currentTime = 0;
      await el.play().toDart;
    } catch (_) {
      // Best-effort; never let a sound failure crash the game.
    }
  }

  @override
  Future<void> dispose() async {
    for (final el in _elements.values) {
      try {
        el.pause();
        el.removeAttribute('src');
        el.load();
      } catch (_) {}
    }
    _elements.clear();
  }
}

/// Entry point imported via conditional import from `audio.dart`.
Future<AudioService> createPlatformAudioService() => WebAudioService.create();
