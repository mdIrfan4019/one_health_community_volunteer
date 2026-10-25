// Domain Models for Sample Support Feature
// File: lib/features/sample_reprot/domain/sample_support_models.dart

class SampleTypeModel {
  final int sampleTypeId;
  final String sampleTypeName;
  final List<String> applicableSectors;
  final bool isOther;

  const SampleTypeModel({
    required this.sampleTypeId,
    required this.sampleTypeName,
    required this.applicableSectors,
    this.isOther = false,
  });

  factory SampleTypeModel.fromJson(Map<String, dynamic> json) {
    final rawSectors = json['applicable_sectors'];
    List<String> parsedSectors = [];
    if (rawSectors is List) {
      parsedSectors = rawSectors
          .map((e) => e.toString().toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return SampleTypeModel(
      sampleTypeId: json['sample_type_id'] is int
          ? json['sample_type_id'] as int
          : int.tryParse(json['sample_type_id']?.toString() ?? '0') ?? 0,
      sampleTypeName: json['sample_type_name']?.toString() ?? '',
      applicableSectors: parsedSectors,
      isOther: json['is_other'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'sample_type_id': sampleTypeId,
    'sample_type_name': sampleTypeName,
    'applicable_sectors': applicableSectors,
    'is_other': isOther,
  };

  /// Returns true if this sample type is applicable to the given sector.
  bool isApplicableTo(String? sector) {
    if (sector == null || sector.trim().isEmpty) return true;
    final lower = sector.toLowerCase().trim();
    return applicableSectors.contains(lower);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SampleTypeModel &&
          runtimeType == other.runtimeType &&
          sampleTypeId == other.sampleTypeId;

  @override
  int get hashCode => sampleTypeId.hashCode;

  @override
  String toString() => sampleTypeName;

  /// Default fallback sample types in case of network unavailability (matches staging master)
  static List<SampleTypeModel> fallbackTypes() => const [
    SampleTypeModel(
      sampleTypeId: 1,
      sampleTypeName: 'Human samples',
      applicableSectors: ['human'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 2,
      sampleTypeName: 'Livestock samples',
      applicableSectors: ['animal'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 3,
      sampleTypeName: 'Poultry samples',
      applicableSectors: ['animal'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 4,
      sampleTypeName: 'Companion animal samples',
      applicableSectors: ['animal', 'human'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 5,
      sampleTypeName: 'Wildlife samples',
      applicableSectors: ['wildlife'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 6,
      sampleTypeName: 'Water samples',
      applicableSectors: ['environment'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 7,
      sampleTypeName: 'Food samples',
      applicableSectors: ['human', 'environment'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 8,
      sampleTypeName: 'Environmental samples',
      applicableSectors: ['environment'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 9,
      sampleTypeName: 'Other',
      applicableSectors: ['human', 'animal', 'wildlife', 'environment'],
      isOther: true,
    ),
  ];
}
