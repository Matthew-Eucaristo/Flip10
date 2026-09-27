import 'package:flutter/material.dart';

import '../../services/app_store.dart';
import '../theme/flip10_colors.dart';

/// Bottom-sheet menu: sound/haptics toggles, lifetime records, and a
/// compact how-to. Values read live from [store]; toggles write through
/// and call [onChanged] so the game screen can re-read.
Future<void> showGameMenuSheet(
  BuildContext context, {
  required AppStore store,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Flip10Colors.panel,
    showDragHandle: true,
    builder: (context) => _GameMenuSheet(store: store, onChanged: onChanged),
  );
}

class _GameMenuSheet extends StatefulWidget {
  const _GameMenuSheet({required this.store, required this.onChanged});

  final AppStore store;
  final VoidCallback onChanged;

  @override
  State<_GameMenuSheet> createState() => _GameMenuSheetState();
}

class _GameMenuSheetState extends State<_GameMenuSheet> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final stats = store.stats;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHeading('Records'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                  label: 'BEST ROUND',
                  value: stats.bestRound?.toString() ?? '—',
                ),
                _StatChip(label: 'SHUT BOXES', value: '${stats.shutBoxes}'),
                _StatChip(
                  label: 'SHUT STREAK',
                  value: '${stats.currentStreak}',
                ),
                _StatChip(label: 'ROUNDS', value: '${stats.rounds}'),
              ],
            ),
            const SizedBox(height: 18),
            const _SheetHeading('Settings'),
            _ToggleRow(
              icon: Icons.volume_up_rounded,
              label: 'Sound effects',
              value: store.soundOn,
              onChanged: (v) async {
                await store.setSoundOn(v);
                widget.onChanged();
                if (mounted) setState(() {});
              },
            ),
            _ToggleRow(
              icon: Icons.vibration_rounded,
              label: 'Haptics',
              value: store.hapticsOn,
              onChanged: (v) async {
                await store.setHapticsOn(v);
                widget.onChanged();
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 18),
            const _SheetHeading('How to play'),
            const SizedBox(height: 8),
            const _RuleLine(
              'Roll the dice, then close any open tiles whose numbers sum to the roll — one tile or a combo.',
            ),
            const _RuleLine(
              'No legal move? The remaining open tiles are added to your total. Low score wins.',
            ),
            const _RuleLine(
              'Close all 10 tiles in one round to shut the box: zero points.',
            ),
            const _RuleLine(
              'Stuck? Once per round, REROLL throws fresh dice — even on a dead roll.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeading extends StatelessWidget {
  const _SheetHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Flip10Colors.brass,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Flip10Colors.panelDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Flip10Colors.brass.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Flip10Colors.ivory.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Flip10Colors.ivory,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: Flip10Colors.brass, size: 20),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Flip10Colors.ivory,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: Flip10Colors.brass,
      activeThumbColor: Flip10Colors.ivoryTop,
      inactiveTrackColor: Flip10Colors.panelDeep,
      inactiveThumbColor: Flip10Colors.ivory.withValues(alpha: 0.6),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Flip10Colors.brass,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Flip10Colors.ivory.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
