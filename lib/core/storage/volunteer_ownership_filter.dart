import 'package:flutter/foundation.dart';

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
    final effectiveAuthNumeric =
        authNumericVolunteerId ??
        activeNumericId ??
        extractNumericSuffix(effectiveAuthCode);
    final hasAuthNumeric =
        effectiveAuthNumeric != null && effectiveAuthNumeric > 0;

    // Fail-safe: if authenticated session lacks any identity, reject all records
    if (!hasAuthNumeric && effectiveAuthCode.isEmpty) {
      debugPrint(
        '[OWNERSHIP] Warning: Authenticated session lacks volunteer identity. Rejecting record.',
      );
      return false;
    }

    final cleanRecordCode = (recordVolunteerCode ?? '').trim().toUpperCase();
    final cleanRecordId =
        (recordVolunteerId ?? itemOwnerId ?? '').trim().toUpperCase();

    // Resolve numeric ID for the record from explicit int or string
    int? parsedRecordNumeric = recordNumericVolunteerId ?? itemNumericId;
    if (parsedRecordNumeric == null || parsedRecordNumeric <= 0) {
      if (RegExp(r'^\d+$').hasMatch(cleanRecordId)) {
        parsedRecordNumeric = int.tryParse(cleanRecordId);
      } else if (RegExp(r'^\d+$').hasMatch(cleanRecordCode)) {
        parsedRecordNumeric = int.tryParse(cleanRecordCode);
      } else {
        parsedRecordNumeric =
            extractNumericSuffix(cleanRecordCode) ??
            extractNumericSuffix(cleanRecordId);
      }
    }

    // Fail-safe: if record lacks any identifying ownership field, do not display it
    if ((parsedRecordNumeric == null || parsedRecordNumeric <= 0) &&
        cleanRecordCode.isEmpty &&
        cleanRecordId.isEmpty) {
      debugPrint(
        '[OWNERSHIP] Discarded record with missing or ambiguous volunteer ownership.',
      );
      return false;
    }

    // 1. Primary DB Key: Numeric volunteer ID match
    if (hasAuthNumeric &&
        parsedRecordNumeric != null &&
        parsedRecordNumeric > 0) {
      final isMatch = parsedRecordNumeric == effectiveAuthNumeric;
      if (!isMatch) {
        debugPrint(
          '[OWNERSHIP] Excluded foreign record (record volunteer_id: $parsedRecordNumeric, auth: $effectiveAuthNumeric)',
        );
      }
      return isMatch;
    }

    // 2. Volunteer code match (e.g. "COHV-26-0016")
    if (effectiveAuthCode.isNotEmpty) {
      if (cleanRecordCode.isNotEmpty && cleanRecordCode == effectiveAuthCode) {
        return true;
      }
      if (cleanRecordId.isNotEmpty && cleanRecordId == effectiveAuthCode) {
        return true;
      }
    }

    // 3. Fallback extraction: If auth code has numeric suffix matching parsed record ID
    if (effectiveAuthCode.isNotEmpty &&
        parsedRecordNumeric != null &&
        parsedRecordNumeric > 0) {
      final authNum = extractNumericSuffix(effectiveAuthCode);
      if (authNum != null && authNum == parsedRecordNumeric) {
        return true;
      }
    }

    // 4. Fallback extraction: If record code has numeric suffix matching effectiveAuthNumeric
    if (hasAuthNumeric) {
      final recNum =
          extractNumericSuffix(cleanRecordCode) ??
          extractNumericSuffix(cleanRecordId);
      if (recNum != null && recNum == effectiveAuthNumeric) {
        return true;
      }
    }

    // No valid match found - exclude record
    return false;
  }
}
