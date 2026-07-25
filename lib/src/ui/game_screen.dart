import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../game/game_controller.dart';
import '../game/game_models.dart';
import 'board/action_row.dart';
import 'board/board_table.dart';
import 'feedback/audio.dart';
import 'feedback/haptics.dart';
import 'feedback/pwa_install_banner.dart';
import 'header/game_header.dart';
import 'theme/flip10_colors.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller = GameController();
  AudioService? _audio;
  bool _isRolling = false;
  int _rollToken = 0;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (_isTestEnvironment()) {
      return;
    }
    try {
      final service = await createAudioService();
      if (!mounted) {
        await service.dispose();
        return;
      }
      setState(() => _audio = service);
    } catch (_) {
      // Audio is optional; never block the UI.
    }
  }

  /// Detect widget-test environment without importing test bindings.
  static bool _isTestEnvironment() {
    final binding = WidgetsBinding.instance;
    final typeName = binding.runtimeType.toString();
    return typeName == 'TestWidgetsFlutterBinding' ||
        typeName == 'AutomatedTestWidgetsFlutterBinding';
  }

  @override
  void dispose() {
    _controller.dispose();
    _audio?.dispose();
    super.dispose();
  }

  void _newGame() {
    _rollToken++;
    if (_isRolling) {
      setState(() => _isRolling = false);
    }
    _controller.newGame();
    FlipHaptics.selection();
    _announce(
      '${_statusCopy(_controller.snapshot)}. ${_actionTitle(_controller.snapshot)}.',
    );
  }

  void _nextRound() {
    _controller.nextRound();
    _announce(
      '${_statusCopy(_controller.snapshot)}. ${_actionTitle(_controller.snapshot)}.',
    );
  }

  Future<void> _roll() async {
    if (_isRolling || _controller.snapshot.phase != GamePhase.waitingForRoll) {
      return;
    }
    setState(() => _isRolling = true);
    final rollToken = ++_rollToken;
    FlipHaptics.light();
    _audio?.play(Sfx.roll);
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted || rollToken != _rollToken) {
      return;
    }
    _controller.roll();
    setState(() => _isRolling = false);
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
    FlipHaptics.selection();
    _announce(_actionDetail(_controller.snapshot));
  }

  void _selectMove(List<int> move) {
    _controller.selectMove(move);
    FlipHaptics.selection();
    _announce(
      'Selected ${move.join(' plus ')}. ${_actionDetail(_controller.snapshot)}',
    );
  }

  void _closeSelection() {
    final total = _controller.snapshot.selectedTotal;
    final shutTheBox =
        _controller.snapshot.activePlayer.openTiles.length ==
        _controller.snapshot.selectedTiles.length;
    _controller.closeSelection();
    FlipHaptics.medium();
    _audio?.play(Sfx.flip);
    if (shutTheBox) {
      _audio?.play(Sfx.success);
      FlipHaptics.heavy();
    }
    _announce(
      'Closed $total. ${_statusCopy(_controller.snapshot)}. ${_actionTitle(_controller.snapshot)}.',
    );
  }

  void _scoreBlockedTurn() {
    final score = _controller.snapshot.activePlayer.remainingTotal;
    _controller.scoreBlockedTurn();
    FlipHaptics.medium();
    _audio?.play(Sfx.blocked);
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
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Flip10Colors.background,
                    Flip10Colors.backgroundSoft,
                  ],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      final snapshot = _controller.snapshot;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isPhone = constraints.maxWidth < 520;
                          final gap = isPhone ? 10.0 : 14.0;
                          final board = BoardTable(
                            snapshot: snapshot,
                            isRolling: _isRolling,
                            isCompact: isPhone,
                            onRoll: _roll,
                            onTilePressed: _toggleTile,
                            onMovePressed: _selectMove,
                            onClose: _closeSelection,
                            onNewGame: _newGame,
                          );
                          final actions = ActionRow(
                            snapshot: snapshot,
                            isRolling: _isRolling,
                            onRoll: _roll,
                            onClose: _closeSelection,
                            onScore: _scoreBlockedTurn,
                            onPlayAgain: _nextRound,
                          );

                          if (isPhone) {
                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  GameHeader(snapshot: snapshot),
                                  SizedBox(height: gap),
                                  Expanded(
                                    child: SingleChildScrollView(child: board),
                                  ),
                                  SizedBox(height: gap),
                                  actions,
                                ],
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                GameHeader(snapshot: snapshot),
                                SizedBox(height: gap),
                                Expanded(
                                  child: SingleChildScrollView(child: board),
                                ),
                                SizedBox(height: gap),
                                actions,
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            if (kIsWeb) const Positioned.fill(child: PwaInstallBanner()),
          ],
        ),
      ),
    );
  }
}

String _statusCopy(GameSnapshot snapshot) {
  return switch (snapshot.phase) {
    GamePhase.waitingForRoll => 'Your turn to roll',
    GamePhase.choosingTiles => 'Select ${snapshot.currentRoll!.total}',
    GamePhase.blocked => 'No legal move',
    GamePhase.complete => snapshot.isShut ? 'Shut the box' : 'Round complete',
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
      'You have ${snapshot.activePlayer.remainingTotal} points open.',
    GamePhase.choosingTiles => _selectionDetail(snapshot),
    GamePhase.blocked =>
      'Score ${snapshot.activePlayer.remainingTotal} to end the round.',
    GamePhase.complete =>
      snapshot.isShut ? 'Shut the box!' : 'Scored ${snapshot.remainingTotal}.',
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
