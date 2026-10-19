import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/profile/domain/profile_models.dart';
import 'package:cohv/features/events/domain/event_models.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUserSession = 'user_session_json';
  static const String _keyVolunteerId = 'volunteer_id';
  static const String _keyVolunteerName = 'volunteer_name';

  /// Save active user session to SharedPreferences
  static Future<void> saveSession(UserSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (session.token.isNotEmpty) {
        await prefs.setString(_keyToken, session.token);
      }
      await prefs.setString(_keyVolunteerId, session.volunteerId);
      await prefs.setString(_keyVolunteerName, session.fullName);
      await prefs.setString(_keyUserSession, jsonEncode(session.toJson()));
      debugPrint('[SESSION] Saved session for ${session.volunteerId} (${session.fullName})');
    } catch (e) {
      debugPrint('[SESSION] Error saving session: $e');
    }
  }

  /// Retrieve stored JWT / Bearer auth token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
    } catch (e) {
      debugPrint('[SESSION] Error getting token: $e');
    }
    return null;
  }

  /// Retrieve cached UserSession
  static Future<UserSession?> getUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_keyUserSession);
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(sessionJson);
        final token = prefs.getString(_keyToken);
        return UserSession.fromJson(decoded, token: token);
      }
    } catch (e) {
      debugPrint('[SESSION] Error getting cached session: $e');
    }
    return null;
  }

  /// Get cached Volunteer ID
  static Future<String?> getVolunteerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyVolunteerId);
    } catch (_) {
      return null;
    }
  }

  /// Get cached Volunteer Full Name
  static Future<String?> getVolunteerName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyVolunteerName);
    } catch (_) {
      return null;
    }
  }

  /// Check whether user has a stored token
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // =========================================================================
  // 👤 DETAILED PROFILE PERSISTENCE (Merges user-edited fields with /api/auth/me)
  // =========================================================================
  static const String _keyDetailedProfile = 'detailed_volunteer_profile_json';

  /// Save detailed profile to local storage
  static Future<void> saveDetailedProfile(DetailedVolunteerProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDetailedProfile, jsonEncode(profile.toJson()));
      debugPrint('[SESSION] Saved detailed volunteer profile to local storage.');
    } catch (e) {
      debugPrint('[SESSION] Error saving detailed profile: $e');
    }
  }

  /// Retrieve locally saved detailed profile
  static Future<DetailedVolunteerProfile?> getDetailedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyDetailedProfile);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return DetailedVolunteerProfile.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[SESSION] Error getting detailed profile: $e');
    }
    return null;
  }

  // =========================================================================
  // 📋 LOGIN HISTORY AUDIT LOG (Dynamically updated on login)
  // =========================================================================
  static const String _keyLoginHistory = 'user_login_history_records';

  /// Prepend a new login event into local audit history
  static Future<void> addLoginHistoryEntry(LoginHistoryEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_keyLoginHistory) ?? [];
      final encoded = jsonEncode(entry.toJson());

      // Filter out immediate exact duplicate if called repeatedly
      final updated = [
        encoded,
        ...existing.where((item) {
          try {
            final decoded = jsonDecode(item);
            return decoded['timestamp'] != entry.timestamp;
          } catch (_) {
            return true;
          }
        }),
      ];

      // Keep up to 50 recent records
      if (updated.length > 50) {
        updated.removeRange(50, updated.length);
      }

      await prefs.setStringList(_keyLoginHistory, updated);
      debugPrint('[SESSION] Saved dynamic login history entry: ${entry.timestamp} (${entry.authMethod})');
    } catch (e) {
      debugPrint('[SESSION] Error saving login history: $e');
    }
  }

  /// Retrieve dynamic recorded login history list (strictly no static fake data)
  static Future<List<LoginHistoryEntry>> getLoginHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyLoginHistory);
      if (list != null && list.isNotEmpty) {
        return list.map((item) {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          return LoginHistoryEntry.fromJson(decoded);
        }).toList();
      }
    } catch (e) {
      debugPrint('[SESSION] Error reading login history: $e');
    }
    return [];
  }

  /// Get latest login timestamp for "Last login" field
  static Future<String?> getLatestLoginTimestamp() async {
    final history = await getLoginHistory();
    if (history.isNotEmpty) {
      return history.first.timestamp;
    }
    return null;
  }

  // =========================================================================
  // 📝 EVENT FORM METADATA CACHE (Dynamic dropdowns per logged-in volunteer)
  // =========================================================================
  static const String _keyEventFormMetadata = 'event_form_metadata_json';

  /// Cache event form metadata from /api/events/form-metadata
  static Future<void> saveEventFormMetadata(Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEventFormMetadata, jsonEncode(json));
      debugPrint('[SESSION] Saved event form metadata cache.');
    } catch (e) {
      debugPrint('[SESSION] Error saving event form metadata: $e');
    }
  }

  /// Retrieve cached event form metadata
  static Future<Map<String, dynamic>?> getEventFormMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyEventFormMetadata);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[SESSION] Error getting event form metadata: $e');
    }
    return null;
  }

  // =========================================================================
  // 📋 SUBMITTED HEALTH EVENT REPORTS PERSISTENCE
  // =========================================================================
  static const String _keySubmittedEvents = 'submitted_events_list_json';

  /// Retrieve list of locally saved submitted events
  static Future<List<EventReportItem>> getSubmittedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getString(_keySubmittedEvents);
      if (listJson != null && listJson.isNotEmpty) {
        final List decoded = jsonDecode(listJson);
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => EventReportItem.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('[SESSION] Error getting submitted events: $e');
    }
    return [];
  }

  /// Save or prepend newly submitted event
  static Future<void> saveSubmittedEvent(EventReportItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getSubmittedEvents();
      existing.removeWhere((e) => e.id == item.id);
      existing.insert(0, item);
      await prefs.setString(
        _keySubmittedEvents,
        jsonEncode(existing.map((e) => e.toJson()).toList()),
      );
      debugPrint('[SESSION] Saved submitted event ${item.id} to storage.');
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted event: $e');
    }
  }

  /// Save full list of submitted events
  static Future<void> saveSubmittedEventsList(List<EventReportItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keySubmittedEvents,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted events list: $e');
    }
  }

  /// Clear all stored session credentials (used on logout or 401 Unauthorized)
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserSession);
      await prefs.remove(_keyVolunteerId);
      await prefs.remove(_keyVolunteerName);
      await prefs.remove(_keyEventFormMetadata);
      debugPrint('[SESSION] Cleared local user session.');
    } catch (e) {
      debugPrint('[SESSION] Error clearing session: $e');
    }
  }
}
