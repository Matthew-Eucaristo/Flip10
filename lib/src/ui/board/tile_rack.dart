import 'package:flutter/material.dart';

import '../../game/game_models.dart';
import 'number_tile.dart';

/// A wrap-laid-out rack of number tiles for the active player.
///
/// Tiles flip with a left-to-right stagger ([NumberTile.flipDelay]) and
/// shake when a pick is rejected — [rejectedTile]/[rejectNonce] identify
/// the last rejected pick.
class TileRack extends StatelessWidget {
  const TileRack({
    super.key,
    required this.snapshot,
    required this.previewTiles,
    required this.isCompact,
    required this.onTilePressed,
    this.rejectedTile,
    this.rejectNonce = 0,
  });

  final GameSnapshot snapshot;
  final Set<int> previewTiles;
  final bool isCompact;
  final ValueChanged<int> onTilePressed;

  /// The tile of the most recent rejected pick, if any.
  final int? rejectedTile;

  /// Bumped on every rejected pick so repeats of the same tile re-shake.
  final int rejectNonce;

  @override
  Widget build(BuildContext context) {
    final target = snapshot.currentRoll?.total;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = isCompact ? 7.0 : 9.0;
        final idealTileWidth = isCompact ? 48.0 : 54.0;
        final minTileWidth = isCompact ? 38.0 : 44.0;
        final maxTileWidth = isCompact ? 54.0 : 60.0;
        final columns =
            ((constraints.maxWidth + spacing) / (idealTileWidth + spacing))
                .floor()
                .clamp(1, kTileCount)
                .toInt();
        final tileWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .clamp(minTileWidth, maxTileWidth)
                .toDouble();
        final tileHeight = tileWidth * (isCompact ? 1.55 : 1.6);

        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: isCompact ? 9 : 11,
          children: [
            for (var tile = 1; tile <= kTileCount; tile++)
              NumberTile(
                number: tile,
                state: _stateFor(tile, target),
                width: tileWidth,
                height: tileHeight,
                flipDelay: Duration(milliseconds: 40 * (tile - 1)),
                rejectNonce: tile == rejectedTile ? rejectNonce : 0,
                onPressed: () => onTilePressed(tile),
              ),
          ],
        );
      },
    );
  }

  TileState _stateFor(int tile, int? target) {
    if (!snapshot.activePlayer.openTiles.contains(tile)) {
      return TileState.closed;
    }
    if (snapshot.selectedTiles.contains(tile)) {
      return TileState.selected;
    }
    if (previewTiles.contains(tile)) {
      return TileState.hinted;
    }
    return TileState.open;
  }
}
