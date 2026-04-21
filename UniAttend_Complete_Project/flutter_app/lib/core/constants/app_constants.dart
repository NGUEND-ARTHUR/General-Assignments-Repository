class AppConstants {
  // Backend API base URL.
  // For Android emulator use 10.0.2.2, for physical device use your PC LAN IP via --dart-define.
  static const String apiBaseUrl = String.fromEnvironment(
    'UNIATTEND_API_BASE_URL',
    defaultValue: 'https://uniattend-backend.yourdomain.com',
  );

  // Geofencing
  static const double geofenceRadiusMeters = 50.0;

  // QR Code rotation interval in seconds
  static const int qrRotationSeconds = 30;

  // Attendance sessions per course per class
  static const int sessionsPerClass = 2;

  // Collection names (Firestore)
  static const String usersCollection = 'users';
  static const String coursesCollection = 'courses';
  static const String attendanceCollection = 'attendance';
  static const String sessionsCollection = 'sessions';
  static const String enrollmentsCollection = 'enrollments';

  // Roles
  static const String roleStudent = 'student';
  static const String roleLecturer = 'lecturer';
  static const String roleCourseRep = 'course_rep';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  static const List<String> roleValues = [
    roleStudent,
    roleCourseRep,
    roleLecturer,
    roleAdmin,
    roleSuperAdmin,
  ];

  // Session types
  static const String sessionNormal = 'Normal Class';
  static const String sessionCatchUp = 'Catch-Up';

  // Departments
  static const List<String> departments = [
    'SEN',
    'CSC',
    'ICT',
    'TEL',
    'CS',
    'EEE',
    'MEE',
    'CEE'
  ];

  // University info
  static const String universityName =
      'University of Technology – ICT Cameroon';
  static const String appVersion = '1.0.0';
}
