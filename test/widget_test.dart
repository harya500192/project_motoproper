// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_motoproper/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // FIX: Tambahkan parameter required 'isLoggedIn' dan 'initError'
    await tester.pumpWidget(const MyApp(isLoggedIn: false, initError: null));

    // Verify that our title text appears.
    expect(find.text('Login MotoProper'), findsOneWidget);
    // Jika Anda ingin menguji Home, ganti isLoggedIn: true
    
  });
}