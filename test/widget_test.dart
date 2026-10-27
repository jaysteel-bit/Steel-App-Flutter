import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steel_flutter/main.dart';

void main() {
  testWidgets('Digital profile is accessible without onboarding or NFC', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: SteelApp()));

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Alexis Rivera'), findsOneWidget);
    expect(find.text('Add to Contacts'), findsOneWidget);
    expect(find.text('Identity & permissions'), findsOneWidget);
    await tester.pumpWidget(const ProviderScope(child: SizedBox()));
  });
}
