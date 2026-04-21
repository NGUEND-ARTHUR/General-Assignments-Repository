import '../../../../shared/models/models.dart';
import '../../../../shared/services/api_service.dart';
import '../../domain/repositories/course_repository.dart';

class CourseRepositoryImpl implements CourseRepository {
  final ApiService _api;

  CourseRepositoryImpl(this._api);

  @override
  Future<List<CourseModel>> getCoursesForStudent(String studentId) async {
    final response = await _api.get('/me/courses');
    final list = (response['courses'] as List<dynamic>? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => CourseModel.fromMap(_toCourseMap(e)))
        .toList();
  }

  @override
  Future<List<CourseModel>> getCoursesForLecturer(String lecturerId) async {
    final all = await getCoursesForStudent(lecturerId);
    return all.where((c) => c.lecturerId == lecturerId).toList();
  }

  @override
  Future<List<CourseModel>> getPublicCourseCatalog() async {
    // Try several known catalog endpoints to remain compatible with
    // different backend revisions.
    final candidatePaths = <String>[
      '/courses/catalog',
      '/courses/available',
      '/course-catalog',
      '/courses',
    ];

    Exception? lastError;
    for (final path in candidatePaths) {
      try {
        final response = await _api.get(path, authorized: false);
        final list = (response['courses'] as List<dynamic>? ?? const []);
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => CourseModel.fromMap(_toCourseMap(e)))
            .toList();
      } catch (e) {
        lastError = Exception(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    // One final authorized retry for environments that unexpectedly enforce auth.
    for (final path in candidatePaths) {
      try {
        final response = await _api.get(path);
        final list = (response['courses'] as List<dynamic>? ?? const []);
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => CourseModel.fromMap(_toCourseMap(e)))
            .toList();
      } catch (e) {
        lastError = Exception(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    throw lastError ?? Exception('Course catalog failed to load');
  }

  @override
  Future<CourseModel> enrollInCourse(String courseId) async {
    final response = await _api.post('/me/courses/$courseId');
    final raw = response['course'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid enroll response');
    }
    return CourseModel.fromMap(_toCourseMap(raw));
  }

  @override
  Future<void> unenrollFromCourse(String courseId) async {
    await _api.delete('/me/courses/$courseId');
  }

  @override
  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    final response = await _api.get('/analytics/dashboard');
    return response;
  }

  @override
  Future<List<AttendanceSession>> getSessionsForCourse(String courseId) async {
    final response = await _api.get('/sessions/course/$courseId');
    final list = (response['sessions'] as List<dynamic>? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => AttendanceSession.fromMap(_toSessionMap(e)))
        .toList();
  }

  @override
  Future<AttendanceSession?> getActiveSession(String courseId) async {
    final response = await _api.get('/sessions/active/$courseId');
    final raw = response['session'];
    if (raw is! Map<String, dynamic>) return null;
    return AttendanceSession.fromMap(_toSessionMap(raw));
  }

  @override
  Future<AttendanceSession> createSession(AttendanceSession session) async {
    final response = await _api.post(
      '/sessions',
      data: {
        'course_id': session.courseId,
        'class_type':
            session.classType == ClassType.catchUp ? 'catch_up' : 'normal',
        'scheduled_date': session.scheduledDate.toIso8601String(),
        'classroom_latitude': session.classroomLatitude,
        'classroom_longitude': session.classroomLongitude,
      },
    );
    final raw = response['session'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid session create response');
    }
    return AttendanceSession.fromMap(_toSessionMap(raw));
  }

  @override
  Future<AttendanceSession> updateSession(AttendanceSession session) async {
    final response = await _api.put(
      '/sessions/${session.id}',
      data: {
        'course_id': session.courseId,
        'class_type':
            session.classType == ClassType.catchUp ? 'catch_up' : 'normal',
        'scheduled_date': session.scheduledDate.toIso8601String(),
        'classroom_latitude': session.classroomLatitude,
        'classroom_longitude': session.classroomLongitude,
      },
    );
    final raw = response['session'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid session update response');
    }
    return AttendanceSession.fromMap(_toSessionMap(raw));
  }

  @override
  Future<AttendanceSession> openCheckOut(String sessionId) async {
    final response =
        await _api.post('/sessions/$sessionId/open-checkout', data: {});
    final raw = response['session'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid open check-out response');
    }
    return AttendanceSession.fromMap(_toSessionMap(raw));
  }

  @override
  Future<AttendanceSession> closeSession(String sessionId) async {
    final response = await _api.post('/sessions/$sessionId/close', data: {});
    final raw = response['session'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid close session response');
    }
    return AttendanceSession.fromMap(_toSessionMap(raw));
  }

  Map<String, dynamic> _toCourseMap(Map<String, dynamic> raw) {
    final enrolledCount =
        ((raw['enrolled_count'] ?? raw['enrolledCount'] ?? 0) as num).toInt();
    return {
      'id': raw['id'],
      'courseCode': raw['course_code'] ?? raw['courseCode'] ?? '',
      'courseName': raw['course_name'] ?? raw['courseName'] ?? '',
      'lecturerId': raw['lecturer_id'] ?? raw['lecturerId'] ?? '',
      'lecturerName': raw['lecturer_name'] ?? raw['lecturerName'] ?? '',
      'courseRepId': raw['course_rep_id'] ?? raw['courseRepId'] ?? '',
      'canManage': raw['can_manage'] == true || raw['canManage'] == true,
      'enrolledCount': enrolledCount,
      'semester': raw['semester'] ?? '',
      'academicYear':
          raw['academic_year'] ?? raw['academicYear'] ?? DateTime.now().year,
    };
  }

  Map<String, dynamic> _toSessionMap(Map<String, dynamic> raw) {
    final classType =
        (raw['class_type'] ?? raw['classType'] ?? 'normal').toString();
    return {
      'id': raw['id'],
      'courseId': raw['course_id'] ?? raw['courseId'] ?? '',
      'courseCode': raw['course_code'] ?? raw['courseCode'] ?? '',
      'courseName': raw['course_name'] ?? raw['courseName'] ?? '',
      'lecturerId': raw['lecturer_id'] ?? raw['lecturerId'] ?? '',
      'courseRepId': raw['course_rep_id'] ?? raw['courseRepId'] ?? '',
      'classType': classType == 'catch_up' ? 'catchUp' : classType,
      'scheduledDate': raw['scheduled_date'] ??
          raw['scheduledDate'] ??
          DateTime.now().toIso8601String(),
      'checkInOpenedAt': raw['check_in_opened_at'] ?? raw['checkInOpenedAt'],
      'checkInClosedAt': raw['check_in_closed_at'] ?? raw['checkInClosedAt'],
      'checkOutOpenedAt': raw['check_out_opened_at'] ?? raw['checkOutOpenedAt'],
      'checkOutClosedAt': raw['check_out_closed_at'] ?? raw['checkOutClosedAt'],
      'status': _normalizeStatus(raw['status']?.toString() ?? 'pending'),
      'classroomLatitude':
          raw['classroom_latitude'] ?? raw['classroomLatitude'] ?? 0.0,
      'classroomLongitude':
          raw['classroom_longitude'] ?? raw['classroomLongitude'] ?? 0.0,
    };
  }

  String _normalizeStatus(String status) {
    switch (status) {
      case 'open_for_check_in':
        return 'openForCheckIn';
      case 'open_for_check_out':
        return 'openForCheckOut';
      default:
        return status;
    }
  }
}
