import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cohv/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:cohv/core/theme/app_colors.dart';

void main() {
  group('SignInScreen UI Redesign Tests', () {
    testWidgets('Renders all branding, input fields, and footer elements matching target mockup', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header branding
      expect(find.text('SETU'), findsOneWidget);
      expect(find.text('Breaching the Silos'), findsOneWidget);

      // Verify SETU color is setuGreen
      final setuWidget = tester.widget<Text>(find.text('SETU'));
      expect(setuWidget.style?.color, equals(AppColors.setuGreen));

      // 2. Authentication Card
      expect(find.text('Sign in'), findsWidgets); // Header and Button
      expect(
        find.text('Sign in with your Volunteer ID or mobile number and your PIN.'),
        findsOneWidget,
      );

      // Input field hints
      expect(find.text('COHV-26-0016 or 10-digit mobile'), findsOneWidget);
      expect(find.text('••••'), findsOneWidget);

      // Action links
      expect(find.text('Forgot password / PIN?'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);

      // 3. Footer branding and disclaimers
      expect(
        find.text('National Centre for Disease Control · National One Health Mission'),
        findsOneWidget,
      );
    });

    testWidgets('Toggles PIN visibility when eye icon button is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially obscured
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Tap toggle
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('Submitting empty form triggers validation error messages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Sign in Elevated button (the second 'Sign in' text)
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign in');
      expect(signInButton, findsOneWidget);

      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your Volunteer ID or mobile number'),
        findsOneWidget,
      );
      expect(
        find.text('Please enter your 4–6 digit PIN'),
        findsOneWidget,
      );
    });
  });
}
