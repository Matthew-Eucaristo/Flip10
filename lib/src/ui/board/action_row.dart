import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../theme/flip10_colors.dart';

/// Phase-aware primary actions for the bottom of the screen.
///
/// Renders the single primary action for the current phase, plus a
/// secondary "Close" button while [GamePhase.choosingTiles] is active.
/// The "Score" prompt is folded into the primary button during
/// [GamePhase.blocked]; "Next round" is replaced by "Play again"
/// during [GamePhase.complete] (rounds are endless — no end-of-match).
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.snapshot,
    required this.isRolling,
    required this.onRoll,
    required this.onClose,
    required this.onScore,
    required this.onPlayAgain,
  });

  final GameSnapshot snapshot;
  final bool isRolling;
  final VoidCallback onRoll;
  final VoidCallback onClose;
  final VoidCallback onScore;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final phase = snapshot.phase;
    final canRoll = phase == GamePhase.waitingForRoll && !isRolling;
    final canClose = phase == GamePhase.choosingTiles && snapshot.isSelectionValid;
    final selectedTotal = snapshot.selectedTotal;
    final remaining = snapshot.currentRoll == null
        ? 0
        : snapshot.currentRoll!.total - selectedTotal;

    final rollBtn = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Flip10Colors.brass,
        foregroundColor: Flip10Colors.ink,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: canRoll ? onRoll : null,
      icon: const Icon(Icons.casino_rounded),
      label: Text(isRolling ? 'Rolling...' : 'Roll dice'),
    );

    final closeBtn = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: canClose
            ? Flip10Colors.accent
            : Flip10Colors.panel,
        foregroundColor: canClose
            ? Flip10Colors.accentDeep
            : Flip10Colors.ivory.withValues(alpha: 0.6),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(
          color: canClose
              ? Flip10Colors.accent
              : Flip10Colors.ivory.withValues(alpha: 0.18),
        ),
      ),
      onPressed: canClose ? onClose : null,
      icon: const Icon(Icons.keyboard_double_arrow_down_rounded),
      label: Text(
        canClose
            ? 'Close $selectedTotal'
            : selectedTotal == 0
                ? 'Select tiles'
                : 'Need $remaining',
      ),
    );

    final scoreBtn = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Flip10Colors.warning,
        foregroundColor: Flip10Colors.ink,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onScore,
      icon: const Icon(Icons.flag_rounded),
      label: Text('Score ${snapshot.remainingTotal}'),
    );

    final playAgainBtn = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Flip10Colors.brass,
        foregroundColor: Flip10Colors.ink,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPlayAgain,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Play again'),
    );

    final primary = switch (phase) {
      GamePhase.waitingForRoll => rollBtn,
      GamePhase.choosingTiles => closeBtn,
      GamePhase.blocked => scoreBtn,
      GamePhase.complete => playAgainBtn,
    };

    final secondary = phase == GamePhase.choosingTiles ? rollBtn : null;

    if (secondary == null) {
      return primary;
    }
    return Row(
      children: [
        Expanded(child: secondary),
        const SizedBox(width: 10),
        Expanded(child: primary),
      ],
    );
  }
}
