import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/svg_icon.dart';
import '../theme/flip10_colors.dart';

/// Visual state of a [NumberTile]. Tiles are rendered from the SVG art pack,
/// with the numeric value overlaid as a Text widget.
enum TileState { open, closed, selected, hinted }

/// A single numbered tile. Renders the matching SVG plus a `Text` overlay for
/// the number (SVG `<text>` is unreliable across renderers).
///
/// Open/closed transitions play a 3D flip around the vertical axis — the
/// "flip" in Flip10 — staggered by [flipDelay] so a closing wave sweeps
/// across the rack. Rejected picks replay a short horizontal shake driven
/// by [rejectNonce].
class NumberTile extends StatefulWidget {
  const NumberTile({
    super.key,
    required this.number,
    required this.state,
    required this.width,
    required this.height,
    required this.onPressed,
    this.flipDelay = Duration.zero,
    this.rejectNonce = 0,
  });

  final int number;
  final TileState state;
  final double width;
  final double height;
  final VoidCallback onPressed;

  /// Delay before this tile's flip starts. The rack passes a per-index
  /// delay so simultaneous transitions read as a left-to-right wave.
  final Duration flipDelay;

  /// Bumped by the parent when a pick on this tile was rejected; each
  /// increment replays the shake once.
  final int rejectNonce;

  @override
  State<NumberTile> createState() => _NumberTileState();
}

class _NumberTileState extends State<NumberTile> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Assets shown on each half of an in-flight flip.
  late String _fromAsset = _assetForState(widget.state);
  late String _toAsset = _fromAsset;
  bool _flipping = false;
  int _flipTicket = 0;

  bool get _isOpen => widget.state != TileState.closed;

  static String _assetForState(TileState state, [int number = 1]) {
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

  String _assetFor(TileState state) => _assetForState(state, widget.number);

  @override
  void didUpdateWidget(covariant NumberTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasClosed = oldWidget.state == TileState.closed;
    final isClosed = widget.state == TileState.closed;
    if (wasClosed != isClosed) {
      _fromAsset = _assetFor(oldWidget.state);
      _toAsset = _assetFor(widget.state);
      final ticket = ++_flipTicket;
      _flip.reset();
      Future<void>.delayed(widget.flipDelay, () {
        if (!mounted || ticket != _flipTicket) return;
        setState(() => _flipping = true);
        _flip.forward().whenComplete(() {
          if (mounted) setState(() => _flipping = false);
        });
      });
    }
    if (widget.rejectNonce != oldWidget.rejectNonce) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final overlayColor = switch (state) {
      TileState.selected => Flip10Colors.brass,
      TileState.hinted => Flip10Colors.accent,
      _ => null,
    };
    final overlayWidth =
        state == TileState.selected || state == TileState.hinted ? 2.2 : 0.0;

    return Semantics(
      button: _isOpen,
      selected: state == TileState.selected,
      enabled: _isOpen,
      label: switch (state) {
        TileState.selected => 'Selected tile ${widget.number}',
        TileState.hinted => 'Suggested tile ${widget.number}',
        TileState.open => 'Open tile ${widget.number}',
        TileState.closed => 'Closed tile ${widget.number}',
      },
      child: AnimatedSlide(
        offset: state == TileState.selected || state == TileState.hinted
            ? const Offset(0, -0.05)
            : Offset.zero,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: state == TileState.selected || state == TileState.hinted
              ? 1.05
              : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: AnimatedBuilder(
              animation: Listenable.merge([_flip, _shake]),
              builder: (context, _) {
                final shakeDx = _shake.isAnimating
                    ? math.sin(_shake.value * math.pi * 3) *
                          5 *
                          (1 - _shake.value)
                    : 0.0;
                final angle = _flipping ? _flip.value * math.pi : 0.0;
                final showingBack = angle >= math.pi / 2;
                return Transform.translate(
                  offset: Offset(shakeDx, 0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (state == TileState.closed)
                        const _ClosedTileShadow()
                      else
                        const _OpenTileShadow(),
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(angle),
                        child: Transform(
                          alignment: Alignment.center,
                          // Un-mirror the back half of the flip.
                          transform: showingBack
                              ? Matrix4.rotationY(math.pi)
                              : Matrix4.identity(),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isOpen ? widget.onPressed : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: SvgIcon(
                                  _flipping
                                      ? (showingBack ? _toAsset : _fromAsset)
                                      : _assetFor(state),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // The numeric value is baked into the tile SVG as a
                      // path (see tools/gen_tiles.py), so no Text overlay.
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
                                        color: Flip10Colors.brass.withValues(
                                          alpha: 0.45,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : state == TileState.hinted
                                  ? [
                                      BoxShadow(
                                        color: Flip10Colors.accent.withValues(
                                          alpha: 0.45,
                                        ),
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
                );
              },
            ),
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
