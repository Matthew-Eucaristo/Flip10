import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../common/svg_icon.dart';
import '../theme/flip10_colors.dart';

/// Phase copy + icon. Reads as a brass plate on the felt.
class ActionPrompt extends StatelessWidget {
  const ActionPrompt({
    super.key,
    required this.snapshot,
    required this.isCompact,
  });

  final GameSnapshot snapshot;
  final bool isCompact;

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
        return 'assets/svg/misc/phase-trophy.svg';
    }
  }

  Color _titleColor() {
    if (snapshot.phase == GamePhase.blocked) return Flip10Colors.warning;
    if (snapshot.phase == GamePhase.choosingTiles && snapshot.isSelectionValid) {
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
            child: SvgIcon(_iconAsset(), size: isCompact ? 26 : 30),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: isCompact ? 21 : 24,
                        letterSpacing: 0.2,
                      ),
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
      'Score ${snapshot.activePlayer.remainingTotal} to end the round.',
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
    return 'Shut the box!';
  }
  return 'Scored ${snapshot.remainingTotal}.';
}
