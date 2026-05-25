import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../game/game_controller.dart';
import '../game/game_models.dart';
import '../game/game_rules.dart';

const _background = Color(0xFF121612);
const _panel = Color(0xFF1B211C);
const _felt = Color(0xFF116B47);
const _feltDeep = Color(0xFF0A422D);
const _wood = Color(0xFF7B4D2A);
const _woodLight = Color(0xFFB7834D);
const _ivory = Color(0xFFF4E3BD);
const _ink = Color(0xFF201610);
const _brass = Color(0xFFD7A941);
const _closed = Color(0xFF302820);
const _warning = Color(0xFFE56E4F);
const _accent = Color(0xFF76D7A6);

const _playerColors = [
  Color(0xFF4FA3FF),
  Color(0xFFE85C4A),
  Color(0xFFF0C84B),
  Color(0xFF39B879),
];

String _statusCopy(GameSnapshot snapshot) {
  if (snapshot.phase != GamePhase.complete) {
    return '${snapshot.activePlayer.name} ${_phaseCopy(snapshot)}';
  }
  return _outcomeCopy(snapshot);
}

String _outcomeCopy(GameSnapshot snapshot) {
  final winners = snapshot.winners;
  if (winners.isEmpty) {
    return 'Round complete';
  }
  if (winners.length == 1) {
    final winner = winners.single;
    return '${winner.name} wins with ${winner.score}';
  }

  final names = winners.map((player) => player.name).join(' and ');
  return '$names tie with ${winners.first.score}';
}

String _phaseCopy(GameSnapshot snapshot) {
  return switch (snapshot.phase) {
    GamePhase.waitingForRoll => 'to roll',
    GamePhase.choosingTiles => 'selects ${snapshot.currentRoll!.total}',
    GamePhase.blocked => 'is blocked',
    GamePhase.complete => 'round complete',
  };
}

String _actionTitle(GameSnapshot snapshot) {
  return switch (snapshot.phase) {
    GamePhase.waitingForRoll => 'Roll dice',
    GamePhase.choosingTiles => 'Choose ${snapshot.currentRoll!.total}',
    GamePhase.blocked => 'No legal move',
    GamePhase.complete => 'Round complete',
  };
}

String _actionDetail(GameSnapshot snapshot) {
  return switch (snapshot.phase) {
    GamePhase.waitingForRoll =>
      '${snapshot.activePlayer.name} has ${snapshot.activePlayer.remainingTotal} points open.',
    GamePhase.choosingTiles => _selectionDetail(snapshot),
    GamePhase.blocked =>
      'Score ${snapshot.activePlayer.remainingTotal} and pass the dice.',
    GamePhase.complete => _outcomeCopy(snapshot),
  };
}

