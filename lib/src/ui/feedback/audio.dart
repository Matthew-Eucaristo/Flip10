import 'audio_native.dart'
    if (dart.library.js_interop) 'audio_web.dart'
    as platform;

/// Cue names correspond to the WAVs in `assets/audio/`.
enum Sfx { roll, flip, select, deny, success, blocked }

/// Platform-agnostic audio service. The native implementation uses
/// `audioplayers`; the web implementation uses HTML5 audio via
/// `dart:js_interop` because the `audioplayers` web plugin does not
/// implement its global event channel and emits `MissingPluginException`
/// on the web (verified against `audioplayers_web-5.2.0`).
abstract class AudioService {
  Future<void> warmUp();
  Future<void> play(Sfx cue);
  Future<void> dispose();
}

/// Construct the platform-appropriate [AudioService].
Future<AudioService> createAudioService() =>
    platform.createPlatformAudioService();
