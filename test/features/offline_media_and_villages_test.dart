import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cohv/core/database/master_data_cache_service.dart';
import 'package:cohv/core/services/local_media_cache_service.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/awareness/data/awareness_api_service.dart';
import 'package:cohv/features/referrals/data/referrals_api_service.dart';
import 'package:cohv/features/sample_reprot/data/sample_support_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Offline Villages & Media Cache Tests', () {
    test('1. MasterDataCacheService.fallbackVillages returns Amrabad, Macharam, Sarlapally', () {
      final villages = MasterDataCacheService.fallbackVillages(5002);
      expect(villages.length, equals(3));
      final names = villages.map((v) => v.villageName).toList();
      expect(names, containsAll(['Amrabad', 'Macharam', 'Sarlapally']));
      expect(names, equals(['Amrabad', 'Macharam', 'Sarlapally']));
    });

    test('2. DemographicRepository.fetchVillagesFromApi falls back to fallback villages on network error', () async {
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final villages = await DemographicRepository.fetchVillagesFromApi(
        '5002',
        client: offlineClient,
      );

      expect(villages, isNotEmpty);
      final names = villages.map((v) => v.villageName).toList();
      expect(names, containsAll(['Amrabad', 'Macharam', 'Sarlapally']));
    });

    test('3. AwarenessApiService.fetchVillagesForPanchayat returns offline villages when network unavailable', () async {
      final service = AwarenessApiService();
      final villages = await service.fetchVillagesForPanchayat(null);
      expect(villages, isNotEmpty);
      final names = villages.map((v) => v.villageName).toList();
      expect(names, contains('Amrabad'));
      expect(names, contains('Macharam'));
      expect(names, contains('Sarlapally'));
    });

    test('4. ReferralsApiService.fetchVillagesForPanchayat returns offline villages when network unavailable', () async {
      final service = ReferralsApiService();
      final villages = await service.fetchVillagesForPanchayat(null);
      expect(villages, isNotEmpty);
      final names = villages.map((v) => v.villageName).toList();
      expect(names, contains('Amrabad'));
      expect(names, contains('Macharam'));
      expect(names, contains('Sarlapally'));
    });

    test('5. SampleSupportApiService.fetchVillagesForPanchayat returns offline villages when network unavailable', () async {
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });
      final service = SampleSupportApiService(client: offlineClient);
      final villages = await service.fetchVillagesForPanchayat(5002);
      expect(villages, isNotEmpty);
      final names = villages.map((v) => v.villageName).toList();
      expect(names, contains('Amrabad'));
      expect(names, contains('Macharam'));
      expect(names, contains('Sarlapally'));
    });

    test('6. LocalMediaCacheService.findLocalFile resolves direct existing file paths', () async {
      final tempDir = Directory.systemTemp.createTempSync('media_test');
      try {
        final testFile = File('${tempDir.path}/scaled_1000220761_geotagged.jpg');
        await testFile.writeAsString('test-image-content');

        final found = await LocalMediaCacheService.instance.findLocalFile(
          storagePath: testFile.path,
          fileName: 'scaled_1000220761_geotagged.jpg',
        );

        expect(found, isNotNull);
        expect(found!.existsSync(), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
