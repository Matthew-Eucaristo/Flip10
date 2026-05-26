import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const _prefsPlayerCount = 'flip10.playerCount';
const _prefsRuleset = 'flip10.ruleset';
const _prefsTargetRounds = 'flip10.targetRounds';
const _prefsRecentMatches = 'flip10.recentMatches';
const _playerOptions = [1, 2, 3, 4];
const _roundOptions = [1, 3, 5];

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
  List<String> _recentMatches = const [];
  bool _isRolling = false;
  int _rollToken = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    final playerCount = _supportedPlayerCount(prefs.getInt(_prefsPlayerCount));
    final ruleset = GameRuleset.fromPresetName(prefs.getString(_prefsRuleset));
    final targetRounds = _supportedTargetRounds(
      prefs.getInt(_prefsTargetRounds),
    );
    setState(() {
      _recentMatches = prefs.getStringList(_prefsRecentMatches) ?? const [];
      _controller.newMatch(
        playerCount: playerCount,
        ruleset: ruleset,
        targetRounds: targetRounds,
      );
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final match = _controller.match;
    await prefs.setInt(_prefsPlayerCount, match.playerCount);
    await prefs.setString(_prefsRuleset, match.ruleset.preset.name);
    await prefs.setInt(_prefsTargetRounds, match.targetRounds);
  }

  Future<void> _saveRecentMatchIfComplete() async {
    final match = _controller.match;
    if (!match.isComplete) {
      return;
    }

    final summary = _matchSummary(match);
    final recent = [
      summary,
      ..._recentMatches.where((item) => item != summary),
    ].take(5).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsRecentMatches, recent);
    if (mounted) {
      setState(() {
        _recentMatches = recent;
      });
    }
  }

  String _matchSummary(MatchSnapshot match) {
    final winners = match.winnerIndexes
        .map((index) => 'Player ${index + 1}')
        .join(' and ');
    final best = match.winnerIndexes.isEmpty
        ? null
        : match.cumulativeScores[match.winnerIndexes.first];
    return '$winners - $best total - ${match.ruleset.name} - ${match.targetRounds} rounds';
  }

  void _newMatch({int? playerCount, GameRuleset? ruleset, int? targetRounds}) {
    _rollToken++;
    if (_isRolling) {
      setState(() {
        _isRolling = false;
      });
    }
    _controller.newMatch(
      playerCount: playerCount,
      ruleset: ruleset,
      targetRounds: targetRounds,
    );
    HapticFeedback.selectionClick();
    _savePreferences();
    _announce(
      '${_statusCopy(_controller.snapshot)}. ${_actionTitle(_controller.snapshot)}.',
    );
  }

  void _nextRound() {
    _controller.nextRound();
    HapticFeedback.selectionClick();
    _announce(
      '${_statusCopy(_controller.snapshot)}. ${_actionTitle(_controller.snapshot)}.',
    );
  }

  Future<void> _roll() async {
    if (_isRolling || _controller.snapshot.phase != GamePhase.waitingForRoll) {
      return;
    }
    setState(() {
      _isRolling = true;
    });
    final rollToken = ++_rollToken;
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted || rollToken != _rollToken) {
      return;
    }
    _controller.roll();
    setState(() {
      _isRolling = false;
    });
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
    HapticFeedback.selectionClick();
    _announce(_actionDetail(_controller.snapshot));
  }

  void _selectMove(List<int> move) {
    _controller.selectMove(move);
    HapticFeedback.selectionClick();
    _announce(
      'Selected ${move.join(' plus ')}. ${_actionDetail(_controller.snapshot)}',
    );
  }

  void _closeSelection() {
    final total = _controller.snapshot.selectedTotal;
    _controller.closeSelection();
    HapticFeedback.mediumImpact();
    _saveRecentMatchIfComplete();
    _announce(
      'Closed $total. ${_statusCopy(_controller.snapshot)}. ${_actionTitle(_controller.snapshot)}.',
    );
  }

  void _scoreBlockedTurn() {
    final score = _controller.snapshot.activePlayer.remainingTotal;
    _controller.scoreBlockedTurn();
    HapticFeedback.mediumImpact();
    _saveRecentMatchIfComplete();
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
        final match = _controller.match;

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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isPhone = constraints.maxWidth < 520;
                      final gap = isPhone ? 10.0 : 14.0;

                      return Padding(
                        padding: EdgeInsets.all(isPhone ? 10 : 16),
                        child: Column(
                          children: [
                            _Header(
                              snapshot: snapshot,
                              match: match,
                              recentMatches: _recentMatches,
                              onNewMatch: () => _newMatch(),
                            ),
                            SizedBox(height: gap),
                            _SetupBar(
                              match: match,
                              onPlayersChanged: (count) {
                                _newMatch(playerCount: count);
                              },
                              onRulesetChanged: (ruleset) {
                                _newMatch(ruleset: ruleset);
                              },
                              onTargetRoundsChanged: (rounds) {
                                _newMatch(targetRounds: rounds);
                              },
                            ),
                            SizedBox(height: gap),
                            Expanded(
                              child: _ResponsivePlayArea(
                                snapshot: snapshot,
                                match: match,
                                isRolling: _isRolling,
                                onRoll: _roll,
                                onTilePressed: _toggleTile,
                                onMovePressed: _selectMove,
                                onClose: _closeSelection,
                                onScore: _scoreBlockedTurn,
                                onNextRound: _nextRound,
                                onNewMatch: () => _newMatch(),
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
          ),
        );
      },
    );
  }
}

