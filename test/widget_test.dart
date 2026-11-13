import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sikunjung/main.dart';

void main() {
  testWidgets('SiKunjung App smoke test', (WidgetTester tester) async {
    // Build aplikasi SiKunjung
    await tester.pumpWidget(const SiKunjungApp());

    // Memastikan judul aplikasi 'SiKunjung' dan teks 'Selamat Datang!' muncul
    expect(find.text('SiKunjung'), findsWidgets);
    expect(find.text('Selamat Datang!'), findsOneWidget);
  });
}