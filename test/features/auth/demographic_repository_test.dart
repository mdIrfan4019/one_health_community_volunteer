import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/presentation/screens/volunteer_registration_screen.dart';

void main() {
  group('StateModel tests', () {
    test('parses state JSON correctly from backend response', () {
      const rawJson = '''
      [
        {
          "state_id": 13,
          "state_name": "Andaman and Nicobar Islands",
          "state_lgd_code": "35"
        }
      ]
      ''';

      final List<dynamic> decoded = jsonDecode(rawJson);
      final states = decoded
          .map((item) => StateModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(states.length, 1);
      expect(states.first.stateId, 13);
      expect(states.first.stateName, 'Andaman and Nicobar Islands');
      expect(states.first.stateLgdCode, '35');
    });

    test('parses new state JSON without state_id correctly', () {
      const rawJson = '''
      [
        {
          "state_lgd_code": "35",
          "state_name": "Andaman and Nicobar Islands"
        }
      ]
      ''';

      final List<dynamic> decoded = jsonDecode(rawJson);
      final states = decoded
          .map((item) => StateModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(states.length, 1);
      expect(states.first.stateName, 'Andaman and Nicobar Islands');
      expect(states.first.stateLgdCode, '35');
      expect(states.first.id, 35);
    });

    test('parses district JSON correctly', () {
      const rawDistrictJson = '''
      [
        {
          "district_lgd_code": "601",
          "district_name": "Nicobars",
          "state_lgd_code": "35"
        },
        {
          "district_lgd_code": "602",
          "district_name": "North and Middle Andaman",
          "state_lgd_code": "35"
        }
      ]
      ''';

      final List<dynamic> decoded = jsonDecode(rawDistrictJson);
      final districts = decoded
          .map((item) => DistrictModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(districts.length, 2);
      expect(districts.first.districtName, 'Nicobars');
      expect(districts.first.districtLgdCode, '601');
      expect(districts.first.stateLgdCode, '35');
      expect(districts.first.id, 601);
    });

    test('parses block JSON correctly', () {
      const rawBlockJson = '''
      [
        {
          "block_lgd_code": "6001",
          "block_name": "Car Nicobar",
          "district_lgd_code": "601"
        },
        {
          "block_lgd_code": "6002",
          "block_name": "Nancowry",
          "district_lgd_code": "601"
        }
      ]
      ''';

      final List<dynamic> decoded = jsonDecode(rawBlockJson);
      final blocks = decoded
          .map((item) => BlockModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(blocks.length, 2);
      expect(blocks.first.blockName, 'Car Nicobar');
      expect(blocks.first.blockLgdCode, '6001');
      expect(blocks.first.districtLgdCode, '601');
      expect(blocks.first.id, 6001);
    });

    test('parses panchayat JSON correctly', () {
      const rawPanchayatJson = '''
      [
        {
          "gram_panchayat_lgd_code": 9000002,
          "block_lgd_code": 5208,
          "district_lgd_code": 694,
          "state_lgd_code": 36,
          "gram_panchayat_name": "Amrabad",
          "local_body_type": "GRAM_PANCHAYAT"
        }
      ]
      ''';

      final List<dynamic> decoded = jsonDecode(rawPanchayatJson);
      final panchayats = decoded
          .map((item) => PanchayatModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(panchayats.length, 1);
      expect(panchayats.first.gramPanchayatName, 'Amrabad');
      expect(panchayats.first.gramPanchayatLgdCode, '9000002');
      expect(panchayats.first.blockLgdCode, '5208');
      expect(panchayats.first.districtLgdCode, '694');
      expect(panchayats.first.stateLgdCode, '36');
      expect(panchayats.first.localBodyType, 'GRAM_PANCHAYAT');
      expect(panchayats.first.id, 9000002);
    });

    test('BlockModel correctly resolves effectiveLgdCode from numeric or alternate keys', () {
      final block1 = BlockModel.fromJson({
        'block_name': 'Amrabad',
        'block_lgd_code': 5208,
      });
      expect(block1.effectiveLgdCode, '5208');

      final block2 = BlockModel.fromJson({
        'name': 'Amrabad',
        'block_id': 5208,
      });
      expect(block2.effectiveLgdCode, '5208');
    });

    test('parses village JSON correctly', () {
      const rawVillageJson = '''
      [
        {
          "village_lgd_code": 90000001,
          "gram_panchayat_lgd_code": 9000001,
          "block_lgd_code": 5208,
          "district_lgd_code": 694,
          "state_lgd_code": 36,
          "village_name": "Mannanur",
          "village_type": "VILLAGE"
        }
      ]
      ''';

      final List<dynamic> decoded = jsonDecode(rawVillageJson);
      final villages = decoded
          .map((item) => VillageModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(villages.length, 1);
      expect(villages.first.villageName, 'Mannanur');
      expect(villages.first.villageLgdCode, '90000001');
      expect(villages.first.gramPanchayatLgdCode, '9000001');
      expect(villages.first.blockLgdCode, '5208');
      expect(villages.first.districtLgdCode, '694');
      expect(villages.first.stateLgdCode, '36');
      expect(villages.first.villageType, 'VILLAGE');
      expect(villages.first.id, 90000001);
    });

    test('parses professions JSON correctly', () {
      const rawProfessionsJson = '''
      [
        {
          "profession_id": 1,
          "profession_name": "Farmer"
        },
        {
          "profession_id": 2,
          "profession_name": "Agricultural labourer"
        }
      ]
      ''';

      final List<dynamic> decoded = jsonDecode(rawProfessionsJson);
      final profs = decoded
          .map((item) => ProfessionModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(profs.length, 2);
      expect(profs.first.professionId, 1);
      expect(profs.first.professionName, 'Farmer');
      expect(profs[1].professionId, 2);
      expect(profs[1].professionName, 'Agricultural labourer');
    });

    test('parses educations JSON correctly', () {
      const rawEducationsJson = '''
      [
        {
          "education_id": 1,
          "education_name": "Secondary Education",
          "is_other": false
        },
        {
          "education_id": 2,
          "education_name": "Higher Secondary",
          "is_other": false
        }
      ]
      ''';

      final List<dynamic> decoded = jsonDecode(rawEducationsJson);
      final edus = decoded
          .map((item) => EducationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(edus.length, 2);
      expect(edus.first.educationId, 1);
      expect(edus.first.educationName, 'Secondary Education');
      expect(edus.first.isOther, false);
      expect(edus[1].educationId, 2);
      expect(edus[1].educationName, 'Higher Secondary');
    });

    testWidgets('VolunteerRegistrationScreen renders without duplicate key error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VolunteerRegistrationScreen(),
        ),
      );
      // Let any microtasks settle
      await tester.pump();
      expect(find.byType(VolunteerRegistrationScreen), findsOneWidget);
    });

    test('getFallbackPanchayats returns seed panchayats for Kopaganj in Mau, Uttar Pradesh', () {
      final panchayats = DemographicRepository.getFallbackPanchayats(
        'Uttar Pradesh',
        'Mau',
        'Kopaganj',
        '1383',
      );
      expect(panchayats.isNotEmpty, true);
      expect(panchayats.any((p) => p.gramPanchayatName.contains('Kopaganj')), true);
      expect(panchayats.first.blockLgdCode, '1383');
      expect(panchayats.first.gramPanchayatLgdCode.isNotEmpty, true);
    });

    test('getFallbackPanchayats generates dynamic fallback for unseeded blocks', () {
      final panchayats = DemographicRepository.getFallbackPanchayats(
        'RandomState',
        'RandomDistrict',
        'TestBlock',
        '9999',
      );
      expect(panchayats.length, 3);
      expect(panchayats.first.gramPanchayatName, 'TestBlock Central GP');
      expect(panchayats.first.gramPanchayatLgdCode, '999901');
    });

    test('getFallbackVillages generates dynamic fallback for unseeded panchayats', () {
      final villages = DemographicRepository.getFallbackVillages(
        'RandomState',
        'RandomDistrict',
        'TestBlock',
        'TestBlock Central GP',
        '999901',
      );
      expect(villages.length, 3);
      expect(villages.first.villageName, 'TestBlock Central Village');
      expect(villages.first.villageLgdCode, '99990101');
    });

    test('parses supervisor JSON correctly from backend response', () {
      const rawSupervisorJson = '''
      [
        {
          "supervisor_id": 1,
          "supervisor_code": "SUP-26-0001",
          "supervisor_name": "Dr. Ravi Kumar",
          "designation": "Medical Officer, PHC",
          "cohv_type": "Public Health"
        }
      ]
      ''';

      final List<dynamic> decoded = jsonDecode(rawSupervisorJson);
      final supervisors = decoded
          .map((item) => SupervisorModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(supervisors.length, 1);
      final s = supervisors.first;
      expect(s.supervisorId, 1);
      expect(s.supervisorCode, 'SUP-26-0001');
      expect(s.supervisorName, 'Dr. Ravi Kumar');
      expect(s.designation, 'Medical Officer, PHC');
      expect(s.cohvType, 'Public Health');
      expect(s.displayName, 'Dr. Ravi Kumar (Medical Officer, PHC)');
    });

    test('DemographicRepository.normalizeCohvType correctly handles UI labels', () {
      expect(DemographicRepository.normalizeCohvType('Public Health (human)'), 'Public Health');
      expect(DemographicRepository.normalizeCohvType('Animal Husbandry (animal)'), 'Animal');
      expect(DemographicRepository.normalizeCohvType('Wildlife (wildlife)'), 'Wildlife');
      expect(DemographicRepository.normalizeCohvType('Environment (ulb)'), 'Environment');
      expect(DemographicRepository.normalizeCohvType('Public Health'), 'Public Health');
      expect(DemographicRepository.normalizeCohvType(null), '');
    });

    test('getFallbackSupervisors generates realistic fallback supervisors', () {
      final sups = DemographicRepository.getFallbackSupervisors(
        cohvType: 'Public Health (human)',
        stateName: 'Uttar Pradesh',
        districtName: 'Mau',
      );
      expect(sups.length, 2);
      expect(sups.first.supervisorName.isNotEmpty, true);
      expect(sups.first.cohvType, 'Public Health');
    });
  });
}
