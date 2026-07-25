import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../theme/flip10_colors.dart';
import 'brand_mark.dart';

/// Slim brand bar: just the mark and a title. All controls live on the
/// board itself (New game is in the active player band).
class GameHeader extends StatelessWidget {
  const GameHeader({super.key, required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const BrandMark(size: 44),
        const SizedBox(width: 12),
        Text(
          'Flip10',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                height: 0.95,
                color: Flip10Colors.ivory,
              ),
        ),
      ],
    );
  }
}
