import 'package:audioplayers/audioplayers.dart';

import 'audio.dart';

/// Native (Android, iOS, desktop) [AudioService] backed by `audioplayers`.
class AudioPlayersService implements AudioService {
  AudioPlayersService._(this._player);

  final AudioPlayer _player;
  bool _warmedUp = false;

  static Future<AudioPlayersService> create() async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    return AudioPlayersService._(player);
  }

  @override
  Future<void> warmUp() async {
    if (_warmedUp) return;
    _warmedUp = true;
    for (final cue in Sfx.values) {
      final source = _sourceFor(cue);
      if (source == null) continue;
      try {
        await _player.setSource(AssetSource(source));
      } catch (_) {
        // Best-effort warmup; individual plays will retry.
      }
    }
  }

  @override
  Future<void> play(Sfx cue) async {
    final source = _sourceFor(cue);
    if (source == null) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(source), volume: 0.9);
    } catch (_) {
      // Best-effort; never let a sound failure crash the game.
    }
  }

  String? _sourceFor(Sfx cue) {
    switch (cue) {
      case Sfx.roll:
        return 'audio/roll.wav';
      case Sfx.flip:
        return 'audio/flip.wav';
      case Sfx.select:
        return 'audio/select.wav';
      case Sfx.deny:
        return 'audio/deny.wav';
      case Sfx.success:
        return 'audio/success.wav';
      case Sfx.blocked:
        return 'audio/blocked.wav';
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Entry point imported via conditional import from `audio.dart`.
Future<AudioService> createPlatformAudioService() =>
    AudioPlayersService.create();
