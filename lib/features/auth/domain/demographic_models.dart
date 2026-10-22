/// Geographic and demographic domain models for location hierarchy and master data.
library;

class StateModel {
  final int? stateId;
  final String stateName;
  final String stateLgdCode;

  const StateModel({
    this.stateId,
    required this.stateName,
    required this.stateLgdCode,
  });

  /// Returns effective numeric identifier (stateId if present, or parsed LGD code, or 0)
  int get id => stateId ?? int.tryParse(stateLgdCode) ?? 0;

  factory StateModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['state_id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    return StateModel(
      stateId: id,
      stateName: json['state_name']?.toString() ?? '',
      stateLgdCode: json['state_lgd_code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    if (stateId != null) 'state_id': stateId,
    'state_name': stateName,
    'state_lgd_code': stateLgdCode,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateModel &&
          runtimeType == other.runtimeType &&
          (stateLgdCode.isNotEmpty && other.stateLgdCode.isNotEmpty
              ? stateLgdCode == other.stateLgdCode
              : (stateId != null && other.stateId != null
                    ? stateId == other.stateId
                    : stateName == other.stateName));

  @override
  int get hashCode => stateLgdCode.isNotEmpty
      ? stateLgdCode.hashCode
      : (stateId ?? stateName.hashCode);

  @override
  String toString() => stateName;
}

class DistrictModel {
  final int? districtId;
  final String districtName;
  final String districtLgdCode;
  final String? stateLgdCode;

  const DistrictModel({
    this.districtId,
    required this.districtName,
    required this.districtLgdCode,
    this.stateLgdCode,
  });

  /// Returns effective numeric identifier (districtId if present, or parsed LGD code, or 0)
  int get id => districtId ?? int.tryParse(districtLgdCode) ?? 0;

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['district_id'] ?? json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    final name =
        json['district_name']?.toString() ?? json['name']?.toString() ?? '';

    final lgdCode =
        json['district_lgd_code']?.toString() ??
        json['lgd_code']?.toString() ??
        '';

    final stateCode =
        json['state_lgd_code']?.toString() ?? json['state_id']?.toString();

    return DistrictModel(
      districtId: id,
      districtName: name,
      districtLgdCode: lgdCode,
      stateLgdCode: stateCode,
    );
  }

  Map<String, dynamic> toJson() => {
    if (districtId != null) 'district_id': districtId,
    'district_name': districtName,
    'district_lgd_code': districtLgdCode,
    if (stateLgdCode != null) 'state_lgd_code': stateLgdCode,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictModel &&
          runtimeType == other.runtimeType &&
          (districtLgdCode.isNotEmpty && other.districtLgdCode.isNotEmpty
              ? districtLgdCode == other.districtLgdCode
              : (districtId != null && other.districtId != null
                    ? districtId == other.districtId
                    : districtName == other.districtName));

  @override
  int get hashCode => districtLgdCode.isNotEmpty
      ? districtLgdCode.hashCode
      : (districtId ?? districtName.hashCode);

  @override
  String toString() => districtName;
}

class BlockModel {
  final int? blockId;
  final String blockName;
  final String blockLgdCode;
  final String? districtLgdCode;

  const BlockModel({
    this.blockId,
    required this.blockName,
    required this.blockLgdCode,
    this.districtLgdCode,
  });

  /// Returns effective numeric identifier (blockId if present, or parsed LGD code, or 0)
  int get id => blockId ?? int.tryParse(blockLgdCode) ?? 0;

  /// Returns effective string LGD code (blockLgdCode if not empty, otherwise blockId as string)
  String get effectiveLgdCode {
    if (blockLgdCode.isNotEmpty) return blockLgdCode;
    if (blockId != null && blockId != 0) return blockId.toString();
    return '';
  }

  factory BlockModel.fromJson(Map<dynamic, dynamic> json) {
    final rawId = json['block_id'] ?? json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    final name =
        json['block_name']?.toString() ??
        json['name']?.toString() ??
        json['sub_district_name']?.toString() ??
        '';

    final lgdCode =
        json['block_lgd_code']?.toString() ??
        json['block_code']?.toString() ??
        json['sub_district_lgd_code']?.toString() ??
        json['lgd_code']?.toString() ??
        (id != null && id != 0 ? id.toString() : '');

    final districtCode =
        json['district_lgd_code']?.toString() ??
        json['district_id']?.toString();

    return BlockModel(
      blockId: id,
      blockName: name,
      blockLgdCode: lgdCode,
      districtLgdCode: districtCode,
    );
  }

  Map<String, dynamic> toJson() => {
    if (blockId != null) 'block_id': blockId,
    'block_name': blockName,
    'block_lgd_code': blockLgdCode,
    if (districtLgdCode != null) 'district_lgd_code': districtLgdCode,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockModel &&
          runtimeType == other.runtimeType &&
          (blockLgdCode.isNotEmpty && other.blockLgdCode.isNotEmpty
              ? blockLgdCode == other.blockLgdCode
              : (blockId != null && other.blockId != null
                    ? blockId == other.blockId
                    : blockName == other.blockName));

  @override
  int get hashCode => blockLgdCode.isNotEmpty
      ? blockLgdCode.hashCode
      : (blockId ?? blockName.hashCode);

  @override
  String toString() => blockName;
}

class PanchayatModel {
  final String gramPanchayatName;
  final String gramPanchayatLgdCode;
  final String? blockLgdCode;
  final String? districtLgdCode;
  final String? stateLgdCode;
  final String? localBodyType;

  const PanchayatModel({
    required this.gramPanchayatName,
    required this.gramPanchayatLgdCode,
    this.blockLgdCode,
    this.districtLgdCode,
    this.stateLgdCode,
    this.localBodyType,
  });

  /// Returns effective numeric identifier
  int get id => int.tryParse(gramPanchayatLgdCode) ?? 0;

  /// Returns effective string LGD code
  String get effectiveLgdCode {
    if (gramPanchayatLgdCode.isNotEmpty) return gramPanchayatLgdCode;
    return id != 0 ? id.toString() : '';
  }

  factory PanchayatModel.fromJson(Map<dynamic, dynamic> json) {
    final name =
        json['gram_panchayat_name']?.toString() ??
        json['panchayat_name']?.toString() ??
        json['gp_name']?.toString() ??
        json['name']?.toString() ??
        '';

    final lgdCode =
        json['gram_panchayat_lgd_code']?.toString() ??
        json['panchayat_lgd_code']?.toString() ??
        json['gp_lgd_code']?.toString() ??
        json['lgd_code']?.toString() ??
        json['id']?.toString() ??
        '';

    return PanchayatModel(
      gramPanchayatName: name,
      gramPanchayatLgdCode: lgdCode,
      blockLgdCode: json['block_lgd_code']?.toString(),
      districtLgdCode: json['district_lgd_code']?.toString(),
      stateLgdCode: json['state_lgd_code']?.toString(),
      localBodyType: json['local_body_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'gram_panchayat_name': gramPanchayatName,
    'gram_panchayat_lgd_code': gramPanchayatLgdCode,
    if (blockLgdCode != null) 'block_lgd_code': blockLgdCode,
    if (districtLgdCode != null) 'district_lgd_code': districtLgdCode,
    if (stateLgdCode != null) 'state_lgd_code': stateLgdCode,
    if (localBodyType != null) 'local_body_type': localBodyType,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanchayatModel &&
          runtimeType == other.runtimeType &&
          (gramPanchayatLgdCode.isNotEmpty &&
                  other.gramPanchayatLgdCode.isNotEmpty
              ? gramPanchayatLgdCode == other.gramPanchayatLgdCode
              : gramPanchayatName == other.gramPanchayatName);

  @override
  int get hashCode => gramPanchayatLgdCode.isNotEmpty
      ? gramPanchayatLgdCode.hashCode
      : gramPanchayatName.hashCode;

  @override
  String toString() => gramPanchayatName;
}

class VillageModel {
  final int? villageId;
  final String villageName;
  final String villageLgdCode;
  final String? gramPanchayatLgdCode;
  final String? blockLgdCode;
  final String? districtLgdCode;
  final String? stateLgdCode;
  final String? villageType;

  const VillageModel({
    this.villageId,
    required this.villageName,
    required this.villageLgdCode,
    this.gramPanchayatLgdCode,
    this.blockLgdCode,
    this.districtLgdCode,
    this.stateLgdCode,
    this.villageType,
  });

  int get id => villageId ?? int.tryParse(villageLgdCode) ?? 0;

  String get effectiveLgdCode {
    if (villageLgdCode.isNotEmpty) return villageLgdCode;
    if (villageId != null && villageId != 0) return villageId.toString();
    return '';
  }

  factory VillageModel.fromJson(Map<dynamic, dynamic> json) {
    final rawId = json['village_id'] ?? json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    final name =
        json['village_name']?.toString() ?? json['name']?.toString() ?? '';

    final lgdCode =
        json['village_lgd_code']?.toString() ??
        json['lgd_code']?.toString() ??
        (id != null && id != 0 ? id.toString() : '');

    return VillageModel(
      villageId: id,
      villageName: name,
      villageLgdCode: lgdCode,
      gramPanchayatLgdCode:
          json['gram_panchayat_lgd_code']?.toString() ??
          json['panchayat_lgd_code']?.toString(),
      blockLgdCode: json['block_lgd_code']?.toString(),
      districtLgdCode: json['district_lgd_code']?.toString(),
      stateLgdCode: json['state_lgd_code']?.toString(),
      villageType: json['village_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (villageId != null) 'village_id': villageId,
    'village_name': villageName,
    'village_lgd_code': villageLgdCode,
    if (gramPanchayatLgdCode != null)
      'gram_panchayat_lgd_code': gramPanchayatLgdCode,
    if (blockLgdCode != null) 'block_lgd_code': blockLgdCode,
    if (districtLgdCode != null) 'district_lgd_code': districtLgdCode,
    if (stateLgdCode != null) 'state_lgd_code': stateLgdCode,
    if (villageType != null) 'village_type': villageType,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VillageModel &&
          runtimeType == other.runtimeType &&
          (villageLgdCode.isNotEmpty && other.villageLgdCode.isNotEmpty
              ? villageLgdCode == other.villageLgdCode
              : (villageId != null && other.villageId != null
                    ? villageId == other.villageId
                    : villageName == other.villageName));

  @override
  int get hashCode => villageLgdCode.isNotEmpty
      ? villageLgdCode.hashCode
      : (villageId ?? villageName.hashCode);

  @override
  String toString() => villageName;
}

class ProfessionModel {
  final int professionId;
  final String professionName;

  const ProfessionModel({
    required this.professionId,
    required this.professionName,
  });

  int get id => professionId;

  factory ProfessionModel.fromJson(Map<dynamic, dynamic> json) {
    final rawId = json['profession_id'] ?? json['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final name =
        json['profession_name']?.toString() ?? json['name']?.toString() ?? '';

    return ProfessionModel(professionId: id, professionName: name);
  }

  Map<String, dynamic> toJson() => {
    'profession_id': professionId,
    'profession_name': professionName,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfessionModel &&
          runtimeType == other.runtimeType &&
          (professionId != 0 && other.professionId != 0
              ? professionId == other.professionId
              : professionName == other.professionName);

  @override
  int get hashCode =>
      professionId != 0 ? professionId.hashCode : professionName.hashCode;

  @override
  String toString() => professionName;
}

class EducationModel {
  final int educationId;
  final String educationName;
  final bool isOther;

  const EducationModel({
    required this.educationId,
    required this.educationName,
    this.isOther = false,
  });

  int get id => educationId;

  factory EducationModel.fromJson(Map<dynamic, dynamic> json) {
    final rawId =
        json['education_id'] ?? json['id'] ?? json['qualification_id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final name =
        json['education_name']?.toString() ??
        json['qualification_name']?.toString() ??
        json['name']?.toString() ??
        '';
    final isOther = json['is_other'] == true || json['is_other'] == 'true';

    return EducationModel(
      educationId: id,
      educationName: name,
      isOther: isOther,
    );
  }

  Map<String, dynamic> toJson() => {
    'education_id': educationId,
    'education_name': educationName,
    'is_other': isOther,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducationModel &&
          runtimeType == other.runtimeType &&
          (educationId != 0 && other.educationId != 0
              ? educationId == other.educationId
              : educationName == other.educationName);

  @override
  int get hashCode =>
      educationId != 0 ? educationId.hashCode : educationName.hashCode;

  @override
  String toString() => educationName;
}

class SupervisorModel {
  final int supervisorId;
  final String supervisorCode;
  final String supervisorName;
  final String? designation;
  final String? cohvType;

  const SupervisorModel({
    required this.supervisorId,
    required this.supervisorCode,
    required this.supervisorName,
    this.designation,
    this.cohvType,
  });

  int get id => supervisorId;

  String get displayName {
    if (designation != null && designation!.isNotEmpty) {
      return '$supervisorName ($designation)';
    }
    return supervisorName;
  }

  factory SupervisorModel.fromJson(Map<dynamic, dynamic> json) {
    final rawId = json['supervisor_id'] ?? json['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return SupervisorModel(
      supervisorId: id,
      supervisorCode: json['supervisor_code']?.toString() ?? '',
      supervisorName:
          json['supervisor_name']?.toString() ?? json['name']?.toString() ?? '',
      designation: json['designation']?.toString(),
      cohvType: json['cohv_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'supervisor_id': supervisorId,
    'supervisor_code': supervisorCode,
    'supervisor_name': supervisorName,
    if (designation != null) 'designation': designation,
    if (cohvType != null) 'cohv_type': cohvType,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupervisorModel &&
          runtimeType == other.runtimeType &&
          (supervisorId != 0 && other.supervisorId != 0
              ? supervisorId == other.supervisorId
              : supervisorName == other.supervisorName);

  @override
  int get hashCode =>
      supervisorId != 0 ? supervisorId.hashCode : supervisorName.hashCode;

  @override
  String toString() => displayName;
}

class DepartmentModel {
  final int departmentId;
  final String departmentName;

  const DepartmentModel({
    required this.departmentId,
    required this.departmentName,
  });

  int get id => departmentId;

  factory DepartmentModel.fromJson(Map<dynamic, dynamic> json) {
    final rawId = json['department_id'] ?? json['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final name = json['department_name'] ?? json['name'] ?? '';

    return DepartmentModel(departmentId: id, departmentName: name.toString());
  }

  Map<String, dynamic> toJson() => {
    'department_id': departmentId,
    'department_name': departmentName,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentModel &&
          runtimeType == other.runtimeType &&
          (departmentId != 0 && other.departmentId != 0
              ? departmentId == other.departmentId
              : departmentName == other.departmentName);

  @override
  int get hashCode =>
      departmentId != 0 ? departmentId.hashCode : departmentName.hashCode;

  @override
  String toString() => departmentName;
}

class InstitutionModel {
  final int institutionTypeId;
  final int departmentId;
  final String fieldLabel;
  final String optionName;
  final bool isOther;
  final int sortOrder;

  const InstitutionModel({
    required this.institutionTypeId,
    required this.departmentId,
    required this.fieldLabel,
    required this.optionName,
    this.isOther = false,
    this.sortOrder = 0,
  });

  int get id => institutionTypeId;

  factory InstitutionModel.fromJson(Map<dynamic, dynamic> json) {
    final rawId = json['institution_type_id'] ?? json['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawDeptId = json['department_id'];
    final deptId = rawDeptId is int
        ? rawDeptId
        : int.tryParse(rawDeptId?.toString() ?? '') ?? 0;

    final label = json['field_label']?.toString() ?? '';
    final name =
        json['option_name']?.toString() ?? json['name']?.toString() ?? '';
    final isOtherRaw = json['is_other'];
    final isOther =
        isOtherRaw == true || isOtherRaw?.toString().toLowerCase() == 'true';

    final rawSort = json['sort_order'];
    final sort = rawSort is int
        ? rawSort
        : int.tryParse(rawSort?.toString() ?? '') ?? 0;

    return InstitutionModel(
      institutionTypeId: id,
      departmentId: deptId,
      fieldLabel: label,
      optionName: name,
      isOther: isOther,
      sortOrder: sort,
    );
  }

  Map<String, dynamic> toJson() => {
    'institution_type_id': institutionTypeId,
    'department_id': departmentId,
    'field_label': fieldLabel,
    'option_name': optionName,
    'is_other': isOther,
    'sort_order': sortOrder,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstitutionModel &&
          runtimeType == other.runtimeType &&
          (institutionTypeId != 0 && other.institutionTypeId != 0
              ? institutionTypeId == other.institutionTypeId
              : (departmentId == other.departmentId &&
                    optionName == other.optionName));

  @override
  int get hashCode =>
      institutionTypeId != 0 ? institutionTypeId.hashCode : optionName.hashCode;

  @override
  String toString() => optionName;
}
