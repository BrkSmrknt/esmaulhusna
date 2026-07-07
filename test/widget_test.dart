import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esmaulhusna/data/esma_data.dart';
import 'package:esmaulhusna/screens/zikir_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Zikir ekranı ilk ismi ve ebced hedefini gösterir',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ZikirScreen()));
    await tester.pumpAndSettle();

    final first = EsmaData.esmalar.first;
    expect(find.text(first.latin), findsOneWidget);
    expect(find.text('${first.ebced}'), findsWidgets);
  });

  testWidgets('Sonraki isim okuna basınca sayaç yeni hedefe sıfırlanır',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ZikirScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
    await tester.pumpAndSettle();

    final second = EsmaData.esmalar[1];
    expect(find.text(second.latin), findsOneWidget);
    expect(find.text('${second.ebced}'), findsWidgets);
  });

  testWidgets('Önceki isim okuna basınca son isme sarılır',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ZikirScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    final last = EsmaData.esmalar.last;
    expect(find.text(last.latin), findsOneWidget);
  });
}
