import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../theme/flip10_colors.dart';

/// Header band showing the active player, a phase-aware total (open
/// points while playing, session total after a round completes), and a
/// New game icon button to reset everything.
class ActivePlayerBand extends StatelessWidget {
  const ActivePlayerBand({
    super.key,
    required this.snapshot,
    required this.isCompact,
    required this.onNewGame,
  });

  final GameSnapshot snapshot;
  final bool isCompact;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final color = Flip10Colors.playerColor(snapshot.activePlayerIndex);
    final isComplete = snapshot.phase == GamePhase.complete;
    final label = isComplete ? 'TOTAL' : 'OPEN';
    final value = isComplete
        ? snapshot.totalScore
        : snapshot.activePlayer.remainingTotal;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 10 : 14,
        isCompact ? 6 : 8,
        4,
        isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Flip10Colors.woodDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 28 : 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Player ${snapshot.activePlayerIndex + 1}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Flip10Colors.ivory,
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 20 : 22,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Flip10Colors.brass,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Flip10Colors.ivory,
                      fontWeight: FontWeight.w900,
                      fontSize: isCompact ? 18 : 20,
                    ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _NewGameButton(onPressed: onNewGame),
        ],
      ),
    );
  }
}

class _NewGameButton extends StatelessWidget {
  const _NewGameButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New game',
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Flip10Colors.brass,
            size: 24,
          ),
          splashRadius: 24,
          padding: EdgeInsets.zero,
          tooltip: 'New game',
        ),
      ),
    );
  }
}
