import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/profile/domain/profile_models.dart';
import 'package:cohv/features/profile/presentation/screen/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProfile = DetailedVolunteerProfile(
    fullName: 'Rajan',
    volunteerId: 'COHV-26-0004',
    designation: 'Public Health',
    gender: 'Male',
    dob: '10 Jul 1997',
    mobileNumber: '9568452369',
    email: 'rajan123@gmail.com',
    village: 'Amrabad',
    panchayat: 'Amrabad',
    block: 'Amrabad',
    division: 'Nagarkurnool Division',
    district: 'Nagarkurnool',
    state: 'Telangana',
    dateOfJoining: '11 Oct 2026',
    qualification: 'Higher Secondary',
    profession: 'Farmer',
    supervisor: 'Dr. Ravi Kumar (ID: 1)',
    status: 'Active',
    lastLogin: '17 Oct 2026, 11:30',
    registrationGps: '28.609306, 77.367452',
    photoUrl: 'volunteers/COHV-26-0004.png',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_valid_token_xyz',
      'volunteer_id': 'COHV-26-0004',
      'volunteer_name': 'Rajan',
    });
    await SessionManager.saveDetailedProfile(testProfile);
  });

  group('Profile & Edit Screen (Approach A) Tests', () {
    test('ApiConstants.resolveImageUrl correctly formats backend Windows and relative upload paths', () {
      // 1. Windows path provided by backend
      const winPath = r'backend\uploads\volunteers\COHV-26-0004.png';
      expect(
        ApiConstants.resolveImageUrl(winPath),
        '${ApiConstants.fileBaseUrl}/uploads/volunteers/COHV-26-0004.png',
      );

      // 2. /api/auth/me relative photo_path
      const mePath = 'volunteers/COHV-26-0005.jpg';
      expect(
        ApiConstants.resolveImageUrl(mePath),
        '${ApiConstants.fileBaseUrl}/uploads/volunteers/COHV-26-0005.jpg',
      );

      // 3. Candidate URLs include direct mount, uploads mount, and backend/uploads mount
      final candidates = ApiConstants.resolveImageCandidateUrls(mePath);
      expect(candidates, containsAll([
        '${ApiConstants.fileBaseUrl}/volunteers/COHV-26-0005.jpg',
        '${ApiConstants.fileBaseUrl}/uploads/volunteers/COHV-26-0005.jpg',
        '${ApiConstants.fileBaseUrl}/backend/uploads/volunteers/COHV-26-0005.jpg',
      ]));

      // 4. Local device file path should return null so Image.file is used
      const localWinPath = r'C:\Users\test\AppData\Local\Temp\photo.jpg';
      expect(ApiConstants.resolveImageUrl(localWinPath), isNull);

      const localAndroidPath = '/data/user/0/org.cohv/cache/photo.jpg';
      expect(ApiConstants.resolveImageUrl(localAndroidPath), isNull);
    });

    test('DetailedVolunteerProfile merges correctly without losing fields', () {
      final serverProfile = DetailedVolunteerProfile(
        fullName: 'Rajan',
        volunteerId: 'COHV-26-0005',
        designation: 'Public Health',
        gender: '—',
        dob: '—',
        mobileNumber: '9568452369',
        email: 'rajan123@gmail.com',
        village: 'Amrabad',
        panchayat: 'Amrabad',
        block: 'Amrabad',
        division: 'Nagarkurnool Division',
        district: 'Nagarkurnool',
        state: 'Telangana',
        dateOfJoining: '—',
        qualification: '—',
        profession: '—',
        supervisor: 'Dr. Ravi Kumar (ID: 1)',
        status: 'ACTIVE',
        lastLogin: 'Active session verified',
        registrationGps: '—',
        photoUrl: 'volunteers/COHV-26-0005.jpg',
      );

      final localEdits = DetailedVolunteerProfile(
        fullName: 'Rajan Kumar',
        volunteerId: 'COHV-26-0005',
        gender: 'Male',
        dob: '10 Jul 1997',
        mobileNumber: '9568452369',
        email: 'rajan123@gmail.com',
        village: 'Amrabad',
        panchayat: 'Amrabad',
        block: 'Amrabad',
        division: 'Nagarkurnool Division',
        district: 'Nagarkurnool',
        state: 'Telangana',
        dateOfJoining: '11 Oct 2026',
        qualification: 'Graduate',
        profession: 'Healthcare Worker / ASHA / ANM',
        supervisor: 'Dr. Ravi Kumar (ID: 1)',
        lastLogin: '—',
        registrationGps: '28.609306, 77.367452',
      );

      final merged = serverProfile.merge(localEdits);

      expect(merged.gender, 'Male');
      expect(merged.dob, '10 Jul 1997');
      expect(merged.qualification, 'Graduate');
      expect(merged.profession, 'Healthcare Worker / ASHA / ANM');
      expect(merged.supervisor, 'Dr. Ravi Kumar (ID: 1)');
      expect(merged.photoUrl, 'volunteers/COHV-26-0005.jpg');
    });

    testWidgets('ProfileScreen renders header with volunteer avatar and Edit profile button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileScreen(volunteerId: 'COHV-26-0004'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Volunteer Name & ID
      expect(find.text('Rajan'), findsOneWidget);
      expect(find.text('COHV-26-0004'), findsOneWidget);

      // Status pill badge
      expect(find.text('ACTIVE'), findsOneWidget);

      // Edit profile action button
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Avatar camera indicator icon
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('Tapping Edit profile navigates to EditProfileScreen (Approach A)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileScreen(volunteerId: 'COHV-26-0004'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap Edit profile button
      final editBtn = find.text('Edit profile');
      expect(editBtn, findsOneWidget);

      await tester.ensureVisible(editBtn);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify EditProfileScreen is shown
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Assigned Administrative Postings (Locked)'), findsOneWidget);
    });
  });
}