int _supportedPlayerCount(int? playerCount) {
  final value = playerCount ?? 1;
  return value.clamp(_playerOptions.first, _playerOptions.last).toInt();
}

int _supportedTargetRounds(int? targetRounds) {
  final value = targetRounds ?? 3;
  return _roundOptions.contains(value) ? value : 3;
}

class _ResponsivePlayArea extends StatelessWidget {
  const _ResponsivePlayArea({
    required this.snapshot,
    required this.match,
    required this.isRolling,
    required this.onRoll,
    required this.onTilePressed,
    required this.onMovePressed,
    required this.onClose,
    required this.onScore,
    required this.onNextRound,
    required this.onNewMatch,
  });

  final GameSnapshot snapshot;
  final MatchSnapshot match;
  final bool isRolling;
  final VoidCallback onRoll;
  final ValueChanged<int> onTilePressed;
  final ValueChanged<List<int>> onMovePressed;
  final VoidCallback onClose;
  final VoidCallback onScore;
  final VoidCallback onNextRound;
  final VoidCallback onNewMatch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final board = _BoardTable(
          snapshot: snapshot,
          match: match,
          isRolling: isRolling,
          isCompact: isCompact,
          showActions: !isCompact,
          onRoll: onRoll,
          onTilePressed: onTilePressed,
          onMovePressed: onMovePressed,
          onClose: onClose,
          onScore: onScore,
          onNextRound: onNextRound,
          onNewMatch: onNewMatch,
        );
        final panel = _RoundPanel(
          snapshot: snapshot,
          match: match,
          isCompact: isCompact,
        );

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

        final compactBoardHeight = snapshot.tileCount >= 12 ? 560.0 : 500.0;
        final boardHeight = constraints.maxWidth < 520
            ? compactBoardHeight
            : 540.0;