String _selectionDetail(GameSnapshot snapshot) {
  final target = snapshot.currentRoll!.total;
  final selected = snapshot.selectedTotal;
  final remaining = target - selected;
  if (remaining == 0) {
    return 'Close the selected tiles.';
  }
  if (selected == 0) {
    return 'Pick open tiles totaling $target.';
  }
  return '$selected selected. Need $remaining more.';
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller = GameController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _newRound({int? playerCount, int? tileCount}) {
    _controller.newRound(playerCount: playerCount, tileCount: tileCount);
    _announce(
      '${_statusCopy(_controller.snapshot)}. ${_actionTitle(_controller.snapshot)}.',
    );
  }

  void _roll() {
    _controller.roll();
    _announce(
      '${_statusCopy(_controller.snapshot)}. ${_actionDetail(_controller.snapshot)}',
    );
  }

  void _toggleTile(int tile) {
    final before = _controller.snapshot.selectedTiles;
    _controller.toggleTile(tile);
    final after = _controller.snapshot.selectedTiles;
    if (before.length == after.length && before.containsAll(after)) {
      return;
    }
    _announce(_actionDetail(_controller.snapshot));
  }

  void _selectMove(List<int> move) {
    _controller.selectMove(move);
    _announce(
      'Selected ${move.join(' plus ')}. ${_actionDetail(_controller.snapshot)}',
    );
  }

  void _closeSelection() {
    final total = _controller.snapshot.selectedTotal;
    _controller.closeSelection();
    _announce(
      'Closed $total. ${_statusCopy(_controller.snapshot)}. ${_actionTitle(_controller.snapshot)}.',
    );
  }

  void _scoreBlockedTurn() {
    final score = _controller.snapshot.activePlayer.remainingTotal;
    _controller.scoreBlockedTurn();
    _announce('Scored $score. ${_statusCopy(_controller.snapshot)}.');
  }

  void _announce(String message) {
    if (!mounted) {
      return;
    }
    if (!MediaQuery.supportsAnnounceOf(context)) {
      return;
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final snapshot = _controller.snapshot;

        return Scaffold(
          body: SafeArea(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_background, Color(0xFF182018)],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _Header(snapshot: snapshot, onNewRound: _newRound),
                        const SizedBox(height: 14),
                        _SetupBar(
                          snapshot: snapshot,
                          onPlayersChanged: (count) {
                            _newRound(playerCount: count);
                          },
                          onTileCountChanged: (count) {
                            _newRound(tileCount: count);
                          },
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: _ResponsivePlayArea(
                            snapshot: snapshot,
                            onRoll: _roll,
                            onTilePressed: _toggleTile,
                            onMovePressed: _selectMove,
                            onClose: _closeSelection,
                            onScore: _scoreBlockedTurn,
                            onNewRound: _newRound,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResponsivePlayArea extends StatelessWidget {
  const _ResponsivePlayArea({
    required this.snapshot,
    required this.onRoll,
    required this.onTilePressed,
    required this.onMovePressed,
    required this.onClose,
    required this.onScore,
    required this.onNewRound,
  });

  final GameSnapshot snapshot;
  final VoidCallback onRoll;
  final ValueChanged<int> onTilePressed;
  final ValueChanged<List<int>> onMovePressed;
  final VoidCallback onClose;
  final VoidCallback onScore;
  final VoidCallback onNewRound;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final board = _BoardTable(
          snapshot: snapshot,
          showActions: !isCompact,
          onRoll: onRoll,
          onTilePressed: onTilePressed,
          onMovePressed: onMovePressed,
          onClose: onClose,
          onScore: onScore,
          onNewRound: onNewRound,
        );
        final panel = _RoundPanel(snapshot: snapshot);

        if (constraints.maxWidth >= 860) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 7, child: board),
              const SizedBox(width: 14),
              SizedBox(width: 320, child: panel),
            ],
          );
        }

        final compactBoardHeight = snapshot.tileCount >= 12 ? 650.0 : 590.0;
        final boardHeight = constraints.maxWidth < 520
            ? compactBoardHeight
            : 540.0;

        final content = SingleChildScrollView(
          padding: EdgeInsets.only(bottom: isCompact ? 12 : 0),
          child: Column(
            children: [
              SizedBox(height: boardHeight, child: board),
              const SizedBox(height: 14),
              panel,
            ],
          ),
        );

        if (!isCompact) {
          return content;
        }

        return Column(
          children: [
            Expanded(child: content),
            const SizedBox(height: 10),
            _MobileActionDock(
              snapshot: snapshot,
              onRoll: onRoll,
              onClose: onClose,
              onScore: onScore,
              onNewRound: onNewRound,
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.snapshot, required this.onNewRound});

  final GameSnapshot snapshot;
  final VoidCallback onNewRound;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = _statusCopy(snapshot);

    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BrandMark(),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Flip10',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: textTheme.titleMedium?.copyWith(
                  color: _ivory.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final action = OutlinedButton.icon(
      onPressed: onNewRound,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('New round'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            action,
          ],
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Flip10 mark',
      image: true,
      child: SizedBox.square(
        dimension: 44,
        child: CustomPaint(painter: const _BrandMarkPainter()),
      ),
    );
  }
}

class _SetupBar extends StatelessWidget {
  const _SetupBar({
    required this.snapshot,
    required this.onPlayersChanged,
    required this.onTileCountChanged,
  });

  final GameSnapshot snapshot;
  final ValueChanged<int> onPlayersChanged;
  final ValueChanged<int> onTileCountChanged;

  @override
  Widget build(BuildContext context) {
    final playerSelector = _SegmentGroup(
      label: 'Players',
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 1, label: Text('1')),
          ButtonSegment(value: 2, label: Text('2')),
          ButtonSegment(value: 3, label: Text('3')),
          ButtonSegment(value: 4, label: Text('4')),
        ],
        selected: {snapshot.players.length},
        onSelectionChanged: (selection) {
          onPlayersChanged(selection.first);
        },
      ),
    );
    final tileSelector = _SegmentGroup(
      label: 'Tiles',
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 9, label: Text('9')),
          ButtonSegment(value: 10, label: Text('10')),
          ButtonSegment(value: 12, label: Text('12')),
        ],
        selected: {snapshot.tileCount},
        onSelectionChanged: (selection) {
          onTileCountChanged(selection.first);
        },
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 360) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SegmentGroup.stacked(
                    label: 'Players',
                    child: playerSelector.child,
                  ),
                  const SizedBox(height: 12),
                  _SegmentGroup.stacked(
                    label: 'Tiles',
                    child: tileSelector.child,
                  ),
                ],
              );
            }

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [playerSelector, tileSelector],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentGroup extends StatelessWidget {
  const _SegmentGroup({required this.label, required this.child})
    : stacked = false;
  const _SegmentGroup.stacked({required this.label, required this.child})
    : stacked = true;

  final String label;
  final Widget child;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: _ivory.withValues(alpha: 0.72)),
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [labelWidget, const SizedBox(height: 6), child],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [labelWidget, const SizedBox(width: 8), child],
    );
  }
}

