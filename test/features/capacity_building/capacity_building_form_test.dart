import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';
import 'package:cohv/features/capacity_building/domain/capacity_building_models.dart';
import 'package:cohv/features/capacity_building/screens/new_training_screen.dart';
import 'package:cohv/features/capacity_building/screens/new_training_attended_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Capacity Building - New Training Imparted Screen', () {
    testWidgets('Does NOT auto-select training on initial load, shows hint "Select"', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: NewTrainingScreen(volunteerId: 'COHV-26-0005'),
        ),
      );

      await tester.pumpAndSettle();

      // Find SearchableDropdownFormField
      final dropdownFinder = find.byType(SearchableDropdownFormField<TrainingMasterModel>);
      expect(dropdownFinder, findsOneWidget);

      // Verify hint is 'Select' and not auto-selected to any training
      expect(find.text('Select'), findsWidgets);
      expect(find.text('Initial COHV Training'), findsNothing);

      // Verify submitting without selection shows validation error
      final saveBtn = find.text('Save');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please select a training'), findsWidgets);
    });

    testWidgets('Opens searchable dropdown overlay and selects training option', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: NewTrainingScreen(volunteerId: 'COHV-26-0005'),
        ),
      );

      await tester.pumpAndSettle();

      // Find TextFormField in dropdown
      final textFormFieldFinder = find.descendant(
        of: find.byType(SearchableDropdownFormField<TrainingMasterModel>),
        matching: find.byType(TextFormField),
      );
      expect(textFormFieldFinder, findsOneWidget);

      // Tap to open searchable dropdown overlay
      await tester.tap(textFormFieldFinder);
      await tester.pumpAndSettle();

      // Should show options in the overlay
      expect(find.text('Initial COHV Training'), findsWidgets);

      // Filter by typing 'Refresher'
      await tester.enterText(textFormFieldFinder, 'Refresher');
      await tester.pumpAndSettle();

      expect(find.text('Refresher Training'), findsWidgets);

      // Tap to select option
      await tester.tap(find.text('Refresher Training').first);
      await tester.pumpAndSettle();

      // Selected option should now be present in the field
      expect(find.text('Refresher Training'), findsOneWidget);
    });
  });

  group('Capacity Building - New Training Attended Screen', () {
    testWidgets('Does NOT auto-select training on initial load, shows hint "Select"', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: NewTrainingAttendedScreen(volunteerId: 'COHV-26-0005'),
        ),
      );

      await tester.pumpAndSettle();

      // Find SearchableDropdownFormField
      final dropdownFinder = find.byType(SearchableDropdownFormField<TrainingMasterModel>);
      expect(dropdownFinder, findsOneWidget);

      // Verify hint is 'Select' and not auto-selected to any training
      expect(find.text('Select'), findsWidgets);
      expect(find.text('Initial COHV Training'), findsNothing);

      // Verify validation triggers if empty
      final submitBtn = find.text('Save');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please select a training'), findsWidgets);
    });

    testWidgets('Opens searchable dropdown overlay and selects training option', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: NewTrainingAttendedScreen(volunteerId: 'COHV-26-0005'),
        ),
      );

      await tester.pumpAndSettle();

      // Find TextFormField in dropdown
      final textFormFieldFinder = find.descendant(
        of: find.byType(SearchableDropdownFormField<TrainingMasterModel>),
        matching: find.byType(TextFormField),
      );
      expect(textFormFieldFinder, findsOneWidget);

      // Tap to open searchable dropdown overlay
      await tester.tap(textFormFieldFinder);
      await tester.pumpAndSettle();

      // Should show options in the overlay
      expect(find.text('Initial COHV Training'), findsWidgets);

      // Select 'Initial COHV Training'
      await tester.tap(find.text('Initial COHV Training').first);
      await tester.pumpAndSettle();

      // Selected option should now be present in the field
      expect(find.text('Initial COHV Training'), findsOneWidget);
    });
  });
}
