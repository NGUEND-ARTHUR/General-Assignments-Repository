import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_constants.dart';

class LocationService {
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the user is within [AppConstants.geofenceRadiusMeters]
  /// of the classroom location.
  Future<bool> isWithinClassroom({
    required double classroomLat,
    required double classroomLng,
  }) async {
    final position = await getCurrentPosition();
    if (position == null) return false;

    final distanceMeters = _haversineDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: classroomLat,
      lon2: classroomLng,
    );

    return distanceMeters <= AppConstants.geofenceRadiusMeters;
  }

  double _haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const R = 6371000.0; // Earth radius in metres
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;
}
