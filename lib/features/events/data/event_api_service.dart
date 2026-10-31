// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:cohv/core/constants/api_constants.dart';
// import 'package:cohv/core/services/authenticated_http_client.dart';
// import 'package:cohv/core/storage/session_manager.dart';
// import '../../sync/data/sync_repository.dart';
// import '../domain/event_models.dart';
//
// class EventApiService {
//   // =========================================================================
//   // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
//   // =========================================================================
//   static const String baseUrl = ApiConstants.baseUrl;
//   static const String endpointEvents = ApiConstants.endpointEvents;
//   static const String endpointReportEvent = ApiConstants.endpointReportEvent;
//   static const String endpointEventFormMetadata =
//       ApiConstants.endpointEventFormMetadata;

//
//   final http.Client _client;
//   final SyncRepository _syncRepository;
//
//
//   EventApiService({
//     http.Client? client,
//     SyncRepository? syncRepository,
//   })  : _client = client ?? http.Client(),
//         _syncRepository = syncRepository ?? SyncRepository();
//
//   /// Retrieve cached event form metadata for instant UI rendering without flicker
//   Future<EventFormMetadata?> getCachedMetadata() async {
//     try {
//       final cachedJson = await SessionManager.getEventFormMetadata();
//       if (cachedJson != null) {
//         return EventFormMetadata.fromJson(cachedJson);
//       }
//     } catch (e) {
//       debugPrint('[EVENT_API] Error reading cached event form metadata: $e');
//     }
//     return null;
//   }
//
//   /// Fetch dynamic event form metadata for the logged-in volunteer from:
//   /// GET /api/events/form-metadata with Bearer token
//   Future<EventFormMetadata> getEventFormMetadata({
//     bool forceRefresh = false,
//     String? sector,
//   }) async {
//     // 1. If not forcing refresh, check if valid cache exists
//     if (!forceRefresh) {
//       final cached = await getCachedMetadata();
//       if (cached != null) {
//         final matchesSector = sector == null ||
//             cached.primarySector.sectorCode.toLowerCase().contains(sector.toLowerCase()) ||
//             cached.primarySector.sectorName.toLowerCase().contains(sector.toLowerCase());
//         if (matchesSector) {
//           // Asynchronously refresh in background
//           _refreshMetadataInBackground();
//           return cached;
//         }
//       }
//     }
//
//     try {
//       final token = await SessionManager.getToken();
//       final url = Uri.parse(endpointEventFormMetadata);
//
//       debugPrint(
//           '[EVENT_API] GET $url with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}');
//
//       final response = await _client
//           .get(
//             url,
//             headers: ApiConstants.defaultHeaders(token: token),
//           )
//           .timeout(const Duration(seconds: 10));
//
//       debugPrint(
//           '[EVENT_API] /api/events/form-metadata status: ${response.statusCode}, body length: ${response.body.length}');
//
//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(utf8.decode(response.bodyBytes))
//             as Map<String, dynamic>;
//         // Cache to SharedPreferences for offline support
//         await SessionManager.saveEventFormMetadata(decoded);
//         return EventFormMetadata.fromJson(decoded);
//       } else {
//         debugPrint(
//             '[EVENT_API] Server returned non-200 status: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('[EVENT_API] Network error fetching event form metadata: $e');
//     }
//
//     // 2. Fallback to cached data if network failed and matches sector
//     final cached = await getCachedMetadata();
//     if (cached != null) {
//       final matchesSector = sector == null ||
//           cached.primarySector.sectorCode.toLowerCase().contains(sector.toLowerCase()) ||
//           cached.primarySector.sectorName.toLowerCase().contains(sector.toLowerCase());
//       if (matchesSector) {
//         return cached;
//       }
//     }
//
//     // 3. Fallback to default schema configured per volunteer sector
//     debugPrint(
//         '[EVENT_API] Returning schema fallback metadata for volunteer sector ($sector).');
//     return EventFormMetadata.fallback(sector: sector);
//   }
//
//   void _refreshMetadataInBackground() async {
//     try {
//       final token = await SessionManager.getToken();
//       final response = await _client
//           .get(
//             Uri.parse(endpointEventFormMetadata),
//             headers: ApiConstants.defaultHeaders(token: token),
//           )
//           .timeout(const Duration(seconds: 10));
//
//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(utf8.decode(response.bodyBytes))
//             as Map<String, dynamic>;
//         await SessionManager.saveEventFormMetadata(decoded);
//         debugPrint(
//             '[EVENT_API] Background refresh of event form metadata succeeded.');
//       }
//     } catch (_) {}
//   }
//
//   /// Submit event report via POST /api/events (multipart/form-data)
//   ///
//   /// Sends event metadata along with uploaded photographs, videos, and documents
//   /// to the backend server with the logged-in volunteer's Bearer token.
//   /// If offline, automatically enqueues into SyncRepository for later synchronization.
//   Future<EventReportResult> submitEventReport(EventReportRequest request) async {
//     final token = await SessionManager.getToken();
//     final url = Uri.parse(endpointEvents);
//
//     debugPrint(
//         '[EVENT_API] POST $url (multipart/form-data) with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}');
//
//     try {
//       final multipartRequest = http.MultipartRequest('POST', url);
//
//       // 1. Authorization & Header Setup
//       if (token != null && token.isNotEmpty) {
//         multipartRequest.headers['Authorization'] = 'Bearer $token';
//       }
//       multipartRequest.headers['Accept'] = 'application/json';
//
//       // 2. Required Form Fields (Schema: EventReportForm)
//       multipartRequest.fields['event_type_id'] =
//           request.eventTypeId.toString();
//
//       if (request.eventTypeOther != null &&
//           request.eventTypeOther!.trim().isNotEmpty) {
//         multipartRequest.fields['event_type_other'] =
//             request.eventTypeOther!.trim();
//       }
//
//       final dateFormatted =
//           '${request.date.year.toString().padLeft(4, '0')}-${request.date.month.toString().padLeft(2, '0')}-${request.date.day.toString().padLeft(2, '0')}';
//       multipartRequest.fields['date'] = dateFormatted;
//
//       var timeFormatted = request.time.trim();
//       if (timeFormatted.length == 5) {
//         // e.g. "09:30" -> "09:30:00"
//         timeFormatted = '$timeFormatted:00';
//       }
//       multipartRequest.fields['time'] = timeFormatted;
//
//       multipartRequest.fields['village_lgd_code'] =
//           request.villageLgdCode.toString();
//       multipartRequest.fields['is_out_of_area'] =
//           request.isOutOfAreaVisit ? 'true' : 'false';
//       multipartRequest.fields['purpose_of_visit'] = request.purposeOfVisit;
//       multipartRequest.fields['location_type'] = request.locationType;
//       multipartRequest.fields['total_visits'] =
//           request.totalVisits.toString();
//       multipartRequest.fields['population_type_id'] =
//           request.populationTypeId.toString();
//
//       // Sector and population metadata fields
//       multipartRequest.fields['primary_sector'] = request.primarySector;
//       if (request.primarySectorCode != null &&
//           request.primarySectorCode!.trim().isNotEmpty) {
//         multipartRequest.fields['primary_sector_code'] =
//             request.primarySectorCode!.trim();
//       }
//       multipartRequest.fields['target_population'] = request.targetPopulation;
//
//       // Optional Content Fields
//       if (request.populationOther != null &&
//           request.populationOther!.trim().isNotEmpty) {
//         multipartRequest.fields['population_other'] =
//             request.populationOther!.trim();
//       }
//       if (request.observations.trim().isNotEmpty) {
//         multipartRequest.fields['observations'] = request.observations.trim();
//       }
//       if (request.actionTaken.trim().isNotEmpty) {
//         multipartRequest.fields['action_taken'] = request.actionTaken.trim();
//       }
//       final desc = request.description ?? request.mediaCaption;
//       if (desc != null && desc.trim().isNotEmpty) {
//         multipartRequest.fields['description'] = desc.trim();
//       }
//
//       // Flags
//       multipartRequest.fields['referral_generated'] =
//           request.isReferralGenerated ? 'true' : 'false';
//       multipartRequest.fields['alert_generated'] =
//           request.isAlertGenerated ? 'true' : 'false';
//       multipartRequest.fields['follow_up_required'] =
//           request.isFollowUpRequired ? 'true' : 'false';
//
//       // Geolocation Coordinates
//       multipartRequest.fields['latitude'] = request.latitude.toString();
//       multipartRequest.fields['longitude'] = request.longitude.toString();
//       multipartRequest.fields['gps_accuracy_m'] = request.accuracy.toString();
//
//       if (request.gpsUnavailableReason != null &&
//           request.gpsUnavailableReason!.trim().isNotEmpty) {
//         multipartRequest.fields['gps_unavailable_reason'] =
//             request.gpsUnavailableReason!.trim();
//       }
//
//       if (request.deviceId.trim().isNotEmpty) {
//         multipartRequest.fields['device_id'] = request.deviceId.trim();
//       }
//
//       final clientRef = request.clientRef ??
//           'EVT-CLI-${DateTime.now().millisecondsSinceEpoch}';
//       multipartRequest.fields['client_ref'] = clientRef;
//
//       // 3. Attach Media Files (photos, videos, documents)
//       final photos =
//           request.photos.isNotEmpty ? request.photos : request.mediaFiles;
//       for (final filePath in photos) {
//         final file = File(filePath);
//         if (await file.exists()) {
//           final multipartFile =
//               await http.MultipartFile.fromPath('photos', file.path);
//           multipartRequest.files.add(multipartFile);
//         }
//       }
//
//       for (final filePath in request.videos) {
//         final file = File(filePath);
//         if (await file.exists()) {
//           final multipartFile =
//               await http.MultipartFile.fromPath('videos', file.path);
//           multipartRequest.files.add(multipartFile);
//         }
//       }
//
//       for (final filePath in request.documents) {
//         final file = File(filePath);
//         if (await file.exists()) {
//           final multipartFile =
//               await http.MultipartFile.fromPath('documents', file.path);
//           multipartRequest.files.add(multipartFile);
//         }
//       }
//
//       debugPrint(
//           '[EVENT_API] Dispatching multipart request with ${multipartRequest.fields.length} fields and ${multipartRequest.files.length} files...');
//
//       final streamedResponse = await _client
//           .send(multipartRequest)
//           .timeout(const Duration(seconds: 30));
//       final response = await http.Response.fromStream(streamedResponse);
//
//       debugPrint(
//           '[EVENT_API] POST /api/events response status: ${response.statusCode}, body: ${response.body}');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = jsonDecode(utf8.decode(response.bodyBytes))
//             as Map<String, dynamic>;
//         return EventReportResult.fromJson(data);
//       } else {
//         String errorMsg = 'Server returned status ${response.statusCode}';
//         try {
//           final errJson = jsonDecode(utf8.decode(response.bodyBytes));
//           if (errJson is Map && errJson['detail'] != null) {
//             final detail = errJson['detail'];
//             if (detail is String) {
//               errorMsg = detail;
//             } else if (detail is List && detail.isNotEmpty) {
//               final first = detail.first;
//               errorMsg =
//                   '${first['loc'] != null ? first['loc'].last : "Validation"}: ${first['msg']}';
//             }
//           }
//         } catch (_) {}
//         throw Exception(errorMsg);
//       }
//     } catch (e) {
//       debugPrint('[EVENT_API] Exception during event report submission: $e');
//
//       // Offline & Server Error Resilience:
//       // If network is offline, or if server returns validation error due to backend sector-population
//       // desynchronization, or if server returns an internal error (500+), automatically save to
//       // SyncRepository so volunteer surveillance reporting is NEVER blocked and data is preserved.
//       final isOffline = e is SocketException ||
//           e.toString().contains('Failed host lookup') ||
//           e.toString().contains('Connection refused') ||
//           e.toString().contains('ClientException');
//
//       final isServerSyncIssue =
//           e.toString().contains('Selected population is not valid') ||
//           e.toString().contains('status 500') ||
//           e.toString().contains('status 502') ||
//           e.toString().contains('status 503') ||
//           e.toString().contains('status 504') ||
//           e.toString().contains('Internal Server Error');
//
//       if (isOffline || isServerSyncIssue) {
//         final seq = DateTime.now().millisecondsSinceEpoch % 1000;
//         final reportId = 'OFFLINE-EVT-26-${seq.toString().padLeft(4, '0')}';
//         final alertId = request.isAlertGenerated
//             ? 'ALERT-26-${(seq + 1).toString().padLeft(4, '0')}'
//             : null;
//
//         await _syncRepository.enqueueRecord(
//           entityType: 'EVENT',
//           payload: {
//             'report_id': reportId,
//             'alert_id': alertId,
//             ...request.toJson(),
//           },
//         );
//
//         return EventReportResult(
//           reportId: reportId,
//           status: 'queued_offline',
//           alertId: alertId,
//           message: request.isAlertGenerated
//               ? 'Event report queued locally. Alert $alertId will synchronize once connectivity/server is restored.'
//               : 'Event report saved locally and queued for automatic sync.',
//         );
//       }
//
//       rethrow;
//     }
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/services/authenticated_http_client.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/storage/volunteer_ownership_filter.dart';

