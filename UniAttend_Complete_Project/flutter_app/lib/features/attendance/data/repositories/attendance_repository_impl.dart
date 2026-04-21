import '../../../../shared/models/models.dart';
import '../../../../shared/services/api_service.dart';
import '../../domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final ApiService _api;

  AttendanceRepositoryImpl(this._api);

  @override
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
  }) async {
    final response = await _api.post(
      '/attendance/checkin',
      data: {
        'session_id': sessionId,
        'student_id': studentId,
        'device_id': deviceId,
        'qr_payload': qrPayload,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final checkedAt =
        DateTime.tryParse((response['checked_at'] ?? '').toString()) ??
            DateTime.now();

    return AttendanceRecord(
      id: 'rec_${checkedAt.millisecondsSinceEpoch}',
      sessionId: sessionId,
      studentId: studentId,
      studentName: studentName,
      matricNumber: matricNumber,
      department: department,
      checkInTime: checkedAt,
      checkInLatitude: latitude,
      checkInLongitude: longitude,
      deviceId: deviceId,
      status: AttendanceStatus.partial,
    );
  }

  @override
  Future<AttendanceRecord> checkOut({
    required String sessionId,
    required String studentId,
    required String deviceId,
    required String qrPayload,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.post(
      '/attendance/checkout',
      data: {
        'session_id': sessionId,
        'student_id': studentId,
        'device_id': deviceId,
        'qr_payload': qrPayload,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final checkedAt =
        DateTime.tryParse((response['checked_at'] ?? '').toString()) ??
            DateTime.now();

    return AttendanceRecord(
      id: 'rec_${checkedAt.millisecondsSinceEpoch}',
      sessionId: sessionId,
      studentId: studentId,
      studentName: '',
      matricNumber: '',
      department: '',
      checkOutTime: checkedAt,
      checkOutLatitude: latitude,
      checkOutLongitude: longitude,
      deviceId: deviceId,
      status: AttendanceStatus.present,
    );
  }

  @override
  Future<List<AttendanceRecord>> getSessionAttendance(String sessionId) async {
    final response = await _api.get('/attendance/session/$sessionId');
    final list = (response['records'] as List<dynamic>? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => AttendanceRecord.fromMap(_toRecordMap(e)))
        .toList();
  }

  @override
  Future<AttendanceRecord?> getStudentRecord(
      String sessionId, String studentId) async {
    final records = await getSessionAttendance(sessionId);
    try {
      return records.firstWhere((r) => r.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toRecordMap(Map<String, dynamic> raw) {
    return {
      'id': raw['id'] ?? '',
      'sessionId': raw['session_id'] ?? raw['sessionId'] ?? '',
      'studentId': raw['student_id'] ?? raw['studentId'] ?? '',
      'studentName': raw['full_name'] ?? raw['studentName'] ?? '',
      'matricNumber': raw['matric_number'] ?? raw['matricNumber'] ?? '',
      'department': raw['department'] ?? '',
      'phoneNumber': raw['phone_number'] ?? raw['phoneNumber'] ?? '',
      'checkInTime': raw['check_in_time'] ?? raw['checkInTime'],
      'checkOutTime': raw['check_out_time'] ?? raw['checkOutTime'],
      'checkInLatitude': raw['check_in_latitude'] ?? raw['checkInLatitude'],
      'checkInLongitude': raw['check_in_longitude'] ?? raw['checkInLongitude'],
      'checkOutLatitude': raw['check_out_latitude'] ?? raw['checkOutLatitude'],
      'checkOutLongitude':
          raw['check_out_longitude'] ?? raw['checkOutLongitude'],
      'deviceId': raw['device_id'] ?? raw['deviceId'] ?? '',
      'status': raw['status'] ?? 'absent',
      'manualAdded': raw['manual_added'] ?? raw['manualAdded'] ?? false,
      'manualAddedBy': raw['manual_added_by'] ?? raw['manualAddedBy'],
      'manualAddedByName':
          raw['manual_added_by_name'] ?? raw['manualAddedByName'],
      'manualAddedAt': raw['manual_added_at'] ?? raw['manualAddedAt'],
      'manualReason': raw['manual_reason'] ?? raw['manualReason'],
    };
  }
}
