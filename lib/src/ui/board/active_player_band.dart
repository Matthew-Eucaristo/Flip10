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
    required this.onMenu,
  });

  final GameSnapshot snapshot;
  final bool isCompact;
  final VoidCallback onNewGame;
  final VoidCallback onMenu;

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
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
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
              _ScoreValue(
                value: value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Flip10Colors.ivory,
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 18 : 20,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _BandButton(
            onPressed: onMenu,
            icon: Icons.settings_rounded,
            label: 'Settings and stats',
          ),
          _BandButton(
            onPressed: onNewGame,
            icon: Icons.refresh_rounded,
            label: 'New game',
          ),
        ],
      ),
    );
  }
}

/// The band's numeric value with a floating "+N" badge that rises and
/// fades whenever the value increases (score added on round complete).
class _ScoreValue extends StatefulWidget {
  const _ScoreValue({required this.value, required this.style});

  final int value;
  final TextStyle? style;

  @override
  State<_ScoreValue> createState() => _ScoreValueState();
}

class _ScoreValueState extends State<_ScoreValue> {
  /// Live "+N" badges; each [_FloatBadge] removes itself when done.
  final List<(int, int)> _badges = <(int, int)>[];
  int _badgeNonce = 0;

  @override
  void didUpdateWidget(covariant _ScoreValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    final delta = widget.value - oldWidget.value;
    if (delta > 0) {
      setState(() => _badges.add((delta, ++_badgeNonce)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Text('${widget.value}', style: widget.style),
        for (final (delta, nonce) in _badges)
          Positioned(
            top: -2,
            child: _FloatBadge(
              key: ValueKey(nonce),
              delta: delta,
              onDone: () {
                setState(() {
                  _badges.removeWhere((b) => b.$2 == nonce);
                });
              },
            ),
          ),
      ],
    );
  }
}

/// A "+N" label that floats up and fades out, then reports completion.
class _FloatBadge extends StatefulWidget {
  const _FloatBadge({super.key, required this.delta, required this.onDone});

  final int delta;
  final VoidCallback onDone;

  @override
  State<_FloatBadge> createState() => _FloatBadgeState();
}

class _FloatBadgeState extends State<_FloatBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDone();
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
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -26 * Curves.easeOut.transform(t)),
            child: Text(
              '+${widget.delta}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Flip10Colors.brassTop,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Circular icon button on the band (settings, new game).
class _BandButton extends StatelessWidget {
  const _BandButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Flip10Colors.brass, size: 24),
          splashRadius: 24,
          padding: EdgeInsets.zero,
          tooltip: label,
        ),
      ),
    );
  }
}
