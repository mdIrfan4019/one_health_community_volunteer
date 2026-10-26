import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/theme/app_colors.dart';

/// Centralized service handling real GPS location capture, permission management,
/// and dialog prompts across all reporting and media modules.
class LocationService {
  static LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();
  LocationService.base();

  /// Allows test suites to inject mock or simulated location services.
  static void setMockInstance(LocationService? mock) {
    _instance = mock ?? LocationService._internal();
  }

  static const String _keyStartupPrompted = 'location_permission_startup_prompted';

  GeoLocationData? _lastKnownLocation;
  GeoLocationData? get lastKnownLocation => _lastKnownLocation;

  bool get _isTestEnv =>
      WidgetsBinding.instance is! WidgetsFlutterBinding;

  /// Check whether hardware GPS / location services are switched on.
  Future<bool> isLocationServiceEnabled() async {
    if (_isTestEnv) {
      return false;
    }
    try {
      return await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  /// Check current app permission status for location.
  Future<LocationPermission> checkPermission() async {
    if (_isTestEnv) {
      return LocationPermission.denied;
    }
    try {
      return await Geolocator.checkPermission().timeout(
        const Duration(seconds: 3),
        onTimeout: () => LocationPermission.denied,
      );
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  /// Request runtime location permission from the OS.
  Future<LocationPermission> requestPermission() async {
    if (_isTestEnv) {
      return LocationPermission.denied;
    }
    try {
      return await Geolocator.requestPermission().timeout(
        const Duration(seconds: 5),
        onTimeout: () => LocationPermission.denied,
      );
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  /// Open device app settings.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Open device location / GPS toggle settings.
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Prompt for location permission at app startup only once when needed.
  Future<bool> requestStartupPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyPrompted = prefs.getBool(_keyStartupPrompted) ?? false;

      final currentPerm = await checkPermission();
      if (currentPerm == LocationPermission.always ||
          currentPerm == LocationPermission.whileInUse) {
        return true;
      }

      // If not yet determined or never prompted at startup
      if (!alreadyPrompted && currentPerm == LocationPermission.denied) {
        await prefs.setBool(_keyStartupPrompted, true);
        final requested = await requestPermission();
        if (requested == LocationPermission.always ||
            requested == LocationPermission.whileInUse) {
          // Warm up fresh coordinates in background
          unawaited(getCurrentLocation(requestIfNeeded: false));
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[LOCATION] Startup permission error: $e');
      return false;
    }
  }

  /// Fetch actual real GPS coordinates from the device.
  /// Never returns fake, simulated, or hardcoded coordinates.
  Future<GeoLocationData> getCurrentLocation({
    bool requestIfNeeded = true,
    Duration timeout = const Duration(seconds: 12),
    bool forceFresh = true,
  }) async {
    try {
      final effectiveTimeout = _isTestEnv ? const Duration(milliseconds: 100) : timeout;

      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        debugPrint('[LOCATION] Device location services are disabled.');
        final data = GeoLocationData.serviceDisabled(
          message: 'Location service is disabled. Please turn on GPS.',
        );
        _lastKnownLocation = data;
        return data;
      }

      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        if (requestIfNeeded) {
          permission = await requestPermission();
        }
        if (permission == LocationPermission.denied) {
          final data = GeoLocationData.permissionDenied(
            message: 'Location permission was denied. Geo-tagging is unavailable.',
          );
          _lastKnownLocation = data;
          return data;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final data = GeoLocationData.permissionPermanentlyDenied(
          message:
              'Location permission is permanently denied. Please enable it in Settings.',
        );
        _lastKnownLocation = data;
        return data;
      }

      // Permission is granted (whileInUse or always)
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: effectiveTimeout,
          ),
        ).timeout(
          effectiveTimeout,
          onTimeout: () => throw TimeoutException('GPS position acquisition timed out.'),
        );

        final result = GeoLocationData.success(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyM: position.accuracy.round(),
          timestamp: position.timestamp,
        );
        _lastKnownLocation = result;
        return result;
      } on TimeoutException {
        debugPrint('[LOCATION] GPS position acquisition timed out after ${timeout.inSeconds}s.');
        // Attempt fast fallback to last known fix if available
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            final result = GeoLocationData.success(
              latitude: last.latitude,
              longitude: last.longitude,
              accuracyM: last.accuracy.round(),
              timestamp: last.timestamp,
            );
            _lastKnownLocation = result;
            return result;
          }
        } catch (_) {}
        final data = GeoLocationData.timeout(
          message: 'Timed out waiting for GPS satellite fix. Please try again.',
        );
        _lastKnownLocation = data;
        return data;
      }
    } catch (e) {
      debugPrint('[LOCATION] Unexpected error while fetching position: $e');
      final data = GeoLocationData.error('Unable to acquire location: $e');
      _lastKnownLocation = data;
      return data;
    }
  }

  /// Displays an informative dialog explaining why location is required
  /// and provides actions to Retry or Open Settings.
  Future<void> showLocationResolutionDialog(
    BuildContext context, {
    required LocationFetchStatus status,
    VoidCallback? onRetry,
  }) async {
    String title = 'Location Required';
    String message =
        'SETU requires your device location to geo-tag reports, sample collections, awareness activities, and referrals with authentic GPS coordinates.';
    String actionLabel = 'Retry';
    VoidCallback onAction = () {
      Navigator.of(context, rootNavigator: true).pop();
      onRetry?.call();
    };

    if (status == LocationFetchStatus.serviceDisabled) {
      title = 'GPS Is Turned Off';
      message =
          'Location services are disabled on your device. Please turn on GPS location in device settings to capture and verify field coordinates.';
      actionLabel = 'Open Location Settings';
      onAction = () async {
        Navigator.of(context, rootNavigator: true).pop();
        await openLocationSettings();
      };
    } else if (status == LocationFetchStatus.permissionPermanentlyDenied) {
      title = 'Permission Permanently Denied';
      message =
          'Location permission is permanently denied for SETU. Please open app settings and grant location access to record authentic coordinates.';
      actionLabel = 'Open App Settings';
      onAction = () async {
        Navigator.of(context, rootNavigator: true).pop();
        await openAppSettings();
      };
    } else if (status == LocationFetchStatus.timeout) {
      title = 'GPS Satellite Timeout';
      message =
          'Device GPS timed out while acquiring satellite lock. Ensure you are outdoors or near a window and retry.';
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.location_off_rounded, color: AppColors.error, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }
}
