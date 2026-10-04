import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rasd_months/core/widgets/app_dropdown.dart';

void main() {
  testWidgets('AppDropdown renders cleanly under unbounded horizontal constraints', (WidgetTester tester) async {
    String? selected = 'item1';

    // Simulate the exact condition: SingleChildScrollView (horizontal) -> Row -> AppDropdown with width: null
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Label: '),
                AppDropdown<String>(
                  value: selected,
                  items: const [
                    DropdownMenuItem(value: 'item1', child: Text('العنصر الأول')),
                    DropdownMenuItem(value: 'item2', child: Text('العنصر الثاني')),
                  ],
                  onChanged: (val) {
                    selected = val;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify it renders without throwing hasSize or RenderFlex assertions
    expect(find.byType(AppDropdown<String>), findsOneWidget);
    expect(find.text('العنصر الأول'), findsOneWidget);
  });

  testWidgets('AppDropdown handles duplicate item values without throwing duplicate GlobalKey error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDropdown<String>(
            value: 'dup',
            items: const [
              DropdownMenuItem(value: 'dup', child: Text('Duplicate 1')),
              DropdownMenuItem(value: 'dup', child: Text('Duplicate 2')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(AppDropdown<String>), findsOneWidget);
  });

  testWidgets('AppDropdown safely handles value not existing in items without throwing assertion error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDropdown<String>(
            value: 'non_existent_value',
            hint: 'اختر قيمة',
            items: const [
              DropdownMenuItem(value: 'val1', child: Text('Value 1')),
              DropdownMenuItem(value: 'val2', child: Text('Value 2')),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(AppDropdown<String>), findsOneWidget);
    expect(find.text('اختر قيمة'), findsOneWidget);
  });
}
