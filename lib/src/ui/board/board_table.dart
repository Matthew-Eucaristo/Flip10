import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import '../../game/game_rules.dart';
import '../common/svg_icon.dart';
import 'action_prompt.dart';
import 'active_player_band.dart';
import 'dice_row.dart';
import 'move_hints.dart';
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
  });

  final GameSnapshot snapshot;
  final bool isRolling;
  final bool isCompact;
  final VoidCallback onRoll;
  final ValueChanged<int> onTilePressed;
  final ValueChanged<List<int>> onMovePressed;
  final VoidCallback onClose;
  final VoidCallback onNewGame;

  @override
  State<BoardTable> createState() => _BoardTableState();
}

class _BoardTableState extends State<BoardTable> {
  Set<int> _previewTiles = const <int>{};

  @override
  void didUpdateWidget(covariant BoardTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot.phase != GamePhase.choosingTiles ||
        widget.snapshot.currentRoll != oldWidget.snapshot.currentRoll) {
      _previewTiles = const <int>{};
    }
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ActivePlayerBand(
                              snapshot: snapshot,
                              isCompact: widget.isCompact,
                              onNewGame: widget.onNewGame,
                            ),
                            SizedBox(height: widget.isCompact ? 12 : 18),
                            DiceRow(
                              roll: roll,
                              isRolling: widget.isRolling,
                              isCompact: widget.isCompact,
                            ),
                            SizedBox(height: widget.isCompact ? 10 : 16),
                            ActionPrompt(
                              snapshot: snapshot,
                              isCompact: widget.isCompact,
                            ),
                            SizedBox(height: widget.isCompact ? 10 : 16),
                            Center(
                              child: TileRack(
                                snapshot: snapshot,
                                previewTiles: _previewTiles,
                                isCompact: widget.isCompact,
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
                    ],
                  ),
                ),
              ),
            ),
            ..._buildCorners(widget.isCompact),
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
