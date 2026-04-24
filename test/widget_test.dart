import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_bilgi_mobile/features/auth/auth_screen.dart';

void main() {
  testWidgets('shows auth form controls', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Futbol Bilgi'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('switches auth form to register mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kayıt Ol').first);
    await tester.pumpAndSettle();

    expect(find.text('Kullanıcı adı'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
  });
}
