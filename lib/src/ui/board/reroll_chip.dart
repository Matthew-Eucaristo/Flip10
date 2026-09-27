import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../theme/flip10_colors.dart';

/// The once-per-round reroll power-up, shown beside the dice. Enabled
/// only while a reroll could still change the round ([GameSnapshot.canReroll]).
class RerollChip extends StatelessWidget {
  const RerollChip({
    super.key,
    required this.snapshot,
    required this.isRolling,
    required this.isCompact,
    required this.onPressed,
  });

  final GameSnapshot snapshot;
  final bool isRolling;
  final bool isCompact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final usable = snapshot.canReroll && !isRolling;
    final left = snapshot.rerollsLeft;
    return Opacity(
      opacity: usable ? 1.0 : 0.45,
      child: Semantics(
        button: true,
        enabled: usable,
        label: left > 0 ? 'Reroll dice, $left left' : 'No rerolls left',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: usable ? onPressed : null,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 12,
                vertical: isCompact ? 7 : 8,
              ),
              decoration: BoxDecoration(
                color: usable
                    ? Flip10Colors.brass.withValues(alpha: 0.18)
                    : Flip10Colors.panel.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: usable
                      ? Flip10Colors.brass
                      : Flip10Colors.ivory.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.casino_outlined,
                    size: isCompact ? 15 : 17,
                    color: usable
                        ? Flip10Colors.brass
                        : Flip10Colors.ivory.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'REROLL ×$left',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: usable
                          ? Flip10Colors.brass
                          : Flip10Colors.ivory.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
