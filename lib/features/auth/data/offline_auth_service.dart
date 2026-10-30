import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/storage/session_manager.dart';

import '../domain/auth_models.dart';

/// Result object for offline credential verification.
class OfflineAuthResult {
  final bool success;
  final UserSession? session;
  final String? errorMessage;

  const OfflineAuthResult({
    required this.success,
    this.session,
    this.errorMessage,
  });
}

/// Service managing offline credential caching, secure PIN hashing,
/// and local authentication when network connectivity is unavailable.
class OfflineAuthService {
  static const String _keyOfflineIdentifier = 'offline_auth_identifier';
  static const String _keyOfflineMobile = 'offline_auth_mobile';
  static const String _keyOfflineVolunteerId = 'offline_auth_volunteer_id';
  static const String _keyOfflineNumericId = 'offline_auth_numeric_id';
  static const String _keyOfflinePinHash = 'offline_auth_pin_hash';
  static const String _keyOfflineSalt = 'offline_auth_salt';
  static const String _keyOfflineSessionJson = 'offline_auth_session_json';
  static const String _keyOfflineLastLogin = 'offline_auth_last_login';

  /// Computes a salted SHA-256 hash of the given [pin] and [salt].
  static String _hashPin({required String pin, required String salt}) {
    final bytes = utf8.encode('$salt:${pin.trim()}');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Normalizes a mobile number string to 10 digits for consistent comparison.
  static String _normalizeMobile(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Normalizes an identifier (volunteer code or mobile) for comparison.
  static String _normalizeIdentifier(String identifier) {
    return identifier.trim().toUpperCase();
  }

  /// Saves the user session and a salted hash of the PIN locally
  /// upon a successful online authentication.
  Future<void> saveOfflineCredentials({
    required String identifier,
    required String pin,
    required UserSession session,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Generate a persistent, unique salt for this device/user
      final salt =
          prefs.getString(_keyOfflineSalt) ??
          'SALT-${DateTime.now().microsecondsSinceEpoch}-${session.volunteerId}';

      final pinHash = _hashPin(pin: pin, salt: salt);
      final normalizedInput = _normalizeIdentifier(identifier);
      final normalizedMobile = _normalizeMobile(session.mobile);
      final normalizedVolunteerId = _normalizeIdentifier(session.volunteerId);
      final numericId = session.numericVolunteerId?.toString() ?? '';

      await prefs.setString(_keyOfflineSalt, salt);
      await prefs.setString(_keyOfflinePinHash, pinHash);
      await prefs.setString(_keyOfflineIdentifier, normalizedInput);
      await prefs.setString(_keyOfflineMobile, normalizedMobile);
      await prefs.setString(_keyOfflineVolunteerId, normalizedVolunteerId);
      if (numericId.isNotEmpty) {
        await prefs.setString(_keyOfflineNumericId, numericId);
      }
      await prefs.setString(
        _keyOfflineSessionJson,
        jsonEncode(session.toJson()),
      );
      await prefs.setString(
        _keyOfflineLastLogin,
        DateTime.now().toUtc().toIso8601String(),
      );

      debugPrint(
        '[OFFLINE_AUTH] Saved offline credentials for ${session.volunteerId} (Mobile: $normalizedMobile)',
      );
    } catch (e) {
      debugPrint('[OFFLINE_AUTH] Error saving offline credentials: $e');
    }
  }

  /// Verifies whether the entered [identifier] and [pin] match the locally
  /// stored credentials on this device.
  Future<OfflineAuthResult> verifyOfflineCredentials({
    required String identifier,
    required String pin,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final storedPinHash = prefs.getString(_keyOfflinePinHash);
      final storedSalt = prefs.getString(_keyOfflineSalt);
      final storedSessionJson = prefs.getString(_keyOfflineSessionJson);

      if (storedPinHash == null ||
          storedSalt == null ||
          storedSessionJson == null ||
          storedSessionJson.isEmpty) {
        // Fallback: Check if user previously logged in on this device via SessionManager
        final existingSession = await SessionManager.getUserSession();
        if (existingSession != null && existingSession.volunteerId.isNotEmpty) {
          final normalizedInput = _normalizeIdentifier(identifier);
          final inputDigits = _normalizeMobile(identifier);
          final sessionCode = _normalizeIdentifier(existingSession.volunteerId);
          final sessionMobile = _normalizeMobile(existingSession.mobile);
          final sessionNumId =
              existingSession.numericVolunteerId?.toString() ?? '';

          final matchesExisting =
              (sessionMobile.isNotEmpty && inputDigits == sessionMobile) ||
              (sessionCode.isNotEmpty && normalizedInput == sessionCode) ||
              (sessionNumId.isNotEmpty && normalizedInput == sessionNumId);

          if (matchesExisting) {
            // Save offline credentials using this entered PIN
            await saveOfflineCredentials(
              identifier: identifier,
              pin: pin,
              session: existingSession,
            );
            debugPrint(
              '[OFFLINE_AUTH] Initialized offline credentials from existing session for ${existingSession.volunteerId}',
            );
            return OfflineAuthResult(success: true, session: existingSession);
          }
        }

        return const OfflineAuthResult(
          success: false,
          errorMessage:
              'No saved credentials found on this device for offline login. Please sign in online first.',
        );
      }

      final normalizedInput = _normalizeIdentifier(identifier);
      final inputDigits = _normalizeMobile(identifier);

      final storedMobile = prefs.getString(_keyOfflineMobile) ?? '';
      final storedVolunteerId = prefs.getString(_keyOfflineVolunteerId) ?? '';
      final storedIdentifier = prefs.getString(_keyOfflineIdentifier) ?? '';
      final storedNumericId = prefs.getString(_keyOfflineNumericId) ?? '';

      // Check if identifier matches stored mobile, volunteer code, or numeric ID
      final isIdentifierMatch =
          (storedMobile.isNotEmpty && inputDigits == storedMobile) ||
          (storedVolunteerId.isNotEmpty &&
              normalizedInput == storedVolunteerId) ||
          (storedIdentifier.isNotEmpty &&
              normalizedInput == storedIdentifier) ||
          (storedNumericId.isNotEmpty && normalizedInput == storedNumericId);

      if (!isIdentifierMatch) {
        return const OfflineAuthResult(
          success: false,
          errorMessage: 'The entered Mobile/Volunteer ID does not match the account saved on this device.',
        );
      }

      // Check PIN hash
      final enteredPinHash = _hashPin(pin: pin, salt: storedSalt);

      if (enteredPinHash != storedPinHash) {
        return const OfflineAuthResult(
          success: false,
          errorMessage: 'Incorrect PIN. Please try again.',
        );
      }

      // Restore session
      final Map<String, dynamic> sessionMap = jsonDecode(storedSessionJson);
      final session = UserSession.fromJson(sessionMap);

      debugPrint(
        '[OFFLINE_AUTH] Offline login successful for ${session.volunteerId} (${session.fullName})',
      );

      return OfflineAuthResult(success: true, session: session);
    } catch (e) {
      debugPrint('[OFFLINE_AUTH] Error verifying offline credentials: $e');
      return OfflineAuthResult(
        success: false,
        errorMessage: 'Offline login verification failed: $e',
      );
    }
  }

  /// Checks whether valid offline credentials are saved on this device.
  Future<bool> hasOfflineCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPinHash = prefs.getString(_keyOfflinePinHash);
      final storedSessionJson = prefs.getString(_keyOfflineSessionJson);
      return storedPinHash != null &&
          storedPinHash.isNotEmpty &&
          storedSessionJson != null &&
          storedSessionJson.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the saved volunteer name or ID for UI display.
  Future<String?> getSavedVolunteerName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyOfflineSessionJson);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        return decoded['volunteer_name'] ?? decoded['full_name'];
      }
    } catch (_) {}
    return null;
  }
}
