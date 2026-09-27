import 'package:shared_preferences/shared_preferences.dart';

/// Lifetime records and per-session settings persisted locally via
/// `shared_preferences`. All reads are synchronous after [AppStore.load].
final class AppStore {
  AppStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kRounds = 'stats.rounds';
  static const _kShutBoxes = 'stats.shutBoxes';
  static const _kBestRound = 'stats.bestRound';
  static const _kStreak = 'stats.streak';
  static const _kBestStreak = 'stats.bestStreak';
  static const _kSound = 'settings.sound';
  static const _kHaptics = 'settings.haptics';

  static Future<AppStore> load() async {
    return AppStore._(await SharedPreferences.getInstance());
  }

  /// Recorded lifetime stats. Safe to read before any round completes.
  GameStats get stats => GameStats(
    rounds: _prefs.getInt(_kRounds) ?? 0,
    shutBoxes: _prefs.getInt(_kShutBoxes) ?? 0,
    bestRound: _prefs.containsKey(_kBestRound)
        ? _prefs.getInt(_kBestRound)
        : null,
    currentStreak: _prefs.getInt(_kStreak) ?? 0,
    bestStreak: _prefs.getInt(_kBestStreak) ?? 0,
  );

  /// Record one finished round. Returns the updated stats plus whether
  /// the round set a new best (lowest score ever, counting shut boxes).
  Future<StatsRecord> recordRound({
    required int score,
    required bool isShut,
  }) async {
    final previous = stats;
    final streak = isShut ? previous.currentStreak + 1 : 0;
    final best = previous.bestRound;
    final isNewBest = best == null || score < best;
    final next = GameStats(
      rounds: previous.rounds + 1,
      shutBoxes: previous.shutBoxes + (isShut ? 1 : 0),
      bestRound: isNewBest ? score : best,
      currentStreak: streak,
      bestStreak: streak > previous.bestStreak ? streak : previous.bestStreak,
    );

    await Future.wait([
      _prefs.setInt(_kRounds, next.rounds),
      _prefs.setInt(_kShutBoxes, next.shutBoxes),
      _prefs.setInt(_kBestRound, next.bestRound!),
      _prefs.setInt(_kStreak, next.currentStreak),
      _prefs.setInt(_kBestStreak, next.bestStreak),
    ]);
    return StatsRecord(stats: next, isNewBest: isNewBest);
  }

  bool get soundOn => _prefs.getBool(_kSound) ?? true;
  bool get hapticsOn => _prefs.getBool(_kHaptics) ?? true;

  Future<void> setSoundOn(bool value) => _prefs.setBool(_kSound, value);
  Future<void> setHapticsOn(bool value) => _prefs.setBool(_kHaptics, value);
}

/// Point-in-time view of the player's records.
final class GameStats {
  const GameStats({
    required this.rounds,
    required this.shutBoxes,
    required this.bestRound,
    required this.currentStreak,
    required this.bestStreak,
  });

  /// Completed rounds (scored or shut).
  final int rounds;

  /// Rounds that shut the box (score 0).
  final int shutBoxes;

  /// Lowest round score ever; null until the first round completes.
  final int? bestRound;

  /// Consecutive shut boxes ending now.
  final int currentStreak;

  /// Longest shut-box streak ever.
  final int bestStreak;
}

/// Result of [AppStore.recordRound].
final class StatsRecord {
  const StatsRecord({required this.stats, required this.isNewBest});

  final GameStats stats;
  final bool isNewBest;
}
