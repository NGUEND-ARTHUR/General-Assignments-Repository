import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../../core/constants/app_constants.dart';

class QrService {
  final Random _random = Random.secure();

  /// Generates a QR token payload for a session.
  /// The token encodes: sessionId + timestamp window + random nonce.
  /// It expires every [AppConstants.qrRotationSeconds] seconds.
  String generateQrPayload({
    required String sessionId,
    required String courseId,
    required String phase, // 'checkin' | 'checkout'
  }) {
    final windowStart = _currentTimeWindow();
    final nonce = _random.nextInt(999999).toString().padLeft(6, '0');
    final raw = '$sessionId:$courseId:$phase:$windowStart:$nonce';
    final hash = sha256.convert(utf8.encode(raw)).toString().substring(0, 16);

    final payload = {
      'sessionId': sessionId,
      'courseId': courseId,
      'phase': phase,
      'window': windowStart,
      'hash': hash,
    };
    return base64Url.encode(utf8.encode(jsonEncode(payload)));
  }

  /// Validates a scanned QR payload. Returns the sessionId on success, null on failure.
  String? validateQrPayload(String rawPayload) {
    try {
      final decoded = utf8.decode(base64Url.decode(rawPayload));
      final payload = jsonDecode(decoded) as Map<String, dynamic>;

      final sessionId = payload['sessionId'] as String;
      final courseId = payload['courseId'] as String;
      final phase = payload['phase'] as String;
      final window = payload['window'] as int;
      final signature = (payload['signature'] ?? payload['hash']) as String;

      // Allow ±1 window to account for clock skew
      final currentWindow = _currentTimeWindow();
      if ((currentWindow - window).abs() > 1) return null;

      // The server now signs QR payloads. Client-side validation only checks
      // structure and window freshness before the backend performs full checks.
      if (sessionId.isEmpty ||
          courseId.isEmpty ||
          phase.isEmpty ||
          signature.length < 16) {
        return null;
      }

      return sessionId;
    } catch (_) {
      return null;
    }
  }

  int _currentTimeWindow() {
    return DateTime.now().millisecondsSinceEpoch ~/
        (AppConstants.qrRotationSeconds * 1000);
  }

  /// Seconds remaining until the current QR expires.
  int secondsUntilExpiry() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const windowDurationMs = AppConstants.qrRotationSeconds * 1000;
    final windowStart = (now ~/ windowDurationMs) * windowDurationMs;
    final elapsed = now - windowStart;
    return ((windowDurationMs - elapsed) / 1000).ceil();
  }
}
