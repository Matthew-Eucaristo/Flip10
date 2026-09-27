import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../../game/game_rules.dart';
import '../common/svg_icon.dart';
import 'action_prompt.dart';
import 'active_player_band.dart';
import 'celebration_burst.dart';
import 'dice_row.dart';
import 'move_hints.dart';
import 'reroll_chip.dart';
import 'tile_rack.dart';

/// The wooden board: wood frame, felt interior, dice, tiles, hints.
/// The action row lives outside this widget so the same widget can be
/// used inside a scroll view (desktop) or above a sticky bottom dock
/// (phone) without an internal `showActions` flag.
class BoardTable extends StatefulWidget {
  const BoardTable({
    super.key,
    required this.snapshot,
    required this.isRolling,
    required this.isCompact,
    required this.onRoll,
    required this.onTilePressed,
    required this.onMovePressed,
    required this.onClose,
    required this.onNewGame,
    required this.onReroll,
    required this.onMenu,
    this.rejectedTile,
    this.rejectNonce = 0,
    this.celebrateNonce = 0,
    this.isNewBest = false,
  });

  final GameSnapshot snapshot;
  final bool isRolling;
  final bool isCompact;
  final VoidCallback onRoll;
  final ValueChanged<int> onTilePressed;
  final ValueChanged<List<int>> onMovePressed;
  final VoidCallback onClose;
  final VoidCallback onNewGame;

  /// Fires the once-per-round reroll power-up (dice tumble included).
  final VoidCallback onReroll;

  /// Opens the settings/stats/how-to sheet.
  final VoidCallback onMenu;

  /// Most recent rejected tile pick + its nonce (replays the shake).
  final int? rejectedTile;
  final int rejectNonce;

  /// Bumped when the player shuts the box; each increment plays one
  /// confetti burst over the board.
  final int celebrateNonce;

  /// Whether the just-completed round set a new lifetime best.
  final bool isNewBest;

  @override
  State<BoardTable> createState() => _BoardTableState();
}

class _BoardTableState extends State<BoardTable>
    with SingleTickerProviderStateMixin {
  Set<int> _previewTiles = const <int>{};

  /// Short horizontal shake played when a roll lands blocked.
  late final AnimationController _blockedShake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// Live confetti bursts (each shuts the box once, then removes itself).
  final List<int> _bursts = <int>[];

  @override
  void didUpdateWidget(covariant BoardTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot.phase != GamePhase.choosingTiles ||
        widget.snapshot.currentRoll != oldWidget.snapshot.currentRoll) {
      _previewTiles = const <int>{};
    }
    if (widget.snapshot.phase == GamePhase.blocked &&
        oldWidget.snapshot.phase != GamePhase.blocked) {
      _blockedShake.forward(from: 0);
    }
    if (widget.celebrateNonce != oldWidget.celebrateNonce) {
      setState(() => _bursts.add(widget.celebrateNonce));
    }
  }

  @override
  void dispose() {
    _blockedShake.dispose();
    super.dispose();
  }

  void _previewMove(List<int>? move) {
    setState(() {
      _previewTiles = move == null ? const <int>{} : Set<int>.of(move);
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final roll = snapshot.currentRoll;
    final activePlayer = snapshot.activePlayer;
    final validMoves = roll == null
        ? const <List<int>>[]
        : GameRules.validMoves(
            openTiles: activePlayer.openTiles,
            target: roll.total,
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgIcon(
                'assets/svg/board/wood-frame.svg',
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(widget.isCompact ? 10 : 14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SvgIcon(
                          'assets/svg/board/felt.svg',
                          fit: BoxFit.fill,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(widget.isCompact ? 12 : 18),
                        child: AnimatedBuilder(
                          animation: _blockedShake,
                          builder: (context, child) {
                            final dx = _blockedShake.isAnimating
                                ? math.sin(_blockedShake.value * math.pi * 4) *
                                      6 *
                                      (1 - _blockedShake.value)
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ActivePlayerBand(
                                snapshot: snapshot,
                                isCompact: widget.isCompact,
                                onNewGame: widget.onNewGame,
                                onMenu: widget.onMenu,
                              ),
                              SizedBox(height: widget.isCompact ? 12 : 18),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  DiceRow(
                                    roll: roll,
                                    isRolling: widget.isRolling,
                                    isCompact: widget.isCompact,
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: RerollChip(
                                      snapshot: snapshot,
                                      isRolling: widget.isRolling,
                                      isCompact: widget.isCompact,
                                      onPressed: widget.onReroll,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: widget.isCompact ? 10 : 16),
                              ActionPrompt(
                                snapshot: snapshot,
                                isCompact: widget.isCompact,
                                isNewBest: widget.isNewBest,
                              ),
                              SizedBox(height: widget.isCompact ? 10 : 16),
                              Center(
                                child: TileRack(
                                  snapshot: snapshot,
                                  previewTiles: _previewTiles,
                                  isCompact: widget.isCompact,
                                  rejectedTile: widget.rejectedTile,
                                  rejectNonce: widget.rejectNonce,
                                  onTilePressed: widget.onTilePressed,
                                ),
                              ),
                              MoveHints(
                                snapshot: snapshot,
                                validMoves: validMoves,
                                isCompact: widget.isCompact,
                                onPreviewMove: _previewMove,
                                onMovePressed: widget.onMovePressed,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ..._buildCorners(widget.isCompact),
            for (final nonce in _bursts)
              Positioned.fill(
                child: CelebrationBurst(
                  key: ValueKey(nonce),
                  onDone: () => setState(() => _bursts.remove(nonce)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners(bool isCompact) {
    final size = isCompact ? 28.0 : 36.0;
    final inset = isCompact ? 4.0 : 6.0;
    return [
      Positioned(
        top: inset,
        left: inset,
        child: SvgIcon('assets/svg/board/corner.svg', size: size),
      ),
      Positioned(
        top: inset,
        right: inset,
        child: Transform.rotate(
          angle: 1.5708,
          child: SvgIcon('assets/svg/board/corner.svg', size: size),
        ),
      ),
      Positioned(
        bottom: inset,
        left: inset,
        child: Transform.rotate(
          angle: -1.5708,
          child: SvgIcon('assets/svg/board/corner.svg', size: size),
        ),
      ),
      Positioned(
        bottom: inset,
        right: inset,
        child: Transform.rotate(
          angle: 3.1416,
          child: SvgIcon('assets/svg/board/corner.svg', size: size),
        ),
      ),
    ];
  }
}