        final content = SingleChildScrollView(
          padding: EdgeInsets.only(bottom: isCompact ? 12 : 0),
          child: Column(
            children: [
              SizedBox(height: boardHeight, child: board),
              SizedBox(height: isCompact ? 10 : 14),
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
              match: match,
              isRolling: isRolling,
              onRoll: onRoll,
              onClose: onClose,
              onScore: onScore,
              onNextRound: onNextRound,
              onNewMatch: onNewMatch,
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.snapshot,
    required this.match,
    required this.recentMatches,
    required this.onNewMatch,
  });

  final GameSnapshot snapshot;
  final MatchSnapshot match;
  final List<String> recentMatches;
  final VoidCallback onNewMatch;

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

    final helpAction = IconButton.outlined(
      onPressed: () => _showRulesSheet(context, match, recentMatches),
      icon: const Icon(Icons.help_outline_rounded),
      tooltip: 'Rules and recent matches',
    );
    final newMatchIconAction = IconButton.outlined(
      onPressed: onNewMatch,
      icon: const Icon(Icons.refresh_rounded),
      tooltip: 'New match',
    );
    final newMatchAction = OutlinedButton.icon(
      onPressed: onNewMatch,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('New match'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              helpAction,
              const SizedBox(width: 6),
              newMatchIconAction,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            helpAction,
            const SizedBox(width: 8),
            newMatchAction,
          ],
        );
      },
    );
  }

  void _showRulesSheet(
    BuildContext context,
    MatchSnapshot match,
    List<String> recentMatches,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _panel,
      builder: (context) =>
          _RulesSheet(match: match, recentMatches: recentMatches),
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

class _RulesSheet extends StatelessWidget {
  const _RulesSheet({required this.match, required this.recentMatches});

  final MatchSnapshot match;
  final List<String> recentMatches;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rules',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _ivory,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _RuleLine(
              icon: Icons.casino_rounded,
              title: 'Roll and close tiles',
              body:
                  'Choose open tiles matching the dice total. Closed tiles stay down for that turn.',
            ),
            _RuleLine(
              icon: Icons.flag_rounded,
              title: 'Blocked turns score open tiles',
              body:
                  'When no legal move exists, the remaining open tiles become that player\'s score.',
            ),
            _RuleLine(
              icon: Icons.emoji_events_rounded,
              title: 'Lowest total wins',
              body:
                  'A match adds each round score. The lowest total after ${match.targetRounds} rounds wins.',
            ),
            _RuleLine(
              icon: Icons.tune_rounded,
              title: match.ruleset.name,
              body: match.ruleset.useSingleDieWhenLow
                  ? 'Uses ${match.ruleset.tileCount} tiles and rolls one die once every open tile is 6 or lower.'
                  : 'Uses ${match.ruleset.tileCount} tiles and rolls two dice throughout the round.',
            ),
            if (recentMatches.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Recent',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _ivory,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in recentMatches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ivory.withValues(alpha: 0.74),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _ivory,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _ivory.withValues(alpha: 0.72),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupBar extends StatelessWidget {
  const _SetupBar({
    required this.match,
    required this.onPlayersChanged,
    required this.onRulesetChanged,
    required this.onTargetRoundsChanged,
  });

  final MatchSnapshot match;
  final ValueChanged<int> onPlayersChanged;
  final ValueChanged<GameRuleset> onRulesetChanged;
  final ValueChanged<int> onTargetRoundsChanged;

  @override
  Widget build(BuildContext context) {
    final playerSelector = _SegmentGroup(
      label: 'Players',
      child: SegmentedButton<int>(
        segments: [
          for (final count in _playerOptions)
            ButtonSegment(value: count, label: Text('$count')),
        ],
        selected: {match.playerCount},
        onSelectionChanged: (selection) {
          onPlayersChanged(selection.first);
        },
      ),
    );
    final rulesetSelector = _SegmentGroup(
      label: 'Rules',
      child: SegmentedButton<RulesetPreset>(
        segments: [
          for (final ruleset in GameRuleset.presets)
            ButtonSegment(
              value: ruleset.preset,
              label: Text('${ruleset.tileCount}'),
              tooltip: ruleset.name,
            ),
        ],
        selected: {match.ruleset.preset},
        onSelectionChanged: (selection) {
          onRulesetChanged(
            GameRuleset.presets.firstWhere(
              (ruleset) => ruleset.preset == selection.first,
            ),
          );
        },
      ),
    );
    final roundsSelector = _SegmentGroup(
      label: 'Rounds',
      child: SegmentedButton<int>(
        segments: [
          for (final rounds in _roundOptions)
            ButtonSegment(value: rounds, label: Text('$rounds')),
        ],
        selected: {match.targetRounds},
        onSelectionChanged: (selection) {
          onTargetRoundsChanged(selection.first);
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
            if (constraints.maxWidth < 520) {
              return _CompactSetupSummary(
                match: match,
                onPressed: () => _showSetupSheet(context),
              );
            }

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [playerSelector, rulesetSelector, roundsSelector],
            );
          },
        ),
      ),
    );
  }

  void _showSetupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _panel,
      builder: (context) => _SetupSheet(
        match: match,
        onPlayersChanged: (count) {
          Navigator.of(context).pop();
          onPlayersChanged(count);
        },
        onRulesetChanged: (ruleset) {
          Navigator.of(context).pop();
          onRulesetChanged(ruleset);
        },
        onTargetRoundsChanged: (rounds) {
          Navigator.of(context).pop();
          onTargetRoundsChanged(rounds);
        },
      ),
    );
  }
}

