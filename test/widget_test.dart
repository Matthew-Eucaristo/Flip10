import 'package:flip10/src/app/flip10_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the game table and setup controls', (tester) async {
    await tester.pumpWidget(const Flip10App());

    expect(find.text('Flip10'), findsOneWidget);
    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Rounds'), findsOneWidget);
    expect(find.text('Roll dice'), findsWidgets);
    expect(
      find.widgetWithIcon(FilledButton, Icons.casino_rounded),
      findsOneWidget,
    );
  });

  testWidgets('shows action-led roll results and move hints', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const Flip10App());

    await tester.tap(find.widgetWithText(FilledButton, 'Roll dice'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Choose'), findsWidgets);
    expect(find.text('Best moves'), findsOneWidget);
  });

  testWidgets('fits the main game surface on a narrow phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const Flip10App());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Roll dice'), findsOneWidget);
    expect(find.text('New match'), findsOneWidget);
    expect(find.text('Match'), findsOneWidget);
  });

  testWidgets('opens the rules and recent matches sheet', (tester) async {
    await tester.pumpWidget(const Flip10App());

    await tester.tap(find.byTooltip('Rules and recent matches'));
    await tester.pumpAndSettle();

    expect(find.text('Rules'), findsWidgets);
    expect(find.text('Lowest total wins'), findsOneWidget);
    expect(find.text('Flip10'), findsWidgets);
  });

  testWidgets('normalizes stale saved setup values', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flip10.playerCount': 99,
      'flip10.targetRounds': 2,
    });

    await tester.pumpWidget(const Flip10App());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Roll dice'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('meets core accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const Flip10App());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      handle.dispose();
    }
  });
}
