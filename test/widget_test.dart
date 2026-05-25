import 'package:flip10/src/app/flip10_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the game table and setup controls', (tester) async {
    await tester.pumpWidget(const Flip10App());

    expect(find.text('Flip10'), findsOneWidget);
    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Tiles'), findsOneWidget);
    expect(
      find.widgetWithIcon(FilledButton, Icons.casino_rounded),
      findsOneWidget,
    );
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
    expect(find.text('New round'), findsOneWidget);
    expect(find.text('Round'), findsOneWidget);
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
