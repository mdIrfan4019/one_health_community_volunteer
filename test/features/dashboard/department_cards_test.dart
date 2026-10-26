import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/dashboard/domain/department_config.dart';
import 'package:cohv/features/dashboard/presentation/widgets/volunteer_profile_avatar.dart';
import 'package:cohv/features/dashboard/presentation/widgets/dashboard_event_report_card.dart';
import 'package:cohv/features/dashboard/presentation/widgets/quick_actions_event_report_card.dart';
import 'package:cohv/features/dashboard/presentation/widgets/dashboard_hero_card.dart';
import 'package:cohv/features/dashboard/presentation/widgets/quick_actions_hero_card.dart';
import 'package:cohv/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:cohv/features/dashboard/presentation/screen/quick_actions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DepartmentConfig Centralized Mapping Unit Tests', () {
    test('Contains exactly six department configurations with required metadata', () {
      expect(DepartmentConfig.allDepartments.length, equals(6));

      final keys = DepartmentConfig.allDepartments.map((d) => d.departmentKey).toSet();
      expect(keys, containsAll([
        'public_health',
        'rural',
        'urban',
        'environment',
        'animal_husbandry',
        'wildlife',
      ]));
    });

    test('1. Public Health Department configuration matches specification', () {
      final dept = DepartmentConfig.publicHealth;
      expect(dept.displayName, 'Public Health Department');
      expect(dept.dashboardIntroTitle, 'Healthy communities start with you');
      expect(dept.quickActionsIntroTitle, 'People first');
      expect(dept.icon, Icons.person_rounded);
      expect(dept.dashboardDescription, 'Small actions. Healthier communities.');
      expect(dept.quickActionsDescription, 'Capture health concerns and community needs.');
    });

    test('2. Rural Department configuration matches specification', () {
      final dept = DepartmentConfig.rural;
      expect(dept.displayName, 'Rural Department');
      expect(dept.dashboardIntroTitle, 'Stronger rural communities');
      expect(dept.quickActionsIntroTitle, 'Stronger villages');
      expect(dept.icon, Icons.cottage_rounded);
      expect(dept.dashboardDescription, 'Small actions. Stronger villages.');
      expect(dept.quickActionsDescription, 'Bring local observations into one shared picture.');
    });

    test('3. Urban Department configuration matches specification', () {
      final dept = DepartmentConfig.urban;
      expect(dept.displayName, 'Urban Department');
      expect(dept.dashboardIntroTitle, 'Better cities, healthier lives');
      expect(dept.quickActionsIntroTitle, 'Make every place safer');
      expect(dept.icon, Icons.location_city_rounded);
      expect(dept.dashboardDescription, 'Small actions. Healthier urban communities.');
      expect(dept.quickActionsDescription, 'Track community concerns across local areas.');
    });

    test('4. Environment Department configuration matches specification', () {
      final dept = DepartmentConfig.environment;
      expect(dept.displayName, 'Environment Department');
      expect(dept.dashboardIntroTitle, 'Nature in focus');
      expect(dept.quickActionsIntroTitle, 'Nature in focus');
      expect(dept.icon, Icons.eco_rounded);
      expect(dept.dashboardDescription, 'Small actions. A healthier environment.');
      expect(dept.quickActionsDescription, 'Spot environmental risks before they spread.');
    });

    test('5. Animal Husbandry Department configuration matches specification', () {
      final dept = DepartmentConfig.animalHusbandry;
      expect(dept.displayName, 'Animal Husbandry Department');
      expect(dept.dashboardIntroTitle, 'Every animal matters');
      expect(dept.quickActionsIntroTitle, 'Every paw matters');
      expect(dept.icon, Icons.pets_rounded);
      expect(dept.dashboardDescription, 'Small actions. Healthier animals and communities.');
      expect(dept.quickActionsDescription, 'Record animal health events while you are there.');
    });

    test('6. Wildlife Department configuration matches specification', () {
      final dept = DepartmentConfig.wildlife;
      expect(dept.displayName, 'Wildlife Department');
      expect(dept.dashboardIntroTitle, 'Protect the wild');
      expect(dept.quickActionsIntroTitle, 'Protect the wild');
      expect(dept.icon, Icons.forest_rounded);
      expect(dept.dashboardDescription, 'Small actions. A safer environment for wildlife.');
      expect(dept.quickActionsDescription, 'Report wildlife observations and emerging risks.');
    });

    test('Fuzzy and safe string matching handles case variations and minor naming differences', () {
      // Public Health
      expect(DepartmentConfig.fromCohvType('Public Health Department'), equals(DepartmentConfig.publicHealth));
      expect(DepartmentConfig.fromCohvType('public_health'), equals(DepartmentConfig.publicHealth));
      expect(DepartmentConfig.fromCohvType('PUBLIC HEALTH'), equals(DepartmentConfig.publicHealth));

      // Rural
      expect(DepartmentConfig.fromCohvType('Rural Department'), equals(DepartmentConfig.rural));
      expect(DepartmentConfig.fromCohvType('rural'), equals(DepartmentConfig.rural));
      expect(DepartmentConfig.fromCohvType('rural_development'), equals(DepartmentConfig.rural));

      // Urban
      expect(DepartmentConfig.fromCohvType('Urban Department'), equals(DepartmentConfig.urban));
      expect(DepartmentConfig.fromCohvType('urban'), equals(DepartmentConfig.urban));
      expect(DepartmentConfig.fromCohvType('URBAN_DEPARTMENT'), equals(DepartmentConfig.urban));

      // Environment
      expect(DepartmentConfig.fromCohvType('Environment Department'), equals(DepartmentConfig.environment));
      expect(DepartmentConfig.fromCohvType('environment'), equals(DepartmentConfig.environment));
      expect(DepartmentConfig.fromCohvType('nature_ecology'), equals(DepartmentConfig.environment));

      // Animal Husbandry
      expect(DepartmentConfig.fromCohvType('Animal Husbandry Department'), equals(DepartmentConfig.animalHusbandry));
      expect(DepartmentConfig.fromCohvType('animal_husbandry'), equals(DepartmentConfig.animalHusbandry));
      expect(DepartmentConfig.fromCohvType('veterinary'), equals(DepartmentConfig.animalHusbandry));

      // Wildlife
      expect(DepartmentConfig.fromCohvType('Wildlife Department'), equals(DepartmentConfig.wildlife));
      expect(DepartmentConfig.fromCohvType('wildlife'), equals(DepartmentConfig.wildlife));
      expect(DepartmentConfig.fromCohvType('forest'), equals(DepartmentConfig.wildlife));
    });

    test('Unknown or missing department returns generic fallback (Public Health)', () {
      expect(DepartmentConfig.fromCohvType(null), equals(DepartmentConfig.fallback));
      expect(DepartmentConfig.fromCohvType(''), equals(DepartmentConfig.fallback));
      expect(DepartmentConfig.fromCohvType('   '), equals(DepartmentConfig.fallback));
      expect(DepartmentConfig.fromCohvType('unknown_sector_xyz'), equals(DepartmentConfig.fallback));
    });
  });

  group('VolunteerProfileAvatar Widget Tests', () {
    testWidgets('Renders generic profile icon when photo path is null or empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolunteerProfileAvatar(
              photoPath: null,
              size: 48,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('Renders generic profile icon when photo path is "—" or blank', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VolunteerProfileAvatar(
              photoPath: '   ',
              size: 48,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('Tapping avatar invokes onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VolunteerProfileAvatar(
              photoPath: null,
              size: 48,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(VolunteerProfileAvatar));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('Reusable Cards for All Six Departments', () {
    for (final dept in DepartmentConfig.allDepartments) {
      testWidgets('DashboardHeroCard renders correct content for ${dept.displayName}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardHeroCard(
                departmentConfig: dept,
                volunteerName: 'Alex Smith',
                volunteerId: 'COHV-26-0001',
                locationBreadcrumb: 'Mannanur · Amrabad',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('SETU FIELDSPACE'), findsOneWidget);
        expect(find.text('Good day, Alex 👋'), findsOneWidget);
        expect(find.text(dept.dashboardIntroTitle), findsOneWidget);
        expect(find.text(dept.dashboardDescription), findsOneWidget);
        expect(find.text(dept.displayName), findsOneWidget);
        expect(find.text('Mannanur · Amrabad'), findsOneWidget);
        expect(find.text('Report an event'), findsOneWidget);
        expect(find.text('Capture a field observation'), findsOneWidget);
        expect(find.byIcon(dept.icon), findsWidgets);
      });

      testWidgets('QuickActionsHeroCard renders correct content for ${dept.displayName}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickActionsHeroCard(
                departmentConfig: dept,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('YOUR FIELD TOOLKIT'), findsOneWidget);
        expect(find.text(dept.quickActionsIntroTitle), findsOneWidget);
        expect(find.text(dept.quickActionsDescription), findsOneWidget);
        expect(find.text('Ready when you are'), findsOneWidget);
        expect(find.byIcon(dept.icon), findsOneWidget);
      });

      testWidgets('DashboardEventReportCard adapts icon to ${dept.displayName}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardEventReportCard(
                departmentConfig: dept,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Report an event'), findsOneWidget);
        expect(find.text('Capture a field observation'), findsOneWidget);
        expect(find.byIcon(dept.icon), findsOneWidget);
      });

      testWidgets('QuickActionsEventReportCard adapts icon to ${dept.displayName}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickActionsEventReportCard(
                departmentConfig: dept,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Report an event'), findsOneWidget);
        expect(find.text('Open this field workflow'), findsOneWidget);
        expect(find.byIcon(dept.icon), findsOneWidget);
      });

      testWidgets('Standalone QuickActionsScreen adapts to explicit department ${dept.displayName}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickActionsScreen(
                volunteerId: 'COHV-TEST',
                department: dept.displayName,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(dept.quickActionsIntroTitle), findsOneWidget);
        expect(find.text(dept.quickActionsDescription), findsOneWidget);
      });
    }
  });

  group('Account Switching & Session Consistency Tests', () {
    testWidgets('Switching accounts updates Dashboard and QuickActions to new department', (tester) async {
      // 1. Initial login: Animal Husbandry volunteer
      final session1 = UserSession(
        volunteerId: 'COHV-26-0010',
        fullName: 'Dr. Ramesh',
        mobile: '9876543210',
        sector: 'Animal Husbandry Department',
        status: 'Active',
        token: 'token-ramesh',
      );
      await SessionManager.saveSession(session1);

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0010',
            volunteerName: 'Dr. Ramesh',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dashboard shows Animal Husbandry content
      expect(find.text('Good day, Dr. 👋'), findsOneWidget);
      expect(find.text('Every animal matters'), findsOneWidget);
      expect(find.text('Small actions. Healthier animals and communities.'), findsOneWidget);
      expect(find.text('Animal Husbandry Department'), findsOneWidget);
      expect(find.byIcon(Icons.pets_rounded), findsWidgets);

      // Switch to Actions tab
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Quick Actions shows Animal Husbandry content
      expect(find.text('Every paw matters'), findsOneWidget);
      expect(find.text('Record animal health events while you are there.'), findsOneWidget);
      expect(find.byIcon(Icons.pets_rounded), findsWidgets);

      // 2. Switch account: Wildlife volunteer
      final session2 = UserSession(
        volunteerId: 'COHV-26-0020',
        fullName: 'Maya Ranger',
        mobile: '9876543211',
        sector: 'Wildlife Department',
        status: 'Active',
        token: 'token-maya',
      );
      await SessionManager.saveSession(session2);

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0020',
            volunteerName: 'Maya Ranger',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dashboard now reflects Wildlife Department
      expect(find.text('Good day, Maya 👋'), findsOneWidget);
      expect(find.text('Protect the wild'), findsOneWidget);
      expect(find.text('Small actions. A safer environment for wildlife.'), findsOneWidget);
      expect(find.text('Wildlife Department'), findsOneWidget);
      expect(find.byIcon(Icons.forest_rounded), findsWidgets);

      // Switch to Actions tab
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();

      // Quick Actions reflects Wildlife Department
      expect(find.text('Protect the wild'), findsOneWidget);
      expect(find.text('Report wildlife observations and emerging risks.'), findsOneWidget);
      expect(find.byIcon(Icons.forest_rounded), findsWidgets);
    });
  });
}