class _BoardTable extends StatefulWidget {
  const _BoardTable({
    required this.snapshot,
    required this.showActions,
    required this.onRoll,
    required this.onTilePressed,
    required this.onMovePressed,
    required this.onClose,
    required this.onScore,
    required this.onNewRound,
  });

  final GameSnapshot snapshot;
  final bool showActions;
  final VoidCallback onRoll;
  final ValueChanged<int> onTilePressed;
  final ValueChanged<List<int>> onMovePressed;
  final VoidCallback onClose;
  final VoidCallback onScore;
  final VoidCallback onNewRound;

  @override
  State<_BoardTable> createState() => _BoardTableState();
}

class _BoardTableState extends State<_BoardTable> {
  Set<int> _previewTiles = const {};

  @override
  void didUpdateWidget(covariant _BoardTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot.phase != GamePhase.choosingTiles ||
        widget.snapshot.currentRoll != oldWidget.snapshot.currentRoll) {
      _previewTiles = const {};
    }
  }

  void _previewMove(List<int>? move) {
    setState(() {
      _previewTiles = move == null ? const {} : Set<int>.of(move);
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final roll = widget.snapshot.currentRoll;
    final activePlayer = widget.snapshot.activePlayer;
    final rollTotal = roll?.total;
    final validMoves = rollTotal == null
        ? const <List<int>>[]
        : GameRules.validMoves(
            openTiles: activePlayer.openTiles,
            target: rollTotal,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _wood,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CustomPaint(
            painter: const _FeltPainter(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _felt,
                border: Border.all(color: _woodLight, width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ActivePlayerBand(player: activePlayer),
                    const SizedBox(height: 18),
                    _DiceRow(roll: roll),
                    const SizedBox(height: 16),
                    _ActionPrompt(snapshot: snapshot),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: _TileRack(
                          snapshot: snapshot,
                          previewTiles: _previewTiles,
                          onTilePressed: widget.onTilePressed,
                        ),
                      ),
                    ),
                    _MoveHints(
                      snapshot: snapshot,
                      validMoves: validMoves,
                      onPreviewMove: _previewMove,
                      onMovePressed: widget.onMovePressed,
                    ),
                    if (widget.showActions) ...[
                      const SizedBox(height: 12),
                      _ActionRow(
                        snapshot: snapshot,
                        onRoll: widget.onRoll,
                        onClose: widget.onClose,
                        onScore: widget.onScore,
                        onNewRound: widget.onNewRound,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPrompt extends StatelessWidget {
  const _ActionPrompt({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isReadyToClose =
        snapshot.phase == GamePhase.choosingTiles && snapshot.isSelectionValid;
    final titleColor = snapshot.phase == GamePhase.blocked
        ? _warning
        : isReadyToClose
        ? _accent
        : _ivory;

    return Semantics(
      liveRegion: true,
      label: '${_actionTitle(snapshot)}. ${_actionDetail(snapshot)}',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Column(
          key: ValueKey(
            '${snapshot.phase}-${snapshot.currentRoll?.total}-${snapshot.selectedTotal}',
          ),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _actionTitle(snapshot),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _actionDetail(snapshot),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _ivory.withValues(alpha: 0.76),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePlayerBand extends StatelessWidget {
  const _ActivePlayerBand({required this.player});

  final PlayerBoard player;

  @override
  Widget build(BuildContext context) {
    final playerColor = _playerColors[player.index % _playerColors.length];

    return Row(
      children: [
        Container(
          width: 12,
          height: 36,
          decoration: BoxDecoration(
            color: playerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            player.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _ivory,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${player.remainingTotal}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ivory,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DiceRow extends StatelessWidget {
  const _DiceRow({required this.roll});

  final DiceRoll? roll;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: roll == null ? 'Dice not rolled' : 'Rolled ${roll!.total}',
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
            roll == null ? 'empty' : '${roll!.first}-${roll!.second}',
          ),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DiceFace(value: roll?.first),
            const SizedBox(width: 12),
            _DiceFace(value: roll?.second),
          ],
        ),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({required this.value});

  final int? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 66,
      child: CustomPaint(painter: _DicePainter(value)),
    );
  }
}

class _TileRack extends StatelessWidget {
  const _TileRack({
    required this.snapshot,
    required this.previewTiles,
    required this.onTilePressed,
  });

  final GameSnapshot snapshot;
  final Set<int> previewTiles;
  final ValueChanged<int> onTilePressed;

  @override
  Widget build(BuildContext context) {
    final activePlayer = snapshot.activePlayer;
    final target = snapshot.currentRoll?.total;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = ((constraints.maxWidth + spacing) / (52 + spacing))
            .floor()
            .clamp(1, snapshot.tileCount)
            .toInt();
        final tileWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .clamp(44.0, 52.0)
                .toDouble();
        final tileHeight = tileWidth * 1.65;

        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: 10,
          children: [
            for (var tile = 1; tile <= snapshot.tileCount; tile++)
              _NumberTile(
                number: tile,
                width: tileWidth,
                height: tileHeight,
                isOpen: activePlayer.openTiles.contains(tile),
                isSelected: snapshot.selectedTiles.contains(tile),
                isHinted: previewTiles.contains(tile),
                canSelect:
                    snapshot.phase == GamePhase.choosingTiles &&
                    activePlayer.openTiles.contains(tile) &&
                    (snapshot.selectedTiles.contains(tile) ||
                        target == null ||
                        snapshot.selectedTotal + tile <= target),
                onPressed: () => onTilePressed(tile),
              ),
          ],
        );
      },
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.number,
    required this.width,
    required this.height,
    required this.isOpen,
    required this.isSelected,
    required this.isHinted,
    required this.canSelect,
    required this.onPressed,
  });

  final int number;
  final double width;
  final double height;
  final bool isOpen;
  final bool isSelected;
  final bool isHinted;
  final bool canSelect;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = !isOpen
        ? _closed
        : isSelected
        ? _brass
        : isHinted
        ? _accent
        : _ivory;
    final foreground = !isOpen ? _ivory.withValues(alpha: 0.34) : _ink;

    return Semantics(
      button: isOpen,
      selected: isSelected,
      enabled: canSelect,
      label: isSelected ? 'Selected tile $number' : 'Tile $number',
      child: AnimatedScale(
        scale: isSelected || isHinted ? 1.05 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: width,
          height: height,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            offset: isOpen ? Offset.zero : const Offset(0, 0.18),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canSelect ? onPressed : null,
                borderRadius: BorderRadius.circular(7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : isHinted
                          ? _brass
                          : Colors.black.withValues(alpha: 0.18),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isOpen
                        ? const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 7,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveHints extends StatelessWidget {
  const _MoveHints({
    required this.snapshot,
    required this.validMoves,
    required this.onPreviewMove,
    required this.onMovePressed,
  });

  final GameSnapshot snapshot;
  final List<List<int>> validMoves;
  final ValueChanged<List<int>?> onPreviewMove;
  final ValueChanged<List<int>> onMovePressed;

  @override
  Widget build(BuildContext context) {
    if (snapshot.phase != GamePhase.choosingTiles || validMoves.isEmpty) {
      return const SizedBox(height: 66);
    }

    final visibleMoves = validMoves.take(6).toList();
    return SizedBox(
      height: 66,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Best moves',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _ivory.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleMoves.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final move = visibleMoves[index];
                return MouseRegion(
                  onEnter: (_) => onPreviewMove(move),
                  onExit: (_) => onPreviewMove(null),
                  child: Semantics(
                    button: true,
                    label: 'Select move ${move.join(' plus ')}',
                    child: ActionChip(
                      label: _MoveHintLabel(move: move),
                      onPressed: () => onMovePressed(move),
                      backgroundColor: _ivory.withValues(alpha: 0.96),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _brass.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveHintLabel extends StatelessWidget {
  const _MoveHintLabel({required this.move});

  final List<int> move;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < move.length; index++) ...[
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _brass.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${move[index]}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (index != move.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '+',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _ink.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.snapshot,
    required this.onRoll,
    required this.onClose,
    required this.onScore,
    required this.onNewRound,
    this.expandPrimary = false,
  });

  final GameSnapshot snapshot;
  final VoidCallback onRoll;
  final VoidCallback onClose;
  final VoidCallback onScore;
  final VoidCallback onNewRound;
  final bool expandPrimary;

  @override
  Widget build(BuildContext context) {
    final canClose =
        snapshot.phase == GamePhase.choosingTiles && snapshot.isSelectionValid;
    final selectedTotal = snapshot.selectedTotal;
    final primaryAction = FilledButton.icon(
      onPressed: snapshot.phase == GamePhase.waitingForRoll ? onRoll : null,
      icon: const Icon(Icons.casino_rounded),
      label: const Text('Roll dice'),
    );
    final closeAction = FilledButton.icon(
      onPressed: canClose ? onClose : null,
      icon: const Icon(Icons.keyboard_double_arrow_down_rounded),
      label: Text(
        canClose
            ? 'Close $selectedTotal'
            : selectedTotal == 0
            ? 'Select tiles'
            : 'Need ${snapshot.currentRoll!.total - selectedTotal}',
      ),
    );

    if (expandPrimary) {
      final compactAction = switch (snapshot.phase) {
        GamePhase.waitingForRoll => primaryAction,
        GamePhase.choosingTiles => closeAction,
        GamePhase.blocked => _ScoreButton(snapshot: snapshot, onScore: onScore),
        GamePhase.complete => _PlayAgainButton(onNewRound: onNewRound),
      };

      return Row(children: [Expanded(child: compactAction)]);
    }

    final actions = [
      primaryAction,
      closeAction,
      if (snapshot.phase == GamePhase.blocked)
        _ScoreButton(snapshot: snapshot, onScore: onScore),
      if (snapshot.phase == GamePhase.complete)
        _PlayAgainButton(onNewRound: onNewRound),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: actions,
    );
  }
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({required this.snapshot, required this.onScore});

  final GameSnapshot snapshot;
  final VoidCallback onScore;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onScore,
      icon: const Icon(Icons.flag_rounded),
      label: Text('Score ${snapshot.activePlayer.remainingTotal}'),
      style: FilledButton.styleFrom(backgroundColor: _warning),
    );
  }
}

class _PlayAgainButton extends StatelessWidget {
  const _PlayAgainButton({required this.onNewRound});

  final VoidCallback onNewRound;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onNewRound,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Play again'),
    );
  }
}

class _MobileActionDock extends StatelessWidget {
  const _MobileActionDock({
    required this.snapshot,
    required this.onRoll,
    required this.onClose,
    required this.onScore,
    required this.onNewRound,
  });

  final GameSnapshot snapshot;
  final VoidCallback onRoll;
  final VoidCallback onClose;
  final VoidCallback onScore;
  final VoidCallback onNewRound;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.96),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _ActionRow(
          snapshot: snapshot,
          expandPrimary: true,
          onRoll: onRoll,
          onClose: onClose,
          onScore: onScore,
          onNewRound: onNewRound,
        ),
      ),
    );
  }
}

class _RoundPanel extends StatelessWidget {
  const _RoundPanel({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Round',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ivory,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            for (final player in snapshot.players) ...[
              _PlayerPanelRow(
                player: player,
                tileCount: snapshot.tileCount,
                isActive:
                    snapshot.phase != GamePhase.complete &&
                    player.index == snapshot.activePlayerIndex,
              ),
              if (player.index != snapshot.players.last.index)
                const SizedBox(height: 10),
            ],
            if (snapshot.phase == GamePhase.complete) ...[
              const SizedBox(height: 16),
              _ResultBanner(snapshot: snapshot),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _Rankings(players: snapshot.rankedPlayers),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: _outcomeCopy(snapshot),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _brass.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _brass.withValues(alpha: 0.38)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: _brass, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _outcomeCopy(snapshot),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _ivory,
                    fontWeight: FontWeight.w800,
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

class _PlayerPanelRow extends StatelessWidget {
  const _PlayerPanelRow({
    required this.player,
    required this.tileCount,
    required this.isActive,
  });

  final PlayerBoard player;
  final int tileCount;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final playerColor = _playerColors[player.index % _playerColors.length];
    final scoreText = player.score == null
        ? '${player.remainingTotal}'
        : '${player.score}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? playerColor : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: playerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  player.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _ivory,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                scoreText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: player.isShut ? _brass : _ivory,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MiniTiles(player: player, tileCount: tileCount),
        ],
      ),
    );
  }
}

class _MiniTiles extends StatelessWidget {
  const _MiniTiles({required this.player, required this.tileCount});

  final PlayerBoard player;
  final int tileCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (var tile = 1; tile <= tileCount; tile++)
          Container(
            width: 15,
            height: 18,
            decoration: BoxDecoration(
              color: player.openTiles.contains(tile)
                  ? _ivory.withValues(alpha: 0.9)
                  : _closed,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _Rankings extends StatelessWidget {
  const _Rankings({required this.players});

  final List<PlayerBoard> players;

  @override
  Widget build(BuildContext context) {
    final winningScore = players.isEmpty ? null : players.first.score;

    return Column(
      children: [
        for (var index = 0; index < players.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${_rankFor(index)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: players[index].score == winningScore
                          ? _brass
                          : _ivory.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    players[index].name,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: _ivory),
                  ),
                ),
                Text(
                  '${players[index].score}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _ivory,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  int _rankFor(int index) {
    final score = players[index].score;
    for (var previousIndex = 0; previousIndex < index; previousIndex++) {
      if (players[previousIndex].score == score) {
        return _rankFor(previousIndex);
      }
    }
    return index + 1;
  }
}

class _FeltPainter extends CustomPainter {
  const _FeltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = _felt;
    canvas.drawRect(Offset.zero & size, base);

    final darkLine = Paint()
      ..color = _feltDeep.withValues(alpha: 0.20)
      ..strokeWidth = 1;
    final lightLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (var x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        darkLine,
      );
    }
    for (var y = 0.0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 4), lightLine);
    }
  }

  @override
  bool shouldRepaint(covariant _FeltPainter oldDelegate) => false;
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()..color = _felt;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _brass;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final badge = RRect.fromRectAndRadius(
      rect.deflate(2),
      const Radius.circular(9),
    );
    canvas.drawRRect(badge.shift(const Offset(0, 2)), shadow);
    canvas.drawRRect(badge, background);
    canvas.drawRRect(badge, border);

    final tilePaint = Paint()..color = _ivory;
    final closedPaint = Paint()..color = _closed;
    final accentPaint = Paint()..color = _accent;
    final tileSize = Size(size.width * 0.22, size.height * 0.34);
    final top = size.height * 0.18;
    final left = size.width * 0.18;

    for (var index = 0; index < 3; index++) {
      final dx = left + index * size.width * 0.18;
      final tileRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, top, tileSize.width, tileSize.height),
        const Radius.circular(3),
      );
      canvas.drawRRect(tileRect, index == 2 ? accentPaint : tilePaint);
    }

    final bottomTile = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.42,
        size.height * 0.54,
        tileSize.width,
        tileSize.height * 0.78,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(bottomTile, closedPaint);
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) => false;
}

class _DicePainter extends CustomPainter {
  const _DicePainter(this.value);

  final int? value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(2),
      const Radius.circular(12),
    );
    final facePaint = Paint()..color = _ivory;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withValues(alpha: 0.16);

    canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawRRect(rrect, facePaint);
    canvas.drawRRect(rrect, borderPaint);

    final rollValue = value;
    if (rollValue == null) {
      final dash = Paint()
        ..color = _ink.withValues(alpha: 0.18)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width * 0.35, size.height * 0.5),
        Offset(size.width * 0.65, size.height * 0.5),
        dash,
      );
      return;
    }

    final pipPaint = Paint()..color = _ink;
    for (final offset in _pipOffsets(rollValue, size)) {
      canvas.drawCircle(offset, 5.2, pipPaint);
    }
  }

  List<Offset> _pipOffsets(int value, Size size) {
    final left = size.width * 0.30;
    final centerX = size.width * 0.50;
    final right = size.width * 0.70;
    final top = size.height * 0.30;
    final centerY = size.height * 0.50;
    final bottom = size.height * 0.70;

    return switch (value) {
      1 => [Offset(centerX, centerY)],
      2 => [Offset(left, top), Offset(right, bottom)],
      3 => [Offset(left, top), Offset(centerX, centerY), Offset(right, bottom)],
      4 => [
        Offset(left, top),
        Offset(right, top),
        Offset(left, bottom),
        Offset(right, bottom),
      ],
      5 => [
        Offset(left, top),
        Offset(right, top),
        Offset(centerX, centerY),
        Offset(left, bottom),
        Offset(right, bottom),
      ],
      6 => [
        Offset(left, top),
        Offset(right, top),
        Offset(left, centerY),
        Offset(right, centerY),
        Offset(left, bottom),
        Offset(right, bottom),
      ],
      _ => const [],
    };
  }

  @override
  bool shouldRepaint(covariant _DicePainter oldDelegate) {
    return value != oldDelegate.value;
  }
}
