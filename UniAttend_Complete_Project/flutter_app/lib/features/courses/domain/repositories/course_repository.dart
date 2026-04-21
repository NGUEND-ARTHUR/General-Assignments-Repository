// domain/repositories/course_repository.dart
import '../../../../shared/models/models.dart';

abstract class CourseRepository {
  Future<List<CourseModel>> getCoursesForStudent(String studentId);
  Future<List<CourseModel>> getCoursesForLecturer(String lecturerId);
  Future<List<CourseModel>> getPublicCourseCatalog();
  Future<CourseModel> enrollInCourse(String courseId);
  Future<void> unenrollFromCourse(String courseId);
  Future<Map<String, dynamic>> getDashboardAnalytics();
  Future<List<AttendanceSession>> getSessionsForCourse(String courseId);
  Future<AttendanceSession?> getActiveSession(String courseId);
  Future<AttendanceSession> createSession(AttendanceSession session);
  Future<AttendanceSession> updateSession(AttendanceSession session);
  Future<AttendanceSession> openCheckOut(String sessionId);
  Future<AttendanceSession> closeSession(String sessionId);
}
