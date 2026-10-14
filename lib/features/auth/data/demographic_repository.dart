// Create file: lib/features/auth/data/demographic_repository.dart

class DemographicRepository {
  // =========================================================================
  // 1. FIXED STANDARD ENUMS / MASTER DATA (App-Side Standards)
  // =========================================================================
  static const List<String> genders = ['Male', 'Female', 'Transgender / Other'];

  static const List<String> cohvTypes = [
    'Public Health (human)',
    'Animal Husbandry (animal)',
    'Wildlife (wildlife)',
    'Environment (ulb)',
  ];

  static const List<String> qualifications = [
    '10th Standard',
    '12th Standard',
    'Graduate',
    'Post Graduate',
    'Diploma / ITI',
    'Other',
  ];

  static const List<String> professions = [
    'Community Health Worker',
    'ASHA Worker',
    'ANM',
    'Farmer',
    'Student',
    'Self Employed',
    'Panchayat Staff',
    'NGO / Social Worker',
    'Other',
  ];

  // =========================================================================
  // 2. CASCADING DEMOGRAPHIC HIERARCHY (Seed Data for Offline-First Readiness)
  // Spec: Changing an upstream administrative unit invalidates downstream units
  // =========================================================================
  static final Map<String, Map<String, Map<String, Map<String, List<String>>>>> _seedHierarchy = {
    'Telangana': {
      'Nagarkurnool': {
        'Amrabad': {
          'Amrabad GP': ['Amrabad Center', 'Vattarlapally', 'Udimilla'],
          'Mannanur GP': ['Mannanur Ward 1', 'Mannanur Ward 2', 'Chinnampally'],
          'Farhabad GP': ['Farhabad Forest Beat', 'Farhabad Village'],
        },
        'Achampet': {
          'Achampet Municipality': ['Ward 1 (Gandhi Chowk)', 'Ward 2', 'Ward 3'],
          'Puljal GP': ['Puljal Village', 'Puljal Tanda'],
        },
        'Lingal': {
          'Lingal GP': ['Lingal Main', 'Appaipally'],
        },
      },
      'Bhadradri Kothagudem': {
        'Palwancha': {
          'Palwancha GP': ['Old Palwancha', 'Kothagudem Road'],
        },
      },
    },
    'Tamil Nadu': {
      'The Nilgiris': {
        'Gudalur': {
          'Mudumalai GP': ['Theppakadu', 'Masinagudi Ward 1', 'Masinagudi Ward 2'],
          'O-Valley GP': ['O-Valley Center', 'Glenvans'],
        },
        'Udhagamandalam': {
          'Ooty Town': ['Upper Ooty', 'Lower Bazaar'],
        },
      },
      'Coimbatore': {
        'Pollachi': {
          'Anamalai GP': ['Topslip', 'Sethumadai'],
        },
      },
    },
  };

  // =========================================================================
  // 3. REPOSITORY ACCESS METHODS
  // =========================================================================

  /// Get list of all states
  static List<String> getStates() {
    return _seedHierarchy.keys.toList();
  }

  /// Get districts for selected state
  static List<String> getDistricts(String? state) {
    if (state == null || !_seedHierarchy.containsKey(state)) return [];
    return _seedHierarchy[state]!.keys.toList();
  }

  /// Get blocks/taluks for selected state and district
  static List<String> getBlocks(String? state, String? district) {
    if (state == null || district == null) return [];
    final districts = _seedHierarchy[state];
    if (districts == null || !districts.containsKey(district)) return [];
    return districts[district]!.keys.toList();
  }

  /// Get Gram Panchayats / Municipalities for selected block
  static List<String> getPanchayats(String? state, String? district, String? block) {
    if (state == null || district == null || block == null) return [];
    final blocks = _seedHierarchy[state]?[district];
    if (blocks == null || !blocks.containsKey(block)) return [];
    return blocks[block]!.keys.toList();
  }

  /// Get Villages / Wards for selected panchayat
  static List<String> getVillages(String? state, String? district, String? block, String? panchayat) {
    if (state == null || district == null || block == null || panchayat == null) return [];
    final panchayats = _seedHierarchy[state]?[district]?[block];
    if (panchayats == null || !panchayats.containsKey(panchayat)) return [];
    return panchayats[panchayat]!;
  }

  // =========================================================================
  // 🔌 FUTURE BACKEND SYNC HOOK:
  // When your backend API endpoint is ready, you can fetch and update the cache:
  // static Future<void> syncDemographicsFromApi() async {
  //   final response = await http.get(Uri.parse('https://api.yourserver.org/api/v1/master/demographics'));
  //   if (response.statusCode == 200) {
  //      // Update cached hierarchy in SQLite or memory
  //   }
  // }
  // =========================================================================
}
