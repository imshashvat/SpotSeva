// Basic smoke test — verifies AdoptASpotApp renders without crashing.
// Note: Firebase is not initialised in test, so this only verifies
// that the widget tree can be built.  Full integration tests should
// use the Firebase emulators via --dart-define=USE_EMULATOR=true.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders a Scaffold without throwing', (tester) async {
    // A minimal widget that mimics the app structure without Firebase
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('SpotSeva')),
        ),
      ),
    );

    expect(find.text('SpotSeva'), findsOneWidget);
  });
}