class _CompactSetupSummary extends StatelessWidget {
  const _CompactSetupSummary({required this.match, required this.onPressed});

  final MatchSnapshot match;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SetupPill(
                icon: Icons.person_rounded,
                label: 'P${match.playerCount}',
              ),
              _SetupPill(
                icon: Icons.apps_rounded,
                label: '${match.ruleset.tileCount} tiles',
              ),
              _SetupPill(
                icon: Icons.flag_rounded,
                label: '${match.targetRounds} rounds',
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: onPressed,
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Change setup',
        ),
      ],
    );
  }
}

class _SetupPill extends StatelessWidget {
  const _SetupPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.11),
        border: Border.all(color: _accent.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _accent, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _ivory,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupSheet extends StatelessWidget {
  const _SetupSheet({
    required this.match,
    required this.onPlayersChanged,
    required this.onRulesetChanged,
    required this.onTargetRoundsChanged,
  });

  final MatchSnapshot match;
  final ValueChanged<int> onPlayersChanged;
  final ValueChanged<GameRuleset> onRulesetChanged;
  final ValueChanged<int> onTargetRoundsChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Setup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _ivory,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _SegmentGroup.stacked(
              label: 'Players',
              child: SegmentedButton<int>(
                segments: [
                  for (final count in _playerOptions)
                    ButtonSegment(value: count, label: Text('$count')),
                ],
                selected: {match.playerCount},
                onSelectionChanged: (selection) {
                  onPlayersChanged(selection.first);
                },
              ),
            ),
            const SizedBox(height: 14),
            _SegmentGroup.stacked(
              label: 'Rules',
              child: SegmentedButton<RulesetPreset>(
                segments: [
                  for (final ruleset in GameRuleset.presets)
                    ButtonSegment(
                      value: ruleset.preset,
                      label: Text('${ruleset.tileCount}'),
                      tooltip: ruleset.name,
                    ),
                ],
                selected: {match.ruleset.preset},
                onSelectionChanged: (selection) {
                  onRulesetChanged(
                    GameRuleset.presets.firstWhere(
                      (ruleset) => ruleset.preset == selection.first,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _SegmentGroup.stacked(
              label: 'Rounds',
              child: SegmentedButton<int>(
                segments: [
                  for (final rounds in _roundOptions)
                    ButtonSegment(value: rounds, label: Text('$rounds')),
                ],
                selected: {match.targetRounds},
                onSelectionChanged: (selection) {
                  onTargetRoundsChanged(selection.first);
                },
              ),
            ),
          ],
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
        mainAxisSize: MainAxisSize.min,
        children: [labelWidget, const SizedBox(height: 5), child],
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
    required this.isRolling,
    required this.isCompact,
    required this.showActions,
    required this.onRoll,
    required this.onTilePressed,
    required this.onMovePressed,
    required this.onClose,
    required this.onScore,
    required this.match,
    required this.onNextRound,
    required this.onNewMatch,
  });

  final GameSnapshot snapshot;
  final MatchSnapshot match;
  final bool isRolling;
  final bool isCompact;
  final bool showActions;
  final VoidCallback onRoll;
  final ValueChanged<int> onTilePressed;
  final ValueChanged<List<int>> onMovePressed;
  final VoidCallback onClose;
  final VoidCallback onScore;
  final VoidCallback onNextRound;
  final VoidCallback onNewMatch;

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
        padding: EdgeInsets.all(widget.isCompact ? 8 : 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CustomPaint(
            painter: const _FeltPainter(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _felt,
                border: Border.all(
                  color: _woodLight,
                  width: widget.isCompact ? 2 : 3,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(widget.isCompact ? 10 : 16),
                child: Column(
                  children: [
                    _ActivePlayerBand(
                      player: activePlayer,
                      isCompact: widget.isCompact,
                    ),
                    SizedBox(height: widget.isCompact ? 12 : 18),
                    _DiceRow(
                      roll: roll,
                      isRolling: widget.isRolling,
                      isCompact: widget.isCompact,
                    ),
                    SizedBox(height: widget.isCompact ? 10 : 16),
                    _ActionPrompt(
                      snapshot: snapshot,
                      isCompact: widget.isCompact,
                    ),
                    SizedBox(height: widget.isCompact ? 10 : 16),
                    Expanded(
                      child: Center(
                        child: _TileRack(
                          snapshot: snapshot,
                          previewTiles: _previewTiles,
                          isCompact: widget.isCompact,
                          onTilePressed: widget.onTilePressed,
                        ),
                      ),
                    ),
                    _MoveHints(
                      snapshot: snapshot,
                      validMoves: validMoves,
                      isCompact: widget.isCompact,
                      onPreviewMove: _previewMove,
                      onMovePressed: widget.onMovePressed,
                    ),
                    if (widget.showActions) ...[
                      const SizedBox(height: 12),
                      _ActionRow(
                        snapshot: snapshot,
                        isRolling: widget.isRolling,
                        onRoll: widget.onRoll,
                        onClose: widget.onClose,
                        onScore: widget.onScore,
                        match: widget.match,
                        onNextRound: widget.onNextRound,
                        onNewMatch: widget.onNewMatch,
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
  const _ActionPrompt({required this.snapshot, required this.isCompact});

  final GameSnapshot snapshot;
  final bool isCompact;

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
                fontSize: isCompact ? 21 : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _actionDetail(snapshot),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _ivory.withValues(alpha: 0.76),
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 13 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePlayerBand extends StatelessWidget {
  const _ActivePlayerBand({required this.player, required this.isCompact});

  final PlayerBoard player;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final playerColor = _playerColors[player.index % _playerColors.length];

    return Row(
      children: [
        Container(
          width: isCompact ? 10 : 12,
          height: isCompact ? 32 : 36,
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
              fontSize: isCompact ? 22 : null,
            ),
          ),
        ),
        Text(
          '${player.remainingTotal}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ivory,
            fontWeight: FontWeight.w800,
            fontSize: isCompact ? 22 : null,
          ),
        ),
      ],
    );
  }
}

class _DiceRow extends StatelessWidget {
  const _DiceRow({
    required this.roll,
    required this.isRolling,
    required this.isCompact,
  });

  final DiceRoll? roll;
  final bool isRolling;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final values = isRolling ? null : roll?.values;
    return Semantics(
      liveRegion: true,
      label: isRolling
          ? 'Rolling dice'
          : roll == null
          ? 'Dice not rolled'
          : 'Rolled ${roll!.total}',
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
            isRolling
                ? 'rolling'
                : roll == null
                ? 'empty'
                : '${roll!.first}-${roll!.second}',
          ),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRolling) ...[
              _RollingDiceFace(isCompact: isCompact),
              SizedBox(width: isCompact ? 10 : 12),
              _RollingDiceFace(
                isCompact: isCompact,
                delay: const Duration(milliseconds: 120),
              ),
            ] else if (values == null) ...[
              _DiceFace(value: null, isCompact: isCompact),
              SizedBox(width: isCompact ? 10 : 12),
              _DiceFace(value: null, isCompact: isCompact),
            ] else
              for (var index = 0; index < values.length; index++) ...[
                _DiceFace(value: values[index], isCompact: isCompact),
                if (index != values.length - 1)
                  SizedBox(width: isCompact ? 10 : 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({required this.value, required this.isCompact});

  final int? value;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: isCompact ? 56 : 66,
      child: CustomPaint(painter: _DicePainter(value)),
    );
  }
}

class _RollingDiceFace extends StatelessWidget {
  const _RollingDiceFace({required this.isCompact, this.delay = Duration.zero});

  final bool isCompact;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(delay),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        final turn = value + delay.inMilliseconds / 1000;
        return Transform.rotate(
          angle: turn * 5.8,
          child: Transform.scale(scale: 0.94 + (value * 0.08), child: child),
        );
      },
      child: _DiceFace(value: null, isCompact: isCompact),
    );
  }
}

class _TileRack extends StatelessWidget {
  const _TileRack({
    required this.snapshot,
    required this.previewTiles,
    required this.isCompact,
    required this.onTilePressed,
  });

  final GameSnapshot snapshot;
  final Set<int> previewTiles;
  final bool isCompact;
  final ValueChanged<int> onTilePressed;

  @override
  Widget build(BuildContext context) {
    final activePlayer = snapshot.activePlayer;
    final target = snapshot.currentRoll?.total;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = isCompact ? 7.0 : 8.0;
        final idealTileWidth = isCompact ? 48.0 : 52.0;
        final minTileWidth = isCompact ? 42.0 : 44.0;
        final maxTileWidth = isCompact ? 50.0 : 52.0;
        final columns =
            ((constraints.maxWidth + spacing) / (idealTileWidth + spacing))
                .floor()
                .clamp(1, snapshot.tileCount)
                .toInt();
        final tileWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .clamp(minTileWidth, maxTileWidth)
                .toDouble();
        final tileHeight = tileWidth * (isCompact ? 1.54 : 1.65);

        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: isCompact ? 8 : 10,
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
    required this.isCompact,
    required this.onPreviewMove,
    required this.onMovePressed,
  });

  final GameSnapshot snapshot;
  final List<List<int>> validMoves;
  final bool isCompact;
  final ValueChanged<List<int>?> onPreviewMove;
  final ValueChanged<List<int>> onMovePressed;

  @override
  Widget build(BuildContext context) {
    if (snapshot.phase != GamePhase.choosingTiles || validMoves.isEmpty) {
      return SizedBox(height: isCompact ? 58 : 66);
    }

    final visibleMoves = validMoves.take(6).toList();
    return SizedBox(
      height: isCompact ? 58 : 66,
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
          SizedBox(height: isCompact ? 4 : 6),
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
    required this.isRolling,
    required this.match,
    required this.onRoll,
    required this.onClose,
    required this.onScore,
    required this.onNextRound,
    required this.onNewMatch,
    this.expandPrimary = false,
  });

  final GameSnapshot snapshot;
  final bool isRolling;
  final MatchSnapshot match;
  final VoidCallback onRoll;
  final VoidCallback onClose;
  final VoidCallback onScore;
  final VoidCallback onNextRound;
  final VoidCallback onNewMatch;
  final bool expandPrimary;

  @override
  Widget build(BuildContext context) {
    final canClose =
        snapshot.phase == GamePhase.choosingTiles && snapshot.isSelectionValid;
    final selectedTotal = snapshot.selectedTotal;
    final primaryAction = FilledButton.icon(
      onPressed: snapshot.phase == GamePhase.waitingForRoll && !isRolling
          ? onRoll
          : null,
      icon: const Icon(Icons.casino_rounded),
      label: Text(isRolling ? 'Rolling...' : 'Roll dice'),
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
        GamePhase.complete => _NextMatchButton(
          match: match,
          onNextRound: onNextRound,
          onNewMatch: onNewMatch,
        ),
      };

      return Row(children: [Expanded(child: compactAction)]);
    }

    final actions = [
      primaryAction,
      closeAction,
      if (snapshot.phase == GamePhase.blocked)
        _ScoreButton(snapshot: snapshot, onScore: onScore),
      if (snapshot.phase == GamePhase.complete)
        _NextMatchButton(
          match: match,
          onNextRound: onNextRound,
          onNewMatch: onNewMatch,
        ),
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

class _NextMatchButton extends StatelessWidget {
  const _NextMatchButton({
    required this.match,
    required this.onNextRound,
    required this.onNewMatch,
  });

  final MatchSnapshot match;
  final VoidCallback onNextRound;
  final VoidCallback onNewMatch;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: match.isComplete ? onNewMatch : onNextRound,
      icon: Icon(
        match.isComplete ? Icons.refresh_rounded : Icons.skip_next_rounded,
      ),
      label: Text(match.isComplete ? 'New match' : 'Next round'),
    );
  }
}

class _MobileActionDock extends StatelessWidget {
  const _MobileActionDock({
    required this.snapshot,
    required this.match,
    required this.isRolling,
    required this.onRoll,
    required this.onClose,
    required this.onScore,
    required this.onNextRound,
    required this.onNewMatch,
  });

  final GameSnapshot snapshot;
  final MatchSnapshot match;
  final bool isRolling;
  final VoidCallback onRoll;
  final VoidCallback onClose;
  final VoidCallback onScore;
  final VoidCallback onNextRound;
  final VoidCallback onNewMatch;

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
          match: match,
          isRolling: isRolling,
          expandPrimary: true,
          onRoll: onRoll,
          onClose: onClose,
          onScore: onScore,
          onNextRound: onNextRound,
          onNewMatch: onNewMatch,
        ),
      ),
    );
  }
}

