import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../common/svg_icon.dart';
import '../theme/flip10_colors.dart';

/// Phase copy + icon. Reads as a brass plate on the felt.
/// Completed rounds are graded with a medal (gold = shut the box,
/// silver <= 10, bronze <= 20) and flagged when they set a new best.
class ActionPrompt extends StatelessWidget {
  const ActionPrompt({
    super.key,
    required this.snapshot,
    required this.isCompact,
    this.isNewBest = false,
  });

  final GameSnapshot snapshot;
  final bool isCompact;

  /// Whether the last completed round set a new lifetime best.
  final bool isNewBest;

  String get _title => _actionTitle(snapshot);
  String get _detail => _actionDetail(snapshot);

  String _iconAsset() {
    switch (snapshot.phase) {
      case GamePhase.waitingForRoll:
        return 'assets/svg/misc/phase-dice.svg';
      case GamePhase.choosingTiles:
        return 'assets/svg/misc/phase-hand.svg';
      case GamePhase.blocked:
        return 'assets/svg/misc/phase-warning.svg';
      case GamePhase.complete:
        return switch (snapshot.remainingTotal) {
          0 => 'assets/svg/misc/medal-gold.svg',
          <= 10 => 'assets/svg/misc/medal-silver.svg',
          <= 20 => 'assets/svg/misc/medal-bronze.svg',
          _ => 'assets/svg/misc/phase-trophy.svg',
        };
    }
  }

  Color _titleColor() {
    if (snapshot.phase == GamePhase.blocked) return Flip10Colors.warning;
    if (snapshot.phase == GamePhase.choosingTiles &&
        snapshot.isSelectionValid) {
      return Flip10Colors.accent;
    }
    return Flip10Colors.ivory;
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = _titleColor();
    return Semantics(
      liveRegion: true,
      label: '$_title. $_detail',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BrassPlate(
            size: isCompact ? 38 : 44,
            padding: const EdgeInsets.all(6),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: SvgIcon(
                _iconAsset(),
                key: ValueKey(_iconAsset()),
                size: isCompact ? 26 : 30,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _title,
                        key: ValueKey(_title),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 21 : 24,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (isNewBest && snapshot.phase == GamePhase.complete)
                      const _NewBestBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Flip10Colors.ivory.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 13 : 14,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _actionTitle(GameSnapshot snapshot) {
  return switch (snapshot.phase) {
    GamePhase.waitingForRoll => 'Roll dice',
    GamePhase.choosingTiles => 'Choose ${snapshot.currentRoll!.total}',
    GamePhase.blocked => 'No legal move',
    GamePhase.complete => 'Round complete',
  };
}

String _actionDetail(GameSnapshot snapshot) {
  return switch (snapshot.phase) {
    GamePhase.waitingForRoll =>
      'You have ${snapshot.activePlayer.remainingTotal} points open.',
    GamePhase.choosingTiles => _selectionDetail(snapshot),
    GamePhase.blocked =>
      snapshot.canReroll
          ? 'Score ${snapshot.activePlayer.remainingTotal} — or reroll for a fresh throw.'
          : 'Score ${snapshot.activePlayer.remainingTotal} to end the round.',
    GamePhase.complete => _outcomeCopy(snapshot),
  };
}

String _selectionDetail(GameSnapshot snapshot) {
  final target = snapshot.currentRoll!.total;
  final selected = snapshot.selectedTotal;
  final remaining = target - selected;
  if (remaining == 0) {
    return 'Close the selected tiles.';
  }
  if (selected == 0) {
    return 'Pick open tiles totaling $target.';
  }
  return '$selected selected. Need $remaining more.';
}

String _outcomeCopy(GameSnapshot snapshot) {
  if (snapshot.isShut) {
    return 'Shut the box! Zero points.';
  }
  return 'Scored ${snapshot.remainingTotal}.';
}

/// Small pulsing brass tag shown next to "Round complete" when the
/// score beat the lifetime best.
class _NewBestBadge extends StatefulWidget {
  const _NewBestBadge();

  @override
  State<_NewBestBadge> createState() => _NewBestBadgeState();
}

class _NewBestBadgeState extends State<_NewBestBadge>
    with SingleTickerProviderStateMixin {
  // Finite pulse count — keeps pumpAndSettle-friendly (no infinite
  // animation) while still catching the eye on round complete.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true, count: 4);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: Flip10Colors.brass.withValues(
            alpha: 0.22 + _pulse.value * 0.16,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Flip10Colors.brass, width: 1),
        ),
        child: child,
      ),
      child: Text(
        'NEW BEST',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Flip10Colors.brassTop,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
