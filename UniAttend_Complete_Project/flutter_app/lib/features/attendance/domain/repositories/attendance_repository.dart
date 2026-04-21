// domain/repositories/attendance_repository.dart
import '../../../../shared/models/models.dart';

abstract class AttendanceRepository {
  Future<AttendanceRecord> checkIn({
    required String sessionId,
    required String studentId,
    required String studentName,
    required String matricNumber,
    required String department,
    required String deviceId,
    required String qrPayload,
    required double latitude,
    required double longitude,
  });

  Future<AttendanceRecord> checkOut({
    required String sessionId,
    required String studentId,
    required String deviceId,
    required String qrPayload,
    required double latitude,
    required double longitude,
  });

  Future<List<AttendanceRecord>> getSessionAttendance(String sessionId);
  Future<AttendanceRecord?> getStudentRecord(
      String sessionId, String studentId);
}
