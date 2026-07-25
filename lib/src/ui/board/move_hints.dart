import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../theme/flip10_colors.dart';
import 'dice_row.dart';

/// Wrapping list of every legal move for the current roll. Each chip is
/// tappable and a hover target on desktop.
class MoveHints extends StatelessWidget {
  const MoveHints({
    super.key,
    required this.snapshot,
    required this.validMoves,
    required this.isCompact,
    required this.onPreviewMove,
    required this.onMovePressed,
  });

  final GameSnapshot snapshot;
  final List<List<int>> validMoves;
  final bool isCompact;
  final ValueChanged<List<int>?> onPreviewMove;
  final ValueChanged<List<int>> onMovePressed;

  @override
  Widget build(BuildContext context) {
    if (snapshot.phase != GamePhase.choosingTiles || validMoves.isEmpty) {
      return const SizedBox(height: 12);
    }
    final count = validMoves.length;
    final summary = count == 1 ? '1 possible move' : '$count possible moves';

    return Padding(
      padding: EdgeInsets.only(top: isCompact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: Flip10Colors.brass,
              ),
              const SizedBox(width: 6),
              Text(
                summary,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Flip10Colors.ivory.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Wrap(
            spacing: 8,
            runSpacing: isCompact ? 6 : 8,
            children: [
              for (final move in validMoves)
                MouseRegion(
                  onEnter: (_) => onPreviewMove(move),
                  onExit: (_) => onPreviewMove(null),
                  child: Semantics(
                    button: true,
                    label: 'Select move ${move.join(' plus ')}',
                    child: _MoveHintChip(
                      move: move,
                      onPressed: () => onMovePressed(move),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoveHintChip extends StatelessWidget {
  const _MoveHintChip({required this.move, required this.onPressed});

  final List<int> move;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          decoration: BoxDecoration(
            color: Flip10Colors.ivoryTop,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Flip10Colors.brass.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < move.length; i++) ...[
                MiniPip(value: move[i], size: 20),
                if (i != move.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '+',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: Flip10Colors.ink.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
