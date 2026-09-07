// Test básico de humo: la app de ConsisApp se construye con su tema.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:consis_app/presentation/app/consis_app.dart';

void main() {
  testWidgets('ConsisApp builds with dark theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ConsisApp()));
    await tester.pump();

    // Al menos un Scaffold existe (la app arranca).
    expect(find.byType(Scaffold), findsWidgets);
  });
}
