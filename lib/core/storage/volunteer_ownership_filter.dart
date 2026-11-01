/// Centralized volunteer ownership validation and filtering utility.
///
/// Ensures strict display-level data isolation across all listing screens
/// (Event Reports, Referrals, Activity Awareness).
class VolunteerOwnershipFilter {
  /// Extracts trailing numeric digits from a volunteer code (e.g. "COHV-26-0050" -> 50)
  static int? extractNumericSuffix(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final trimmed = code.trim();
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return int.tryParse(trimmed);
    }
    final match = RegExp(r'(\d+)$').firstMatch(trimmed);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Evaluates whether a given entity record strictly belongs to the
  /// currently authenticated volunteer.
  static bool isOwnedByVolunteer({
    int? recordNumericVolunteerId,
    String? recordVolunteerCode,
    String? recordVolunteerId,
    String? recordVolunteerName,
    int? itemNumericId,
    String? itemOwnerId,
    int? authNumericVolunteerId,
    String? authVolunteerCode,
    String? activeVolunteerId,
    int? activeNumericId,
    String? authVolunteerName,
  }) {
    final effectiveAuthCode =
        (authVolunteerCode ?? activeVolunteerId ?? '').trim().toUpperCase();

    // Explicit primary DB numeric ID (do not fallback to suffix here to prevent false rejection)
    final explicitAuthNumeric = (authNumericVolunteerId != null && authNumericVolunteerId > 0)
        ? authNumericVolunteerId
        : ((activeNumericId != null && activeNumericId > 0) ? activeNumericId : null);

    final cleanRecordCode = (recordVolunteerCode ?? '').trim().toUpperCase();
    final cleanRecordId =
        (recordVolunteerId ?? itemOwnerId ?? '').trim().toUpperCase();

    // 1. Volunteer code exact match (e.g. "COHV-26-0007" == "COHV-26-0007")
    if (effectiveAuthCode.isNotEmpty) {
      if (cleanRecordCode.isNotEmpty && cleanRecordCode == effectiveAuthCode) {
        return true;
      }
      if (cleanRecordId.isNotEmpty && cleanRecordId == effectiveAuthCode) {
        return true;
      }
    }

    // Resolve numeric ID for the record from explicit int or string
    int? parsedRecordNumeric = recordNumericVolunteerId ?? itemNumericId;
    if (parsedRecordNumeric == null || parsedRecordNumeric <= 0) {
      if (RegExp(r'^\d+$').hasMatch(cleanRecordId)) {
        parsedRecordNumeric = int.tryParse(cleanRecordId);
      } else if (RegExp(r'^\d+$').hasMatch(cleanRecordCode)) {
        parsedRecordNumeric = int.tryParse(cleanRecordCode);
      }
    }

    // 2. Explicit Database Numeric Volunteer ID match (e.g. 37 == 37)
    if (explicitAuthNumeric != null && parsedRecordNumeric != null && parsedRecordNumeric > 0) {
      if (parsedRecordNumeric == explicitAuthNumeric) {
        return true;
      }
    }

    // 3. Suffix / Derived ID matching
    final authSuffix = extractNumericSuffix(effectiveAuthCode);
    final recordSuffix =
        extractNumericSuffix(cleanRecordCode) ?? extractNumericSuffix(cleanRecordId);

    if (authSuffix != null && recordSuffix != null && authSuffix == recordSuffix) {
      return true;
    }

    if (authSuffix != null && parsedRecordNumeric != null && authSuffix == parsedRecordNumeric) {
      return true;
    }

    if (explicitAuthNumeric != null && recordSuffix != null && explicitAuthNumeric == recordSuffix) {
      return true;
    }

    // 4. Secondary Name match if volunteer codes/IDs were omitted in the payload
    final effectiveAuthName = (authVolunteerName ?? '').trim().toLowerCase();
    final cleanRecordName = (recordVolunteerName ?? '').trim().toLowerCase();
    if (effectiveAuthName.isNotEmpty &&
        cleanRecordName.isNotEmpty &&
        effectiveAuthName == cleanRecordName) {
      return true;
    }

    // If record lacks any identifying ownership field at all
    if ((parsedRecordNumeric == null || parsedRecordNumeric <= 0) &&
        cleanRecordCode.isEmpty &&
        cleanRecordId.isEmpty &&
        cleanRecordName.isEmpty) {
      return false;
    }

    return false;
  }
}
