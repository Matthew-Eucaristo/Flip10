import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/flip10_colors.dart';

/// An [SvgPicture] wrapper with sensible defaults for the Flip10 art pack.
///
/// - Renders the SVG to fill the given width/height (or constraints).
/// - Uses [ColorFilter] to apply the current color when the SVG uses `currentColor`.
/// - Forwards semantics from the supplied [semanticLabel] (optional).
class SvgIcon extends StatelessWidget {
  const SvgIcon(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
    this.semanticsLabel,
    this.fit = BoxFit.contain,
  })  : assert(
          width == null || size == null,
          'Provide either width or size, not both.',
        ),
        assert(
          height == null || size == null,
          'Provide either height or size, not both.',
        );

  final String asset;
  final double? width;
  final double? height;
  final double? size;
  final Color? color;
  final String? semanticsLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final picture = SvgPicture.asset(
      asset,
      width: w,
      height: h,
      fit: fit,
      allowDrawingOutsideViewBox: true,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
    if (semanticsLabel == null) {
      return picture;
    }
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: picture,
    );
  }
}

/// A wood-toned ornament plate used for phase icons and stat headers.
class BrassPlate extends StatelessWidget {
  const BrassPlate({
    super.key,
    required this.child,
    this.size = 36,
    this.padding = const EdgeInsets.all(4),
  });

  final Widget child;
  final double size;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Flip10Colors.brassTop,
            Flip10Colors.brass,
            Flip10Colors.brassDeep,
          ],
        ),
        border: Border.all(color: Flip10Colors.woodDeep, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