import '../../sync/data/sync_repository.dart';
import '../domain/event_models.dart';
import 'package:cohv/core/models/geo_location_data.dart';

class EventApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointEvents = ApiConstants.endpointEvents;
  static const String endpointReportEvent = ApiConstants.endpointReportEvent;
  static const String endpointEventFormMetadata =
      ApiConstants.endpointEventFormMetadata;


  static const String endpointPopulationSubcategories =
      ApiConstants.endpointPopulationSubcategories;

  final http.Client _client;
  final SyncRepository _syncRepository;

  EventApiService({http.Client? client, SyncRepository? syncRepository})
    : _client = client ?? AuthenticatedHttpClient.instance,
      _syncRepository = syncRepository ?? SyncRepository();

  /// Retrieve cached event form metadata for instant UI rendering.
  Future<EventFormMetadata?> getCachedMetadata() async {
    try {
      final cachedJson = await SessionManager.getEventFormMetadata();

      if (cachedJson != null) {
        return EventFormMetadata.fromJson(cachedJson);
      }
    } catch (e) {
      debugPrint('[EVENT_API] Error reading cached event form metadata: $e');
    }

    return null;
  }

  /// Fetch dynamic event form metadata for the logged-in volunteer.
  /// GET /api/events/form-metadata with Bearer token.
  Future<EventFormMetadata> getEventFormMetadata({
    bool forceRefresh = false,
    String? sector,
  }) async {
    if (!forceRefresh) {
      final cached = await getCachedMetadata();

      if (cached != null) {
        final matchesSector =
            sector == null ||
            cached.primarySector.sectorCode.toLowerCase().contains(
              sector.toLowerCase(),
            ) ||
            cached.primarySector.sectorName.toLowerCase().contains(
              sector.toLowerCase(),
            );

        if (matchesSector) {
          _refreshMetadataInBackground();
          return cached;
        }
      }
    }

    try {
      final token = await SessionManager.getToken();
      final uri = (sector != null && sector.trim().isNotEmpty)
          ? Uri.parse('$endpointEventFormMetadata?sector=${Uri.encodeComponent(sector.trim())}')
          : Uri.parse(endpointEventFormMetadata);

      debugPrint(
        '[EVENT_API] GET $uri with Bearer token: '
        '${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
      );

      final response = await _client
          .get(uri, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 10));

      debugPrint(
        '[EVENT_API] /api/events/form-metadata status: '
        '${response.statusCode}, '
        'body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        await SessionManager.saveEventFormMetadata(decoded);

        return EventFormMetadata.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[EVENT_API] Network error fetching event form metadata: $e');
    }

    final cached = await getCachedMetadata();

    if (cached != null) {
      final matchesSector =
          sector == null ||
          cached.primarySector.sectorCode.toLowerCase().contains(
            sector.toLowerCase(),
          ) ||
          cached.primarySector.sectorName.toLowerCase().contains(
            sector.toLowerCase(),
          );

      if (matchesSector) {
        return cached;
      }
    }

    debugPrint(
      '[EVENT_API] Returning schema fallback metadata '
      'for volunteer sector ($sector).',
    );

    return EventFormMetadata.fallback(sector: sector);
  }

  /// Refresh metadata in the background without blocking the UI.
  void _refreshMetadataInBackground() async {
    try {
      final token = await SessionManager.getToken();

      final response = await _client
          .get(
            Uri.parse(endpointEventFormMetadata),
            headers: ApiConstants.defaultHeaders(token: token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        await SessionManager.saveEventFormMetadata(decoded);
      }
    } catch (_) {}
  }

  /// Fetch population subcategories for a given population type ID.
  /// GET /api/events/population-subcategories?population_type_id={id}
  Future<List<PopulationSubcategoryOption>> fetchPopulationSubcategories(
    int populationTypeId,
  ) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(
      ApiConstants.endpointPopulationSubcategoriesQuery(populationTypeId),
    );

    debugPrint(
      '[EVENT_API] GET $url with Bearer token: '
      '${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    final response = await _client
        .get(url, headers: ApiConstants.defaultHeaders(token: token))
        .timeout(const Duration(seconds: 10));

    debugPrint(
      '[EVENT_API] /api/events/population-subcategories status: '
      '${response.statusCode}, body length: ${response.body.length}',
    );

    if (response.statusCode == 200) {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final parsed = PopulationSubcategoriesResponse.fromJson(decoded);
      return parsed.data;
    } else {
      String errorMessage =
          'Failed to fetch subcategories (${response.statusCode})';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  /// Submit event report via POST /api/events (multipart/form-data).
  ///
  /// By default, throws real server errors and network errors directly so the
  /// caller/UI receives immediate feedback and can address validation or network
  /// issues. If [allowOfflineFallback] is explicitly set to true, network-level
  /// connection drops will enqueue the payload locally in [SyncRepository].
  Future<EventReportResult> submitEventReport(
    EventReportRequest request, {
    bool allowOfflineFallback = false,
  }) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointEvents);

    debugPrint(
      '[EVENT_API] POST $url (multipart/form-data) with Bearer token: '
      '${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    try {
      final multipartRequest = http.MultipartRequest('POST', url);

      // 1. Authorization headers.
      if (token != null && token.isNotEmpty) {
        multipartRequest.headers['Authorization'] = 'Bearer $token';
      }

      multipartRequest.headers['Accept'] = 'application/json';

      // 2. Event type fields.
      // Send both ID and string alias keys for backend compatibility.
      multipartRequest.fields['event_type_id'] = request.eventTypeId.toString();
      multipartRequest.fields['event_type'] = request.eventType;

      if (request.eventTypeOther != null &&
          request.eventTypeOther!.trim().isNotEmpty) {
        multipartRequest.fields['event_type_other'] = request.eventTypeOther!
            .trim();
      }

      // 3. Date and time.
      final dateFormatted =
          '${request.date.year.toString().padLeft(4, '0')}-'
          '${request.date.month.toString().padLeft(2, '0')}-'
          '${request.date.day.toString().padLeft(2, '0')}';

      multipartRequest.fields['date'] = dateFormatted;

      var timeFormatted = request.time.trim();

      if (timeFormatted.length == 5) {
        timeFormatted = '$timeFormatted:00';
      }

      multipartRequest.fields['time'] = timeFormatted;

      // 4. Location and village details.
      multipartRequest.fields['village_lgd_code'] = request.villageLgdCode
          .toString();
      multipartRequest.fields['village'] = request.village;

      if (request.gramPanchayat != null) {
        multipartRequest.fields['gram_panchayat'] = request.gramPanchayat!;
      }

      if (request.blockName != null) {
        multipartRequest.fields['block_name'] = request.blockName!;
      }

      multipartRequest.fields['is_out_of_area'] = request.isOutOfAreaVisit
          ? 'true'
          : 'false';

      multipartRequest.fields['is_out_of_area_visit'] = request.isOutOfAreaVisit
          ? 'true'
          : 'false';

      // 5. Visit details.
      multipartRequest.fields['purpose_of_visit'] = request.purposeOfVisit;
      multipartRequest.fields['location_type'] = request.locationType;
      multipartRequest.fields['total_visits'] = request.totalVisits.toString();

      // 6. Target population.
      multipartRequest.fields['population_type_id'] = request.populationTypeId
          .toString();
      multipartRequest.fields['target_population'] = request.targetPopulation;

      if (request.populationOther != null &&
          request.populationOther!.trim().isNotEmpty) {
        multipartRequest.fields['population_other'] = request.populationOther!
            .trim();
      }

      if (request.populationSubcategoryId != null) {
        multipartRequest.fields['population_subcategory_id'] =
            request.populationSubcategoryId.toString();
      }
      if (request.populationSubcategory != null &&
          request.populationSubcategory!.trim().isNotEmpty) {
        multipartRequest.fields['population_subcategory'] =
            request.populationSubcategory!.trim();
      }
      if (request.populationSubcategoryOther != null &&
          request.populationSubcategoryOther!.trim().isNotEmpty) {
        multipartRequest.fields['population_subcategory_other'] =
            request.populationSubcategoryOther!.trim();
      }

      // 7. Primary sector & sector code (send all aliases for backend compatibility).
      multipartRequest.fields['primary_sector'] = request.primarySector;
      multipartRequest.fields['sector'] = request.primarySector;
      multipartRequest.fields['sector_name'] = request.primarySector;

      final sectorCode = (request.primarySectorCode != null &&
              request.primarySectorCode!.trim().isNotEmpty)
          ? request.primarySectorCode!.trim()
          : EventReportItem.sectorToCode(request.primarySector);

      multipartRequest.fields['primary_sector_code'] = sectorCode;
      multipartRequest.fields['sector_code'] = sectorCode;

      // 8. Observations and actions.
      multipartRequest.fields['observations'] = request.observations.trim();
      multipartRequest.fields['action_taken'] = request.actionTaken.trim();

      final desc = request.description ?? request.mediaCaption;

      if (desc != null && desc.trim().isNotEmpty) {
        final cleanDesc = desc.trim();
        multipartRequest.fields['description'] = cleanDesc;
        multipartRequest.fields['media_caption'] = cleanDesc;
        multipartRequest.fields['caption'] = cleanDesc;
      }

      // 9. Boolean flags.
      multipartRequest.fields['referral_generated'] =
          request.isReferralGenerated ? 'true' : 'false';

      multipartRequest.fields['is_referral_generated'] =
          request.isReferralGenerated ? 'true' : 'false';

      multipartRequest.fields['alert_generated'] = request.isAlertGenerated
          ? 'true'
          : 'false';

      multipartRequest.fields['is_alert_generated'] = request.isAlertGenerated
          ? 'true'
          : 'false';

      multipartRequest.fields['follow_up_required'] = request.isFollowUpRequired
          ? 'true'
          : 'false';

      multipartRequest.fields['is_follow_up_required'] =
          request.isFollowUpRequired ? 'true' : 'false';

      // 10. Geolocation coordinates formatted to maximum 6 decimal places.
      if (request.latitude != null) {
        multipartRequest.fields['latitude'] =
            GeoLocationData.formatCoordinateString(request.latitude)!;
      }
      if (request.longitude != null) {
        multipartRequest.fields['longitude'] =
            GeoLocationData.formatCoordinateString(request.longitude)!;
      }
      if (request.accuracy != null) {
        multipartRequest.fields['gps_accuracy_m'] = request.accuracy.toString();
        multipartRequest.fields['accuracy'] = request.accuracy.toString();
      }

      if (request.gpsUnavailableReason != null &&
          request.gpsUnavailableReason!.trim().isNotEmpty) {
        multipartRequest.fields['gps_unavailable_reason'] = request
            .gpsUnavailableReason!
            .trim();
      }

      // 11. Device and volunteer details.
      if (request.deviceId.trim().isNotEmpty) {
        multipartRequest.fields['device_id'] = request.deviceId.trim();
      }

      multipartRequest.fields['volunteer_id'] = request.volunteerId;

      final clientRef =
          request.clientRef ??
          'EVT-CLI-${DateTime.now().millisecondsSinceEpoch}';

      multipartRequest.fields['client_ref'] = clientRef;

      // 12. Attach photo files.
      final photos = request.photos.isNotEmpty
          ? request.photos
          : request.mediaFiles;

      for (final filePath in photos) {
        final file = File(filePath);

        if (await file.exists()) {
          multipartRequest.files.add(
            await http.MultipartFile.fromPath('photos', file.path),
          );
        }
      }

      // 13. Attach video files.
      for (final filePath in request.videos) {
        final file = File(filePath);

        if (await file.exists()) {
          multipartRequest.files.add(
            await http.MultipartFile.fromPath('videos', file.path),
          );
        }
      }

      // 14. Attach document files.
      for (final filePath in request.documents) {
        final file = File(filePath);

        if (await file.exists()) {
          multipartRequest.files.add(
            await http.MultipartFile.fromPath('documents', file.path),
          );
        }
      }

      debugPrint(
        '[EVENT_API] Dispatching POST /api/events with '
        '${multipartRequest.fields.length} fields & '
        '${multipartRequest.files.length} files...',
      );

      ApiConstants.logRequest(
        module: 'Event Reporting',
        method: 'POST',
        url: url,
        body: multipartRequest.fields,
      );

      // 15. Send multipart request.
      final streamedResponse = await _client
          .send(multipartRequest)
          .timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        '[EVENT_API] POST /api/events response status: '
        '${response.statusCode}, body: ${response.body}',
      );

      // 16. Handle successful responses.
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        return EventReportResult.fromJson(data);
      }

      // 17. Parse server errors.
      String errorMsg = 'Server returned error status ${response.statusCode}';

      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes));

        if (errJson is Map) {
          if (errJson['detail'] != null) {
            final detail = errJson['detail'];

            if (detail is String) {
              errorMsg = detail;
            } else if (detail is List && detail.isNotEmpty) {
              final first = detail.first;

              final fieldLoc = first['loc'] is List
                  ? (first['loc'] as List).last
                  : 'Validation';

              errorMsg = '$fieldLoc: ${first['msg']}';
            }
          } else if (errJson['message'] != null) {
            errorMsg = errJson['message'].toString();
          }
        }
      } catch (_) {}

      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('[EVENT_API] Exception submitting event report: $e');

      // Offline synchronization fallback only when explicitly enabled AND on real network outage
      final isOffline =
          e is SocketException ||
          e is TimeoutException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('TimeoutException');

      if (allowOfflineFallback && isOffline) {
        final seq = DateTime.now().millisecondsSinceEpoch % 1000;

        final reportId = 'OFFLINE-EVT-26-${seq.toString().padLeft(4, '0')}';

        final alertId = request.isAlertGenerated
            ? 'ALERT-26-${(seq + 1).toString().padLeft(4, '0')}'
            : null;

        await _syncRepository.enqueueRecord(
          entityType: 'EVENT',
          payload: {
            'report_id': reportId,
            'alert_id': alertId,
            ...request.toJson(),
          },
        );

        return EventReportResult(
          reportId: reportId,
          status: 'queued_offline',
          alertId: alertId,
          message: request.isAlertGenerated
              ? 'Event report queued locally. Alert $alertId '
                    'will synchronize once connectivity is restored.'
              : 'Event report saved locally and queued '
                    'for automatic sync.',
        );
      }

      rethrow;
    }
  }

  /// Update an existing event report: PUT /api/events/{event_report_id}
  Future<EventReportResult> updateEventReport(
    int eventReportId,
    EventReportRequest request,
  ) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(ApiConstants.endpointEventDetail(eventReportId));

    debugPrint(
      '[EVENT_API] PUT $url (eventReportId: $eventReportId)',
    );

    try {
      final multipartRequest = http.MultipartRequest('PUT', url);

      if (token != null && token.isNotEmpty) {
        multipartRequest.headers['Authorization'] = 'Bearer $token';
      }
      multipartRequest.headers['Accept'] = 'application/json';

      // 2. Event type fields.
      multipartRequest.fields['event_type_id'] = request.eventTypeId.toString();
      multipartRequest.fields['event_type'] = request.eventType;

      if (request.eventTypeOther != null &&
          request.eventTypeOther!.trim().isNotEmpty) {
        multipartRequest.fields['event_type_other'] = request.eventTypeOther!.trim();
      }

      // 3. Date and time.
      final dateFormatted =
          '${request.date.year.toString().padLeft(4, '0')}-'
          '${request.date.month.toString().padLeft(2, '0')}-'
          '${request.date.day.toString().padLeft(2, '0')}';

      multipartRequest.fields['date'] = dateFormatted;

      var timeFormatted = request.time.trim();
      if (timeFormatted.length == 5) {
        timeFormatted = '$timeFormatted:00';
      }
      multipartRequest.fields['time'] = timeFormatted;

      // 4. Location and village details.
      multipartRequest.fields['village_lgd_code'] = request.villageLgdCode.toString();
      multipartRequest.fields['village'] = request.village;

      if (request.gramPanchayat != null) {
        multipartRequest.fields['gram_panchayat'] = request.gramPanchayat!;
      }
      if (request.blockName != null) {
        multipartRequest.fields['block_name'] = request.blockName!;
      }

      multipartRequest.fields['is_out_of_area_visit'] =
          request.isOutOfAreaVisit ? 'true' : 'false';

      // 5. Purpose & Location Type
      multipartRequest.fields['purpose_of_visit'] = request.purposeOfVisit;
      multipartRequest.fields['location_type'] = request.locationType;
      multipartRequest.fields['total_visits'] = request.totalVisits.toString();

      // 6. Population category details
      multipartRequest.fields['population_type_id'] =
          request.populationTypeId.toString();
      multipartRequest.fields['target_population'] = request.targetPopulation;
      multipartRequest.fields['population_type'] = request.targetPopulation;
      if (request.populationOther != null &&
          request.populationOther!.trim().isNotEmpty) {
        multipartRequest.fields['population_other'] =
            request.populationOther!.trim();
      }

      // 7. Population subcategory details
      if (request.populationSubcategoryId != null) {
        multipartRequest.fields['population_subcategory_id'] =
            request.populationSubcategoryId.toString();
      }
      if (request.populationSubcategory != null &&
          request.populationSubcategory!.trim().isNotEmpty) {
        multipartRequest.fields['population_subcategory'] =
            request.populationSubcategory!;
      }
      if (request.populationSubcategoryOther != null &&
          request.populationSubcategoryOther!.trim().isNotEmpty) {
        multipartRequest.fields['population_subcategory_other'] =
            request.populationSubcategoryOther!.trim();
      }

      // 8. Sector details
      multipartRequest.fields['primary_sector'] = request.primarySector;
      if (request.primarySectorCode != null &&
          request.primarySectorCode!.trim().isNotEmpty) {
        multipartRequest.fields['primary_sector_code'] =
            request.primarySectorCode!.trim();
      }

      // 9. Qualitative observations & actions taken
      multipartRequest.fields['observations'] = request.observations.trim();
      multipartRequest.fields['action_taken'] = request.actionTaken.trim();

      // 10. Operational flags
      multipartRequest.fields['is_referral_generated'] =
          request.isReferralGenerated ? 'true' : 'false';
      multipartRequest.fields['is_alert_generated'] =
          request.isAlertGenerated ? 'true' : 'false';
      multipartRequest.fields['is_follow_up_required'] =
          request.isFollowUpRequired ? 'true' : 'false';

      // 11. GPS Telemetry
      if (request.latitude != null) {
        multipartRequest.fields['latitude'] =
            GeoLocationData.formatCoordinateString(request.latitude)!;
      }
      if (request.longitude != null) {
        multipartRequest.fields['longitude'] =
            GeoLocationData.formatCoordinateString(request.longitude)!;
      }
      if (request.accuracy != null) {
        multipartRequest.fields['gps_accuracy_m'] = request.accuracy.toString();
        multipartRequest.fields['accuracy'] = request.accuracy.toString();
      }
      if (request.gpsUnavailableReason != null &&
          request.gpsUnavailableReason!.trim().isNotEmpty) {
        multipartRequest.fields['gps_unavailable_reason'] =
            request.gpsUnavailableReason!.trim();
      }

      // 12. Identification
      if (request.clientRef != null && request.clientRef!.trim().isNotEmpty) {
        multipartRequest.fields['client_ref'] = request.clientRef!.trim();
      }
      if (request.deviceId.trim().isNotEmpty) {
        multipartRequest.fields['device_id'] = request.deviceId.trim();
      }

      // 13. File attachments (only local non-http paths)
      for (final path in request.photos) {
        if (path.startsWith('http')) continue;
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split(Platform.pathSeparator).last;
          multipartRequest.files.add(
            await http.MultipartFile.fromPath('photos', path, filename: fileName),
          );
        }
      }

      for (final path in request.videos) {
        if (path.startsWith('http')) continue;
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split(Platform.pathSeparator).last;
          multipartRequest.files.add(
            await http.MultipartFile.fromPath('videos', path, filename: fileName),
          );
        }
      }

      for (final path in request.documents) {
        if (path.startsWith('http')) continue;
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split(Platform.pathSeparator).last;
          multipartRequest.files.add(
            await http.MultipartFile.fromPath('documents', path, filename: fileName),
          );
        }
      }

      final desc = request.description ?? request.mediaCaption;
      if (desc != null && desc.trim().isNotEmpty) {
        final cleanDesc = desc.trim();
        multipartRequest.fields['media_caption'] = cleanDesc;
        multipartRequest.fields['description'] = cleanDesc;
        multipartRequest.fields['caption'] = cleanDesc;
      }

      final existingPhotos = request.photos.where((p) => p.startsWith('http') || !File(p).existsSync()).toList();
      final existingVideos = request.videos.where((v) => v.startsWith('http') || !File(v).existsSync()).toList();
      final existingDocs = request.documents.where((d) => d.startsWith('http') || !File(d).existsSync()).toList();
      if (existingPhotos.isNotEmpty) {
        multipartRequest.fields['existing_photos'] = jsonEncode(existingPhotos);
      }
      if (existingVideos.isNotEmpty) {
        multipartRequest.fields['existing_videos'] = jsonEncode(existingVideos);
      }
      if (existingDocs.isNotEmpty) {
        multipartRequest.fields['existing_documents'] = jsonEncode(existingDocs);
      }

      if (request.removedAttachmentIds.isNotEmpty) {
        multipartRequest.fields['removed_attachment_ids'] = jsonEncode(request.removedAttachmentIds);
      }

      ApiConstants.logRequest(
        module: 'Event Reporting',
        method: 'PUT',
        url: url,
        body: multipartRequest.fields,
      );

      final streamedResponse = await _client
          .send(multipartRequest)
          .timeout(const Duration(seconds: 45));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        '[EVENT_API] Response ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        return EventReportResult.fromJson(decoded);
      }

      String errorMsg = 'Failed to update event report (${response.statusCode})';
      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes));
        if (errJson is Map) {
          if (errJson['detail'] != null) {
            final detail = errJson['detail'];
            if (detail is String) {
              errorMsg = detail;
            } else if (detail is List && detail.isNotEmpty) {
              final first = detail.first;
              final fieldLoc = first['loc'] is List
                  ? (first['loc'] as List).last
                  : 'Validation';
              errorMsg = '$fieldLoc: ${first['msg']}';
            }
          } else if (errJson['message'] != null) {
            errorMsg = errJson['message'].toString();
          }
        }
      } catch (_) {}

      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('[EVENT_API] Error updating event report $eventReportId: $e');
      rethrow;
    }
  }

  /// Fetch submitted event reports belonging to the signed-in volunteer:
  /// Uses GET /api/events/all (with ?volunteer_id=...) with Bearer token,
  /// and applies strict client-side ownership verification against the active volunteer.
  Future<List<EventReportItem>> fetchEventReports({
    String? volunteerId,
    int? numericVolunteerId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final token = await SessionManager.getToken();
    final session = await SessionManager.getUserSession();

    final effectiveVolunteerId =
        (volunteerId != null && volunteerId.trim().isNotEmpty)
            ? volunteerId.trim()
            : (session?.volunteerId ??
                await SessionManager.getVolunteerId() ??
                '');

    final effectiveNumericId =
        numericVolunteerId ??
        session?.numericVolunteerId ??
        await SessionManager.getNumericVolunteerId() ??
        VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerId);

    // Query ApiConstants.endpointEventsAll (/api/events/all)
    String urlStr = ApiConstants.endpointEventsAll;
    final queryParams = <String, String>{};
    if (effectiveNumericId != null && effectiveNumericId > 0) {
      queryParams['volunteer_id'] = effectiveNumericId.toString();
    }
    queryParams['page'] = page.toString();
    queryParams['page_size'] = pageSize.toString();

    final uri = Uri.parse(urlStr).replace(queryParameters: queryParams);

    debugPrint(
      '[EVENT_API] GET $uri with Bearer token: '
      '${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}',
    );

    List<EventReportItem> remoteEvents = [];

    try {
      final response = await _client
          .get(uri, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[EVENT_API] GET /api/events/all status: ${response.statusCode}, '
        'body length: ${response.body.length}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));

        List<dynamic> rawList = [];
        if (decoded is Map && decoded['data'] is List) {
          rawList = decoded['data'] as List;
        } else if (decoded is Map &&
            decoded['data'] is Map &&
            decoded['data']['items'] is List) {
          rawList = decoded['data']['items'] as List;
        } else if (decoded is List) {
          rawList = decoded;
        }

        remoteEvents = rawList
            .whereType<Map>()
            .map(
              (item) => EventReportItem.fromJson(
                Map<String, dynamic>.from(item),
                fallbackSector: session?.sector,
              ),
            )
            .where(
              (event) => VolunteerOwnershipFilter.isOwnedByVolunteer(
                itemOwnerId: event.volunteerId,
                itemNumericId: event.numericVolunteerId,
                activeVolunteerId: effectiveVolunteerId,
                activeNumericId: effectiveNumericId,
              ),
            )
            .toList();
      } else {
        debugPrint(
          '[EVENT_API] Server returned status ${response.statusCode} for /api/events/all',
        );
      }
    } catch (e) {
      debugPrint('[EVENT_API] Error fetching event reports from API: $e');
    }

    // Merge with any locally queued/offline-stored event reports scoped to this volunteer
    try {
      final localStored = await SessionManager.getSubmittedEvents(
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );
      if (localStored.isNotEmpty) {
        final existingIds = remoteEvents.map((e) => e.id).toSet();
        final existingNumericIds = remoteEvents
            .where((e) => e.numericId != null)
            .map((e) => e.numericId!)
            .toSet();
        for (final local in localStored) {
          if (local.id == 'EVT-26-0001') continue;
          if (!existingIds.contains(local.id) &&
              (local.numericId == null || !existingNumericIds.contains(local.numericId)) &&
              VolunteerOwnershipFilter.isOwnedByVolunteer(
                itemOwnerId: local.volunteerId,
                itemNumericId: local.numericVolunteerId,
                activeVolunteerId: effectiveVolunteerId,
                activeNumericId: effectiveNumericId,
              )) {
            remoteEvents.insert(0, local);
          }
        }
      }
    } catch (e) {
      debugPrint('[EVENT_API] Error merging local events: $e');
    }

    // Final fail-closed safety filter on returned list
    return remoteEvents
        .where(
          (event) => VolunteerOwnershipFilter.isOwnedByVolunteer(
            itemOwnerId: event.volunteerId,
            itemNumericId: event.numericVolunteerId,
            activeVolunteerId: effectiveVolunteerId,
            activeNumericId: effectiveNumericId,
          ),
        )
        .toList();
  }

  /// Fetch full details of a specific event report:
  /// GET /api/events/{id} with Bearer token
  Future<EventReportItem?> fetchEventDetail(int eventReportId) async {
    final token = await SessionManager.getToken();
    final session = await SessionManager.getUserSession();
    final url = Uri.parse(ApiConstants.endpointEventDetail(eventReportId));

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (decoded['data'] is Map) {
          return EventReportItem.fromJson(
            Map<String, dynamic>.from(decoded['data']),
            fallbackSector: session?.sector,
          );
        }
      }
    } catch (e) {
      debugPrint('[EVENT_API] Error fetching event detail ($eventReportId): $e');
    }
    return null;
  }
}

