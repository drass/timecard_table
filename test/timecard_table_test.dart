import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:timecard_table/timecard_table.dart';

void main() {
  testWidgets('MioWidget mostra il testo passato', (WidgetTester tester) async {
    // Monta il widget. Serve un MaterialApp/Scaffold attorno
    // perché molti widget richiedono Directionality, Theme, ecc.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TimecardTable(),
        ),
      ),
    );

    // Verifica che renderizzi quello che ti aspetti
    //expect(find.text('Ciao'), findsOneWidget);
  });

}