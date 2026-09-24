import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear_erp_sheets/main.dart';

void main() {
  testWidgets('shows the setup screen', (tester) async {
    await tester.pumpWidget(const FootwearErpApp());
    expect(find.text('Footwear ERP'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
