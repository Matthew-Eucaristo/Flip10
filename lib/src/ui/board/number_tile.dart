import 'package:flutter/material.dart';

import '../common/svg_icon.dart';
import '../theme/flip10_colors.dart';

/// Visual state of a [NumberTile]. Tiles are rendered from the SVG art pack,
/// with the numeric value overlaid as a Text widget.
enum TileState { open, closed, selected, hinted }

/// A single numbered tile. Renders the matching SVG plus a `Text` overlay for
/// the number (SVG `<text>` is unreliable across renderers).
class NumberTile extends StatelessWidget {
  const NumberTile({
    super.key,
    required this.number,
    required this.state,
    required this.width,
    required this.height,
    required this.onPressed,
  });

  final int number;
  final TileState state;
  final double width;
  final double height;
  final VoidCallback onPressed;

  bool get _isOpen => state != TileState.closed;

  String get _asset {
    switch (state) {
      case TileState.open:
        return 'assets/svg/tiles/tile-ivory-$number.svg';
      case TileState.closed:
        return 'assets/svg/tiles/tile-closed.svg';
      case TileState.selected:
        return 'assets/svg/tiles/tile-selected-$number.svg';
      case TileState.hinted:
        return 'assets/svg/tiles/tile-hinted-$number.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = switch (state) {
      TileState.selected => Flip10Colors.brass,
      TileState.hinted => Flip10Colors.accent,
      _ => null,
    };
    final overlayWidth = state == TileState.selected ||
            state == TileState.hinted
        ? 2.2
        : 0.0;

    return Semantics(
      button: _isOpen,
      selected: state == TileState.selected,
      enabled: _isOpen,
      label: switch (state) {
        TileState.selected => 'Selected tile $number',
        TileState.hinted => 'Suggested tile $number',
        TileState.open => 'Open tile $number',
        TileState.closed => 'Closed tile $number',
      },
      child: AnimatedScale(
        scale: state == TileState.selected || state == TileState.hinted
            ? 1.05
            : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (state == TileState.closed)
                const _ClosedTileShadow()
              else
                const _OpenTileShadow(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isOpen ? onPressed : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: SvgIcon(_asset, fit: BoxFit.contain),
                  ),
                ),
              ),
              // The numeric value is baked into the tile SVG as a path
              // (see tools/gen_tiles.py), so we don't need a Text overlay.
              if (overlayColor != null)
                IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: overlayColor,
                        width: overlayWidth,
                      ),
                      boxShadow: state == TileState.selected
                          ? [
                              BoxShadow(
                                color: Flip10Colors.brass
                                    .withValues(alpha: 0.45),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : state == TileState.hinted
                              ? [
                                  BoxShadow(
                                    color: Flip10Colors.accent
                                        .withValues(alpha: 0.45),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenTileShadow extends StatelessWidget {
  const _OpenTileShadow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ClosedTileShadow extends StatelessWidget {
  const _ClosedTileShadow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const SizedBox.expand(),
    );
  }
}
