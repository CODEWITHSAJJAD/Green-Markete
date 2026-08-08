import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:green_market/presentation/widgets/green_card.dart';

void main() {
  testWidgets('GreenCard renders child content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GreenCard(
            child: Text('Green Market'),
          ),
        ),
      ),
    );

    expect(find.text('Green Market'), findsOneWidget);
    expect(find.byType(GreenCard), findsOneWidget);
  });
}
