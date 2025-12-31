// Basic Flutter widget test for GoiryokuKojo app

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goiryoku_kojo/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: GoiryokuKojoApp()));

    // Verify that the app title is displayed
    expect(find.text('語彙力向上'), findsOneWidget);
  });
}
