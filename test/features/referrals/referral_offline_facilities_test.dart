import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cohv/features/referrals/data/referrals_api_service.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Referral Facilities Offline & Fallback Tests', () {
    test('Animal referral facilities fallback returns 4 facilities when offline', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network unreachable');
      });

      final service = ReferralsApiService(client: mockClient);
      final facilities = await service.fetchFacilities('Animal');

      expect(facilities.length, 4);
      expect(facilities.map((f) => f.facilityName).toList(), containsAll([
        'Veterinary Dispensary',
        'Veterinary Hospital',
        'Veterinary Polyclinic',
        'Other',
      ]));
      expect(facilities.firstWhere((f) => f.isOther).facilityName, 'Other');
    });

    test('Human referral facilities fallback returns 8 facilities when offline', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network unreachable');
      });

      final service = ReferralsApiService(client: mockClient);
      final facilities = await service.fetchFacilities('Human');

      expect(facilities.length, 8);
      expect(facilities.map((f) => f.facilityName).toList(), containsAll([
        'Sub-Centre / HWC',
        'PHC',
        'CHC',
        'District Hospital',
        'Medical College / Tertiary Facility',
        'Mobile Health Unit',
        'Emergency Referral',
        'Other',
      ]));
      expect(facilities.firstWhere((f) => f.isOther).facilityName, 'Other');
    });

    test('ReferralFacility JSON serialization preserves referral_stream and referral_facility_id', () {
      const facility = ReferralFacility(
        facilityId: 10,
        stream: 'ANIMAL',
        facilityName: 'Veterinary Hospital',
        isOther: false,
      );

      final json = facility.toJson();
      expect(json['referral_facility_id'], 10);
      expect(json['referral_stream'], 'ANIMAL');
      expect(json['referral_facility_name'], 'Veterinary Hospital');
      expect(json['is_other'], false);

      final deserialized = ReferralFacility.fromJson(json);
      expect(deserialized.facilityId, 10);
      expect(deserialized.stream, 'ANIMAL');
      expect(deserialized.facilityName, 'Veterinary Hospital');
      expect(deserialized.isOther, false);
    });
  });
}
