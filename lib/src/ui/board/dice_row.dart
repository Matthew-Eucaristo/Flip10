import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../common/svg_icon.dart';
import '../theme/flip10_colors.dart';

/// Two dice rendered with the SVG art pack, with a tumble animation.
class DiceRow extends StatelessWidget {
  const DiceRow({
    super.key,
    required this.roll,
    required this.isRolling,
    required this.isCompact,
  });

  final DiceRoll? roll;
  final bool isRolling;
  final bool isCompact;

  static const _tumbleFrames = [
    'assets/svg/dice/tumble-1.svg',
    'assets/svg/dice/tumble-2.svg',
  ];

  @override
  Widget build(BuildContext context) {
    final size = isCompact ? 60.0 : 72.0;
    final faces = isRolling
        ? const <int>[]
        : (roll == null
            ? const <int>[]
            : <int>[roll!.first, roll!.second]);

    return Semantics(
      liveRegion: true,
      label: isRolling
          ? 'Rolling dice'
          : roll == null
              ? 'Dice not rolled'
              : 'Rolled ${roll!.total}',
      child: SizedBox(
        height: size,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Row(
            key: ValueKey(
              isRolling
                  ? 'rolling'
                  : roll == null
                      ? 'empty'
                      : '${roll!.first}-${roll!.second}',
            ),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRolling) ...[
                _TumbleDie(
                  asset: _tumbleFrames[0],
                  size: size,
                  delayMs: 0,
                ),
                SizedBox(width: isCompact ? 10 : 12),
                _TumbleDie(
                  asset: _tumbleFrames[1],
                  size: size,
                  delayMs: 120,
                ),
              ] else if (faces.isEmpty) ...[
                _StaticDie(
                  asset: 'assets/svg/dice/face-blank.svg',
                  size: size,
                ),
                SizedBox(width: isCompact ? 10 : 12),
                _StaticDie(
                  asset: 'assets/svg/dice/face-blank.svg',
                  size: size,
                ),
              ] else
                for (var i = 0; i < faces.length; i++) ...[
                  _StaticDie(
                    asset: 'assets/svg/dice/face-${faces[i]}.svg',
                    size: size,
                  ),
                  if (i != faces.length - 1)
                    SizedBox(width: isCompact ? 10 : 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticDie extends StatelessWidget {
  const _StaticDie({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: SvgIcon(asset, size: size, semanticsLabel: null),
    );
  }
}

class _TumbleDie extends StatefulWidget {
  const _TumbleDie({
    required this.asset,
    required this.size,
    required this.delayMs,
  });

  final String asset;
  final double size;
  final int delayMs;

  @override
  State<_TumbleDie> createState() => _TumbleDieState();
}

class _TumbleDieState extends State<_TumbleDie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _rotation = Tween<double>(begin: 0, end: 6.28).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value,
          child: child,
        );
      },
      child: SizedBox.square(
        dimension: widget.size,
        child: SvgIcon(widget.asset, size: widget.size),
      ),
    );
  }
}

/// A small numbered chip used inside the move hint rows.
class MiniPip extends StatelessWidget {
  const MiniPip({super.key, required this.value, this.size = 22});
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: size + 4),
      height: size + 6,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Flip10Colors.brass.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Flip10Colors.brassDeep.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Text(
        '$value',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Flip10Colors.ink,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