class _RoundPanel extends StatelessWidget {
  const _RoundPanel({
    required this.snapshot,
    required this.match,
    required this.isCompact,
  });

  final GameSnapshot snapshot;
  final MatchSnapshot match;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Match',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: isCompact ? 20 : null,
                    ),
                  ),
                ),
                Text(
                  '${match.completedRounds}/${match.targetRounds}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _ivory.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${match.ruleset.name} - Round ${match.currentRoundNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _ivory.withValues(alpha: 0.66),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isCompact ? 10 : 12),
            for (final player in snapshot.players) ...[
              _PlayerPanelRow(
                player: player,
                tileCount: snapshot.tileCount,
                cumulativeScore: match.cumulativeScores[player.index],
                isCompact: isCompact,
                isActive:
                    snapshot.phase != GamePhase.complete &&
                    player.index == snapshot.activePlayerIndex,
              ),
              if (player.index != snapshot.players.last.index)
                SizedBox(height: isCompact ? 8 : 10),
            ],
            if (match.roundHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _RoundHistory(records: match.roundHistory),
            ],
            if (snapshot.phase == GamePhase.complete) ...[
              const SizedBox(height: 16),
              _ResultBanner(snapshot: snapshot, match: match),
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
  const _ResultBanner({required this.snapshot, required this.match});

  final GameSnapshot snapshot;
  final MatchSnapshot match;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: match.isComplete
          ? _matchOutcomeCopy(match)
          : _outcomeCopy(snapshot),
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
                  match.isComplete
                      ? _matchOutcomeCopy(match)
                      : _outcomeCopy(snapshot),
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

String _matchOutcomeCopy(MatchSnapshot match) {
  final winners = match.winnerIndexes
      .map((index) => 'Player ${index + 1}')
      .join(' and ');
  if (winners.isEmpty) {
    return 'Match complete';
  }
  final score = match.cumulativeScores[match.winnerIndexes.first];
  return '$winners win the match with $score';
}

class _PlayerPanelRow extends StatelessWidget {
  const _PlayerPanelRow({
    required this.player,
    required this.tileCount,
    required this.cumulativeScore,
    required this.isCompact,
    required this.isActive,
  });

  final PlayerBoard player;
  final int tileCount;
  final int cumulativeScore;
  final bool isCompact;
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
      padding: EdgeInsets.all(isCompact ? 9 : 10),
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
                    fontSize: isCompact ? 15 : null,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    scoreText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: player.isShut ? _brass : _ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: isCompact ? 15 : null,
                    ),
                  ),
                  Text(
                    'total $cumulativeScore',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _ivory.withValues(alpha: 0.52),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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

class _RoundHistory extends StatelessWidget {
  const _RoundHistory({required this.records});

  final List<RoundRecord> records;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: _ivory,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final record in records.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    'R${record.roundNumber}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _brass,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.scores.join(' / '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ivory.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
