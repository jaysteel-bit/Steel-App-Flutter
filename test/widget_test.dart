import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:steel_flutter/main.dart';

void main() {
  testWidgets('Steel app loads with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SteelApp()),
    );

    // The app should show "STEEL" text during initialization
    expect(find.text('STEEL'), findsOneWidget);
  });
}
