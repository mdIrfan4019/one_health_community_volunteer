import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';

void main() {
  group('Inline SearchableDropdownFormField Tests', () {
    final testItems = [
      'Public Health',
      'Animal Husbandry',
      'Environmental Health',
      'Community Volunteer'
    ];

    testWidgets('Renders inline field and opens overlay on tap', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SearchableDropdownFormField<String>(
                fieldId: 'cohv_type',
                items: testItems,
                itemLabel: (item) => item,
                hintText: 'Select COHV Type',
                onChanged: (val) => selectedValue = val,
              ),
            ),
          ),
        ),
      );

      // Verify hint is visible in TextFormField
      expect(find.text('Select COHV Type'), findsOneWidget);

      // Tap the dropdown field to open inline overlay
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      // Verify all options are visible in the floating overlay
      expect(find.text('Public Health'), findsOneWidget);
      expect(find.text('Animal Husbandry'), findsOneWidget);
      expect(find.text('Environmental Health'), findsOneWidget);

      // Tap 'Public Health' option
      await tester.tap(find.text('Public Health'));
      await tester.pumpAndSettle();

      // Verify selection is updated
      expect(selectedValue, 'Public Health');
      expect(find.text('Public Health'), findsOneWidget);
    });

    testWidgets('Filters options dynamically when typing in the text field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SearchableDropdownFormField<String>(
                fieldId: 'cohv_type',
                items: testItems,
                itemLabel: (item) => item,
                hintText: 'Select option',
              ),
            ),
          ),
        ),
      );

      // Tap and enter "h" (as seen in the user screenshot)
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'h');
      await tester.pumpAndSettle();

      // "Public Health" and "Animal Husbandry" and "Environmental Health" contain 'h'
      expect(find.text('Public Health'), findsOneWidget);
      expect(find.text('Animal Husbandry'), findsOneWidget);
      expect(find.text('Environmental Health'), findsOneWidget);
      expect(find.text('Community Volunteer'), findsNothing);

      // Filter with "husbandry"
      await tester.enterText(find.byType(TextFormField), 'husbandry');
      await tester.pumpAndSettle();

      expect(find.text('Animal Husbandry'), findsOneWidget);
      expect(find.text('Public Health'), findsNothing);

      // Select "Animal Husbandry"
      await tester.tap(find.text('Animal Husbandry'));
      await tester.pumpAndSettle();

      expect(find.text('Animal Husbandry'), findsOneWidget);
    });

    testWidgets('Validates properly with FormKey', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: SearchableDropdownFormField<String>(
                fieldId: 'test_field',
                items: testItems,
                itemLabel: (item) => item,
                hintText: 'Select option',
                validator: (val) => val == null ? 'Field is required' : null,
              ),
            ),
          ),
        ),
      );

      final isValid = formKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(isValid, false);
      expect(find.text('Field is required'), findsOneWidget);
    });
  });
}
