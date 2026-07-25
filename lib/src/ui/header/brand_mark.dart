import 'package:flutter/material.dart';

import '../common/svg_icon.dart';
import '../theme/flip10_colors.dart';

/// The Flip10 brand mark: 48px wood-and-felt badge with dice + "10" tile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgIcon(
      'assets/svg/misc/brand-mark.svg',
      size: size,
      semanticsLabel: 'Flip10 mark',
    );
  }
}

/// Inline status text under the title. Uses a typewriter-feel secondary line.
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.text, this.isCompact = false});

  final String text;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Flip10Colors.ivory.withValues(alpha: 0.78),
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 13 : 14,
            letterSpacing: 0.2,
          ),
    );
  }
}

/// A circular brass-look icon button.
class BrassIconButton extends StatelessWidget {
  const BrassIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.filled = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled
            ? Flip10Colors.brass
            : Flip10Colors.panel,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
        elevation: 1.5,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: filled
                    ? Flip10Colors.ink
                    : Flip10Colors.ivory,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
