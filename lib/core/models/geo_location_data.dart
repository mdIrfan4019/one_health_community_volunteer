enum LocationFetchStatus {
  success,
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  timeout,
  error,
}

/// Immutable model representing device GPS coordinates, accuracy, and status.
class GeoLocationData {
  final double? latitude;
  final double? longitude;
  final int? accuracyM;
  final DateTime? timestamp;
  final LocationFetchStatus status;
  final String? errorMessage;

  const GeoLocationData({
    this.latitude,
    this.longitude,
    this.accuracyM,
    this.timestamp,
    required this.status,
    this.errorMessage,
  });

  /// True only when real, non-zero coordinates are available.
  bool get isAvailable =>
      status == LocationFetchStatus.success &&
      latitude != null &&
      longitude != null &&
      (latitude != 0.0 || longitude != 0.0);

  /// Human-readable coordinates or graceful failure message.
  String get displayText {
    if (isAvailable) {
      final latStr = latitude!.toStringAsFixed(6);
      final lngStr = longitude!.toStringAsFixed(6);
      final accStr = accuracyM != null && accuracyM! > 0 ? ' · ±$accuracyM m' : '';
      return '$latStr, $lngStr$accStr';
    }
    switch (status) {
      case LocationFetchStatus.serviceDisabled:
        return 'GPS / Location Service Disabled';
      case LocationFetchStatus.permissionDenied:
        return 'Location Permission Denied';
      case LocationFetchStatus.permissionPermanentlyDenied:
        return 'Location Permission Blocked (Open Settings)';
      case LocationFetchStatus.timeout:
        return 'GPS Signal Timeout';
      case LocationFetchStatus.error:
        return errorMessage?.isNotEmpty == true ? errorMessage! : 'Location Unavailable';
      case LocationFetchStatus.success:
        return 'Location Unavailable';
    }
  }

  /// Formats coordinate to a maximum of 6 decimal places as double.
  /// Example: 28.609471238 -> 28.609471, 77.367523891 -> 77.367524
  static double? formatCoordinate(double? coordinate) {
    if (coordinate == null) return null;
    return double.parse(coordinate.toStringAsFixed(6));
  }

  /// Formats coordinate to a maximum of 6 decimal places as String.
  /// Example: 28.609471238 -> "28.609471", 77.367523891 -> "77.367524"
  static String? formatCoordinateString(double? coordinate) {
    if (coordinate == null) return null;
    return coordinate.toStringAsFixed(6);
  }

  factory GeoLocationData.success({
    required double latitude,
    required double longitude,
    int? accuracyM,
    DateTime? timestamp,
  }) {
    return GeoLocationData(
      latitude: formatCoordinate(latitude),
      longitude: formatCoordinate(longitude),
      accuracyM: accuracyM,
      timestamp: timestamp ?? DateTime.now(),
      status: LocationFetchStatus.success,
    );
  }

  factory GeoLocationData.serviceDisabled({String? message}) => GeoLocationData(
        status: LocationFetchStatus.serviceDisabled,
        errorMessage: message ?? 'Location services are disabled on this device.',
      );

  factory GeoLocationData.permissionDenied({String? message}) => GeoLocationData(
        status: LocationFetchStatus.permissionDenied,
        errorMessage: message ?? 'Location permission was denied.',
      );

  factory GeoLocationData.permissionPermanentlyDenied({String? message}) =>
      GeoLocationData(
        status: LocationFetchStatus.permissionPermanentlyDenied,
        errorMessage: message ??
            'Location permission is permanently denied. Please enable it in Settings.',
      );

  factory GeoLocationData.timeout({String? message}) => GeoLocationData(
        status: LocationFetchStatus.timeout,
        errorMessage: message ?? 'Timed out waiting for GPS satellite fix.',
      );

  factory GeoLocationData.error(String message) => GeoLocationData(
        status: LocationFetchStatus.error,
        errorMessage: message,
      );

  @override
  String toString() =>
      'GeoLocationData(status: $status, lat: $latitude, lng: $longitude, acc: $accuracyM, err: $errorMessage)';
}
