import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bolao_copa_web/app.dart';

void main() {
  testWidgets('app builds with router', (WidgetTester tester) async {
    await tester.pumpWidget(const BolaoCopaApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
