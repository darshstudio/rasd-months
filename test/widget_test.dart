import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rasd_months/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('RasdApp renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RasdApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RasdApp), findsOneWidget);
  });
}
