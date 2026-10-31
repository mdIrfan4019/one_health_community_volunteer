import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/profile/domain/profile_models.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';
import 'package:cohv/features/dashboard/domain/dashboard_models.dart';
import 'volunteer_ownership_filter.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUserSession = 'user_session_json';
  static const String _keyVolunteerId = 'volunteer_id';
  static const String _keyNumericVolunteerId = 'numeric_volunteer_id';
  static const String _keyVolunteerName = 'volunteer_name';
  static const String _keyDeviceId = 'persistent_device_id';

  /// In-memory token cache for synchronous, zero-latency access across the app.
  static String? _cachedToken;
  static String? get cachedToken => _cachedToken;
  static void setCachedToken(String? token) => _cachedToken = token;

  /// Returns a persistent, unique device identifier generated once per installation.
  /// Prevents multiple devices from sharing the same hardcoded device ID.
  static Future<String> getOrCreateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_keyDeviceId);
      if (id != null && id.trim().isNotEmpty) {
        return id.trim();
      }
      final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase();
      final randPart = (DateTime.now().millisecond * 31).toRadixString(36).toUpperCase();
      final generated = 'DEV-$now$randPart';
      await prefs.setString(_keyDeviceId, generated);
      return generated;
    } catch (_) {
      return 'DEV-COHV-ANDROID';
    }
  }

  /// Generates a scoped cache key for submitted events unique to the volunteer
  static String _volunteerEventsKey(String volunteerId) =>
      'submitted_events_${volunteerId.trim().toUpperCase()}_json';

  /// Generates a scoped cache key for submitted referrals unique to the volunteer
  static String _volunteerReferralsKey(String volunteerId) =>
      'submitted_referrals_${volunteerId.trim().toUpperCase()}_json';

  /// Generates a scoped cache key for awareness activities unique to the volunteer
  static String _volunteerAwarenessKey(String volunteerId) =>
      'submitted_awareness_${volunteerId.trim().toUpperCase()}_json';

  /// Generates a scoped cache key for sample support records unique to the volunteer
  static String _volunteerSampleSupportKey(String volunteerId) =>
      'submitted_sample_support_${volunteerId.trim().toUpperCase()}_json';

  /// Generates a scoped cache key for success stories unique to the volunteer
  static String _volunteerSuccessStoriesKey(String volunteerId) =>
      'submitted_success_stories_${volunteerId.trim().toUpperCase()}_json';

  /// Generates a scoped cache key for dashboard metrics unique to the volunteer
  static String _volunteerDashboardMetricsKey(String volunteerId) =>
      'cached_dashboard_metrics_${volunteerId.trim().toUpperCase()}_json';

  /// Save active user session to SharedPreferences
  static Future<void> saveSession(UserSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (session.token.isNotEmpty) {
        _cachedToken = session.token.trim();
        await prefs.setString(_keyToken, session.token.trim());
      }
      await prefs.setString(_keyVolunteerId, session.volunteerId);
      await prefs.setString(_keyVolunteerName, session.fullName);
      if (session.numericVolunteerId != null && session.numericVolunteerId! > 0) {
        await prefs.setInt(_keyNumericVolunteerId, session.numericVolunteerId!);
      }
      await prefs.setString(_keyUserSession, jsonEncode(session.toJson()));
      debugPrint('[SESSION] Saved session for ${session.volunteerId} (numeric: ${session.numericVolunteerId}, ${session.fullName})');
    } catch (e) {
      debugPrint('[SESSION] Error saving session: $e');
    }
  }

  /// Retrieve stored JWT / Bearer auth token
  static Future<String?> getToken() async {
    if (_cachedToken != null && _cachedToken!.trim().isNotEmpty) {
      return _cachedToken!.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      if (token != null && token.trim().isNotEmpty) {
        _cachedToken = token.trim();
        return _cachedToken;
      }
      final sessionJson = prefs.getString(_keyUserSession);
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final dynamic decoded = jsonDecode(sessionJson);
        if (decoded is Map) {
          final t = decoded['token'] ?? decoded['access_token'];
          if (t != null && t.toString().trim().isNotEmpty) {
            _cachedToken = t.toString().trim();
            return _cachedToken;
          }
        }
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
        final session = UserSession.fromJson(decoded, token: token);
        // Ensure numeric volunteer ID is kept consistent if stored separately
        final storedNumId = prefs.getInt(_keyNumericVolunteerId);
        if (session.numericVolunteerId == null && storedNumId != null && storedNumId > 0) {
          return session.copyWith(numericVolunteerId: storedNumId);
        }
        return session;
      }
    } catch (e) {
      debugPrint('[SESSION] Error getting cached session: $e');
    }
    return null;
  }

  /// Get cached Volunteer ID (Code)
  static Future<String?> getVolunteerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_keyVolunteerId);
      if (id != null && id.isNotEmpty) return id;
      final session = await getUserSession();
      return session?.volunteerId;
    } catch (_) {
      return null;
    }
  }

  /// Get cached Numeric Volunteer ID (Primary DB integer key)
  static Future<int?> getNumericVolunteerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final numId = prefs.getInt(_keyNumericVolunteerId);
      if (numId != null && numId > 0) return numId;
      final session = await getUserSession();
      if (session?.numericVolunteerId != null && session!.numericVolunteerId! > 0) {
        return session.numericVolunteerId;
      }
      final detailed = await getDetailedProfile();
      if (detailed?.numericVolunteerId != null && detailed!.numericVolunteerId! > 0) {
        return detailed.numericVolunteerId;
      }
    } catch (_) {}
    return null;
  }

  /// Explicitly save or update the numeric volunteer ID in SharedPreferences
  static Future<void> saveNumericVolunteerId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyNumericVolunteerId, id);
    } catch (_) {}
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
      if (profile.numericVolunteerId != null && profile.numericVolunteerId! > 0) {
        await prefs.setInt(_keyNumericVolunteerId, profile.numericVolunteerId!);
      }
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
  // 📋 SUBMITTED HEALTH EVENT REPORTS PERSISTENCE (Volunteer-Scoped)
  // =========================================================================
  static const String _keySubmittedEvents = 'submitted_events_list_json';

  /// Retrieve list of locally saved submitted events strictly scoped
  /// to the authenticated volunteer.
  static Future<List<EventReportItem>> getSubmittedEvents({
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.trim().isNotEmpty)
          ? volunteerId.trim()
          : (session?.volunteerId ?? '');
      final authNumId = numericVolunteerId ?? session?.numericVolunteerId;

      List<EventReportItem> allItems = [];

      // 1. Try reading volunteer-scoped key first
      if (authCode.isNotEmpty) {
        final scopedKey = _volunteerEventsKey(authCode);
        final scopedJson = prefs.getString(scopedKey);
        if (scopedJson != null && scopedJson.isNotEmpty) {
          final List decoded = jsonDecode(scopedJson);
          allItems.addAll(
            decoded
                .whereType<Map<String, dynamic>>()
                .map((e) => EventReportItem.fromJson(e)),
          );
        }
      }

      // 2. Also inspect legacy global key if scoped was empty, filtering strictly
      if (allItems.isEmpty) {
        final listJson = prefs.getString(_keySubmittedEvents);
        if (listJson != null && listJson.isNotEmpty) {
          final List decoded = jsonDecode(listJson);
          allItems.addAll(
            decoded
                .whereType<Map<String, dynamic>>()
                .map((e) => EventReportItem.fromJson(e)),
          );
        }
      }

      // 3. Apply strict volunteer ownership filter & purge phantom dummy entries
      bool hadPhantom = false;
      final filtered = allItems.where((item) {
        if (item.id == 'EVT-26-0001') {
          hadPhantom = true;
          return false;
        }
        // If the item has ownership fields, check ownership strictly
        return VolunteerOwnershipFilter.isOwnedByVolunteer(
          recordNumericVolunteerId: item.numericVolunteerId,
          recordVolunteerCode: item.volunteerId,
          recordVolunteerId: item.volunteerId,
          recordVolunteerName: item.volunteerName,
          authNumericVolunteerId: authNumId,
          authVolunteerCode: authCode,
        );
      }).toList();

      // If phantom was encountered, clean up persisted storage immediately
      if (hadPhantom) {
        final cleanedJson = jsonEncode(filtered.map((e) => e.toJson()).toList());
        if (authCode.isNotEmpty) {
          await prefs.setString(_volunteerEventsKey(authCode), cleanedJson);
        }
        await prefs.setString(_keySubmittedEvents, cleanedJson);
      }

      return filtered;
    } catch (e) {
      debugPrint('[SESSION] Error getting submitted events: $e');
    }
    return [];
  }

  /// Explicitly remove a submitted event (e.g. phantom 'EVT-26-0001') from all local storage caches
  static Future<void> removeSubmittedEvent(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = session?.volunteerId ?? '';

      if (authCode.isNotEmpty) {
        final key = _volunteerEventsKey(authCode);
        final listJson = prefs.getString(key);
        if (listJson != null && listJson.isNotEmpty) {
          final List decoded = jsonDecode(listJson);
          final updated = decoded
              .where((e) =>
                  e is Map &&
                  e['id']?.toString() != eventId &&
                  e['event_report_code']?.toString() != eventId)
              .toList();
          await prefs.setString(key, jsonEncode(updated));
        }
      }

      final globalJson = prefs.getString(_keySubmittedEvents);
      if (globalJson != null && globalJson.isNotEmpty) {
        final List decoded = jsonDecode(globalJson);
        final updated = decoded
            .where((e) =>
                e is Map &&
                e['id']?.toString() != eventId &&
                e['event_report_code']?.toString() != eventId)
            .toList();
        await prefs.setString(_keySubmittedEvents, jsonEncode(updated));
      }
      debugPrint('[SESSION] Purged phantom event $eventId from local storage.');
    } catch (e) {
      debugPrint('[SESSION] Error removing submitted event $eventId: $e');
    }
  }

  /// Save or prepend newly submitted event scoped to the volunteer
  static Future<void> saveSubmittedEvent(
    EventReportItem item, {
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : ((item.volunteerId != null && item.volunteerId!.isNotEmpty)
              ? item.volunteerId!
              : (session?.volunteerId ?? ''));
      final authNumId = numericVolunteerId ?? item.numericVolunteerId ?? session?.numericVolunteerId;

      // Stamp item with ownership if missing
      final stampedItem = item.volunteerId != null
          ? item
          : item.copyWith(
              volunteerId: authCode.isNotEmpty ? authCode : null,
              numericVolunteerId: authNumId,
              volunteerName: session?.fullName,
            );

      final existing = await getSubmittedEvents(
        volunteerId: authCode,
        numericVolunteerId: authNumId,
      );

      // Clean existing matches (by ID, numeric ID, or phantom ID)
      existing.removeWhere((e) =>
          e.id == 'EVT-26-0001' ||
          e.id == stampedItem.id ||
          (stampedItem.numericId != null &&
              e.numericId != null &&
              e.numericId == stampedItem.numericId));

      if (stampedItem.id != 'EVT-26-0001') {
        existing.insert(0, stampedItem);
      }

      final encoded = jsonEncode(existing.map((e) => e.toJson()).toList());

      // Save to scoped storage
      if (authCode.isNotEmpty) {
        await prefs.setString(_volunteerEventsKey(authCode), encoded);
      }
      // Also update global legacy key for current session
      await prefs.setString(_keySubmittedEvents, encoded);

      debugPrint('[SESSION] Saved submitted event ${stampedItem.id} for volunteer $authCode.');
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted event: $e');
    }
  }

  /// Save full list of submitted events scoped to the volunteer
  static Future<void> saveSubmittedEventsList(
    List<EventReportItem> items, {
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ??
              items
                  .map((e) => e.volunteerId)
                  .firstWhere((id) => id != null && id.isNotEmpty, orElse: () => null) ??
              '');
      final authNumId = numericVolunteerId ??
          session?.numericVolunteerId ??
          items
              .map((e) => e.numericVolunteerId)
              .firstWhere((id) => id != null && id > 0, orElse: () => null);

      // Ensure only owned items are stored
      final ownedItems = items.where((item) {
        return VolunteerOwnershipFilter.isOwnedByVolunteer(
          recordNumericVolunteerId: item.numericVolunteerId,
          recordVolunteerCode: item.volunteerId,
          recordVolunteerId: item.volunteerId,
          recordVolunteerName: item.volunteerName,
          authNumericVolunteerId: authNumId,
          authVolunteerCode: authCode,
        );
      }).toList();

      final encoded = jsonEncode(ownedItems.map((e) => e.toJson()).toList());
      if (authCode.isNotEmpty) {
        await prefs.setString(_volunteerEventsKey(authCode), encoded);
      }
      await prefs.setString(_keySubmittedEvents, encoded);
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted events list: $e');
    }
  }

  // =========================================================================
  // 📋 SUBMITTED REFERRALS PERSISTENCE (Volunteer-Scoped)
  // =========================================================================
  static const String _keySubmittedReferrals = 'submitted_referrals_list_json';

  /// Retrieve list of locally saved submitted referrals strictly scoped
  /// to the authenticated volunteer.
  static Future<List<ReferralItem>> getSubmittedReferrals({
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.trim().isNotEmpty)
          ? volunteerId.trim()
          : (session?.volunteerId ?? '');
      final authNumId = numericVolunteerId ?? session?.numericVolunteerId;

      List<ReferralItem> allItems = [];

      // 1. Try reading volunteer-scoped key first
      if (authCode.isNotEmpty) {
        final scopedKey = _volunteerReferralsKey(authCode);
        final scopedJson = prefs.getString(scopedKey);
        if (scopedJson != null && scopedJson.isNotEmpty) {
          final List decoded = jsonDecode(scopedJson);
          allItems.addAll(
            decoded
                .whereType<Map<String, dynamic>>()
                .map((e) => ReferralItem.fromJson(e)),
          );
        }
      }

      // 2. Also inspect legacy global key if scoped was empty
      if (allItems.isEmpty) {
        final listJson = prefs.getString(_keySubmittedReferrals);
        if (listJson != null && listJson.isNotEmpty) {
          final List decoded = jsonDecode(listJson);
          allItems.addAll(
            decoded
                .whereType<Map<String, dynamic>>()
                .map((e) => ReferralItem.fromJson(e)),
          );
        }
      }

      // 3. Apply strict volunteer ownership filter & purge any phantom 'REF-26-0001'
      bool hadPhantom = false;
      final filtered = allItems.where((item) {
        if (item.id == 'REF-26-0001') {
          hadPhantom = true;
          return false;
        }
        return VolunteerOwnershipFilter.isOwnedByVolunteer(
          recordNumericVolunteerId: item.numericVolunteerId,
          recordVolunteerCode: item.volunteerCode,
          recordVolunteerId: item.volunteerId,
          recordVolunteerName: item.volunteerName,
          authNumericVolunteerId: authNumId,
          authVolunteerCode: authCode,
        );
      }).toList();

      // If phantom was encountered, clean up persisted storage immediately
      if (hadPhantom) {
        final cleanedJson = jsonEncode(filtered.map((e) => e.toJson()).toList());
        if (authCode.isNotEmpty) {
          await prefs.setString(_volunteerReferralsKey(authCode), cleanedJson);
        }
        await prefs.setString(_keySubmittedReferrals, cleanedJson);
      }

      return filtered;
    } catch (e) {
      debugPrint('[SESSION] Error getting submitted referrals: $e');
    }
    return [];
  }

  /// Explicitly remove a submitted referral (e.g. phantom 'REF-26-0001') from all local storage caches
  static Future<void> removeSubmittedReferral(String referralId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = session?.volunteerId ?? '';

      if (authCode.isNotEmpty) {
        final key = _volunteerReferralsKey(authCode);
        final listJson = prefs.getString(key);
        if (listJson != null && listJson.isNotEmpty) {
          final List decoded = jsonDecode(listJson);
          final updated = decoded
              .where((e) =>
                  e is Map &&
                  e['id']?.toString() != referralId &&
                  e['referral_code']?.toString() != referralId)
              .toList();
          await prefs.setString(key, jsonEncode(updated));
        }
      }

      final globalJson = prefs.getString(_keySubmittedReferrals);
      if (globalJson != null && globalJson.isNotEmpty) {
        final List decoded = jsonDecode(globalJson);
        final updated = decoded
            .where((e) =>
                e is Map &&
                e['id']?.toString() != referralId &&
                e['referral_code']?.toString() != referralId)
            .toList();
        await prefs.setString(_keySubmittedReferrals, jsonEncode(updated));
      }
      debugPrint('[SESSION] Purged phantom referral $referralId from local storage.');
    } catch (e) {
      debugPrint('[SESSION] Error removing submitted referral $referralId: $e');
    }
  }

  /// Save or prepend newly submitted referral scoped to the volunteer
  static Future<void> saveSubmittedReferral(
    ReferralItem item, {
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (item.volunteerCode?.isNotEmpty == true
              ? item.volunteerCode!
              : (item.volunteerId.isNotEmpty
                  ? item.volunteerId
                  : (session?.volunteerId ?? '')));
      final authNumId = numericVolunteerId ?? item.numericVolunteerId ?? session?.numericVolunteerId;

      final existing = await getSubmittedReferrals(
        volunteerId: authCode,
        numericVolunteerId: authNumId,
      );
      // Clean existing matches (by ID, numeric ID, or phantom ID)
      existing.removeWhere((e) =>
          e.id == 'REF-26-0001' ||
          e.id == item.id ||
          (item.referralId != null &&
              e.referralId != null &&
              e.referralId == item.referralId));

      if (item.id != 'REF-26-0001') {
        existing.insert(0, item);
      }

      final encoded = jsonEncode(existing.map((e) => e.toJson()).toList());

      if (authCode.isNotEmpty) {
        await prefs.setString(_volunteerReferralsKey(authCode), encoded);
      }
      await prefs.setString(_keySubmittedReferrals, encoded);

      debugPrint('[SESSION] Saved submitted referral ${item.id} for volunteer $authCode.');
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted referral: $e');
    }
  }

  /// Save full list of submitted referrals scoped to the volunteer
  static Future<void> saveSubmittedReferralsList(
    List<ReferralItem> items, {
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ??
              items
                  .map((e) => e.volunteerCode ?? e.volunteerId)
                  .firstWhere((id) => id.isNotEmpty, orElse: () => ''));
      final authNumId = numericVolunteerId ??
          session?.numericVolunteerId ??
          items
              .map((e) => e.numericVolunteerId)
              .firstWhere((id) => id != null && id > 0, orElse: () => null);

      // Filter to only items owned by this volunteer
      final ownedItems = items.where((item) {
        return VolunteerOwnershipFilter.isOwnedByVolunteer(
          recordNumericVolunteerId: item.numericVolunteerId,
          recordVolunteerCode: item.volunteerCode,
          recordVolunteerId: item.volunteerId,
          recordVolunteerName: item.volunteerName,
          authNumericVolunteerId: authNumId,
          authVolunteerCode: authCode,
        );
      }).toList();

      final encoded = jsonEncode(ownedItems.map((e) => e.toJson()).toList());
      if (authCode.isNotEmpty) {
        await prefs.setString(_volunteerReferralsKey(authCode), encoded);
      }
      await prefs.setString(_keySubmittedReferrals, encoded);
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted referrals list: $e');
    }
  }

  // =========================================================================
  // 📋 SUBMITTED AWARENESS ACTIVITIES PERSISTENCE (Volunteer-Scoped)
  // =========================================================================

  /// Retrieve list of locally saved submitted awareness activities strictly scoped
  /// to the authenticated volunteer.
  static Future<List<AwarenessItem>> getSubmittedAwareness({
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.trim().isNotEmpty)
          ? volunteerId.trim()
          : (session?.volunteerId ?? '');
      final authNumId = numericVolunteerId ?? session?.numericVolunteerId;

      if (authCode.isEmpty && authNumId == null) return [];

      final scopedKey = _volunteerAwarenessKey(authCode);
      final scopedJson = prefs.getString(scopedKey);
      if (scopedJson != null && scopedJson.isNotEmpty) {
        final List decoded = jsonDecode(scopedJson);
        final items = decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => AwarenessItem.fromJson(e))
            .where((item) {
              return VolunteerOwnershipFilter.isOwnedByVolunteer(
                recordNumericVolunteerId: item.numericVolunteerId,
                recordVolunteerCode: item.volunteerCode,
                recordVolunteerId: item.volunteerId,
                recordVolunteerName: item.volunteerName,
                authNumericVolunteerId: authNumId,
                authVolunteerCode: authCode,
              );
            }).toList();
        return items;
      }
    } catch (e) {
      debugPrint('[SESSION] Error getting submitted awareness activities: $e');
    }
    return [];
  }

  /// Alias for getSubmittedAwareness
  static Future<List<AwarenessItem>> getSubmittedAwarenessActivities({
    String? volunteerId,
    int? numericVolunteerId,
  }) =>
      getSubmittedAwareness(
        volunteerId: volunteerId,
        numericVolunteerId: numericVolunteerId,
      );

  /// Save or prepend newly submitted awareness activity scoped to the volunteer
  static Future<void> saveSubmittedAwareness(
    AwarenessItem item, {
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (item.volunteerCode?.isNotEmpty == true
              ? item.volunteerCode!
              : (item.volunteerId.isNotEmpty
                  ? item.volunteerId
                  : (session?.volunteerId ?? '')));
      final authNumId = numericVolunteerId ?? item.numericVolunteerId ?? session?.numericVolunteerId;

      final existing = await getSubmittedAwareness(
        volunteerId: authCode,
        numericVolunteerId: authNumId,
      );
      existing.removeWhere((e) => e.id == item.id);
      existing.insert(0, item);

      final encoded = jsonEncode(existing.map((e) => e.toJson()).toList());
      if (authCode.isNotEmpty) {
        await prefs.setString(_volunteerAwarenessKey(authCode), encoded);
      }
      debugPrint('[SESSION] Saved submitted awareness ${item.id} for volunteer $authCode.');
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted awareness: $e');
    }
  }

  /// Alias for saveSubmittedAwareness
  static Future<void> saveSubmittedAwarenessActivity(
    AwarenessItem item, {
    String? volunteerId,
    int? numericVolunteerId,
  }) =>
      saveSubmittedAwareness(
        item,
        volunteerId: volunteerId,
        numericVolunteerId: numericVolunteerId,
      );

  /// Save full list of submitted awareness activities scoped to the volunteer
  static Future<void> saveSubmittedAwarenessList(
    List<AwarenessItem> items, {
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ??
              items
                  .map((e) => e.volunteerCode ?? e.volunteerId)
                  .firstWhere((id) => id.isNotEmpty, orElse: () => ''));
      final authNumId = numericVolunteerId ??
          session?.numericVolunteerId ??
          items
              .map((e) => e.numericVolunteerId)
              .firstWhere((id) => id != null && id > 0, orElse: () => null);

      // Filter to only items owned by this volunteer
      final ownedItems = items.where((item) {
        return VolunteerOwnershipFilter.isOwnedByVolunteer(
          recordNumericVolunteerId: item.numericVolunteerId,
          recordVolunteerCode: item.volunteerCode,
          recordVolunteerId: item.volunteerId,
          recordVolunteerName: item.volunteerName,
          authNumericVolunteerId: authNumId,
          authVolunteerCode: authCode,
        );
      }).toList();

      final encoded = jsonEncode(ownedItems.map((e) => e.toJson()).toList());
      if (authCode.isNotEmpty) {
        await prefs.setString(_volunteerAwarenessKey(authCode), encoded);
      }
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted awareness list: $e');
    }
  }

  /// Save or prepend newly submitted sample support record scoped to the volunteer
  static Future<void> saveSubmittedSampleSupport(
    SampleSupportRecordModel item, {
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ?? '');

      final existing = await getSubmittedSampleSupportList(volunteerId: authCode);
      existing.removeWhere((e) => e.sampleId == item.sampleId || (e.sampleCode.isNotEmpty && e.sampleCode == item.sampleCode));
      existing.insert(0, item);

      final encoded = jsonEncode(existing.map((e) => e.toJson()).toList());
      if (authCode.isNotEmpty) {
        await prefs.setString(_volunteerSampleSupportKey(authCode), encoded);
      }
      debugPrint('[SESSION] Saved sample support record ${item.sampleCode} for volunteer $authCode.');
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted sample support: $e');
    }
  }

  /// Get cached sample support records scoped to the volunteer
  static Future<List<SampleSupportRecordModel>> getSubmittedSampleSupportList({
    String? volunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ?? '');

      if (authCode.isEmpty) return [];

      final raw = prefs.getString(_volunteerSampleSupportKey(authCode));
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => SampleSupportRecordModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[SESSION] Error reading cached sample support: $e');
    }
    return [];
  }

  /// Save full list of sample support records scoped to the volunteer
  static Future<void> saveSubmittedSampleSupportList(
    List<SampleSupportRecordModel> items, {
    String? volunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ?? '');

      if (authCode.isNotEmpty) {
        final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
        await prefs.setString(_volunteerSampleSupportKey(authCode), encoded);
      }
    } catch (e) {
      debugPrint('[SESSION] Error saving sample support list: $e');
    }
  }

  /// Save or prepend newly submitted success story record scoped to the volunteer
  static Future<void> saveSubmittedSuccessStory(
    SuccessStoryRecordModel item, {
    String? volunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ?? '');

      final existing = await getSubmittedSuccessStoriesList(volunteerId: authCode);
      existing.removeWhere((e) =>
          e.storyId == item.storyId ||
          (e.storyCode.isNotEmpty && e.storyCode == item.storyCode));
      existing.insert(0, item);

      final encoded = jsonEncode(existing.map((e) => e.toJson()).toList());
      if (authCode.isNotEmpty) {
        await prefs.setString(_volunteerSuccessStoriesKey(authCode), encoded);
      }
      debugPrint(
        '[SESSION] Saved success story record ${item.storyCode} for volunteer $authCode.',
      );
    } catch (e) {
      debugPrint('[SESSION] Error saving submitted success story: $e');
    }
  }

  /// Get cached success story records scoped to the volunteer
  static Future<List<SuccessStoryRecordModel>> getSubmittedSuccessStoriesList({
    String? volunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ?? '');

      if (authCode.isEmpty) return [];

      final raw = prefs.getString(_volunteerSuccessStoriesKey(authCode));
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) =>
                SuccessStoryRecordModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[SESSION] Error reading cached success stories: $e');
    }
    return [];
  }

  /// Save full list of success story records scoped to the volunteer
  static Future<void> saveSubmittedSuccessStoriesList(
    List<SuccessStoryRecordModel> items, {
    String? volunteerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = await getUserSession();
      final authCode = (volunteerId != null && volunteerId.isNotEmpty)
          ? volunteerId
          : (session?.volunteerId ?? '');

      if (authCode.isNotEmpty) {
        final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
        await prefs.setString(_volunteerSuccessStoriesKey(authCode), encoded);
      }
    } catch (e) {
      debugPrint('[SESSION] Error saving success stories list: $e');
    }
  }

  /// Clear all stored session credentials and cached data (used on logout or 401 Unauthorized)
  static Future<void> clearSession() async {
    _cachedToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Purge active authentication credentials and session tokens
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserSession);
      await prefs.remove(_keyVolunteerId);
      await prefs.remove(_keyNumericVolunteerId);
      await prefs.remove(_keyVolunteerName);
      await prefs.remove(_keyDetailedProfile);
      await prefs.remove(_keyEventFormMetadata);

      // 2. Purge global listing caches so no cross-user data leakage occurs
      await prefs.remove(_keySubmittedEvents);
      await prefs.remove(_keySubmittedReferrals);

      // 3. Purge all volunteer-scoped caches so no cross-user data leakage occurs
      final allKeys = prefs.getKeys().toList();
      for (final key in allKeys) {
        if (key.startsWith('submitted_events_') ||
            key.startsWith('submitted_referrals_') ||
            key.startsWith('submitted_awareness_') ||
            key.startsWith('submitted_sample_support_') ||
            key.startsWith('submitted_success_stories_') ||
            key.startsWith('cached_dashboard_metrics_')) {
          await prefs.remove(key);
        }
      }

      debugPrint('[SESSION] Cleared local user session and purged listing caches.');
    } catch (e) {
      debugPrint('[SESSION] Error clearing session: $e');
    }
  }

  // =========================================================================
  // 📊 DASHBOARD METRICS LOCAL PERSISTENCE
  // =========================================================================

  /// Save cached dashboard summary metrics for instant offline recovery
  static Future<void> saveDashboardMetrics(
    String volunteerId,
    DashboardMetrics metrics,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _volunteerDashboardMetricsKey(volunteerId);
      await prefs.setString(key, jsonEncode(metrics.toJson()));
      debugPrint('[SESSION] Cached dashboard metrics for $volunteerId');
    } catch (e) {
      debugPrint('[SESSION] Error saving dashboard metrics: $e');
    }
  }

  /// Retrieve locally cached dashboard summary metrics
  static Future<DashboardMetrics?> getCachedDashboardMetrics(
    String volunteerId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _volunteerDashboardMetricsKey(volunteerId);
      final jsonStr = prefs.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          return DashboardMetrics.fromJson(decoded);
        }
      }
    } catch (e) {
      debugPrint('[SESSION] Error loading cached dashboard metrics: $e');
    }
    return null;
  }
}
