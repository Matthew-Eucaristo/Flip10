import 'package:flip10/src/app/flip10_app.dart';
import 'package:flip10/src/ui/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('desktop home layout matches golden', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const Flip10App());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GameScreen),
      matchesGoldenFile('goldens/flip10_home_desktop.png'),
    );
  });

  testWidgets('phone home layout matches golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const Flip10App());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GameScreen),
      matchesGoldenFile('goldens/flip10_home_phone.png'),
    );
  });
}
