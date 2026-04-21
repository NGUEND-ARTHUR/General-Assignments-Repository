import 'package:equatable/equatable.dart';

// ─── User ────────────────────────────────────────────────────────────────────
class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String matricNumber;
  final String department;
  final String phoneNumber;
  final String role; // student | lecturer | course_rep | admin
  final String? deviceId;
  final DateTime createdAt;
  final bool isActive;
  final String? blockedAt;
  final String? blockedReason;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.matricNumber,
    required this.department,
    required this.phoneNumber,
    required this.role,
    this.deviceId,
    required this.createdAt,
    this.isActive = true,
    this.blockedAt,
    this.blockedReason,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] ?? '',
        fullName: map['fullName'] ?? map['full_name'] ?? '',
        email: map['email'] ?? '',
        matricNumber: map['matricNumber'] ?? map['matric_number'] ?? '',
        department: map['department'] ?? '',
        phoneNumber: map['phoneNumber'] ?? map['phone_number'] ?? '',
        role: map['role'] ?? 'student',
        deviceId: map['deviceId'],
        createdAt: DateTime.parse((map['createdAt'] ??
                map['created_at'] ??
                DateTime.now().toIso8601String())
            .toString()),
        isActive: map['isActive'] == true ||
            map['is_active'] == 1 ||
            map['is_active'] == true,
        blockedAt:
            map['blockedAt']?.toString() ?? map['blocked_at']?.toString(),
        blockedReason: map['blockedReason']?.toString() ??
            map['blocked_reason']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'matricNumber': matricNumber,
        'department': department,
        'phoneNumber': phoneNumber,
        'role': role,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
        'blockedAt': blockedAt,
        'blockedReason': blockedReason,
      };

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        matricNumber,
        department,
        phoneNumber,
        role,
        deviceId,
        isActive,
        blockedAt,
        blockedReason,
      ];
}

// ─── Course ──────────────────────────────────────────────────────────────────
class CourseModel extends Equatable {
  final String id;
  final String courseCode;
  final String courseName;
  final String lecturerId;
  final String lecturerName;
  final String courseRepId;
  final bool canManage;
  final int enrolledCount;
  final String semester;
  final int academicYear;

  const CourseModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.lecturerId,
    required this.lecturerName,
    required this.courseRepId,
    required this.canManage,
    required this.enrolledCount,
    required this.semester,
    required this.academicYear,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) => CourseModel(
        id: map['id'] ?? '',
        courseCode: map['courseCode'] ?? '',
        courseName: map['courseName'] ?? '',
        lecturerId: map['lecturerId'] ?? '',
        lecturerName: map['lecturerName'] ?? '',
        courseRepId: map['courseRepId'] ?? '',
        canManage: map['canManage'] == true,
        enrolledCount:
            ((map['enrolledCount'] ?? map['enrolled_count'] ?? 0) as num)
                .toInt(),
        semester: map['semester'] ?? '',
        academicYear: map['academicYear'] ?? DateTime.now().year,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'courseCode': courseCode,
        'courseName': courseName,
        'lecturerId': lecturerId,
        'lecturerName': lecturerName,
        'courseRepId': courseRepId,
        'canManage': canManage,
        'enrolledCount': enrolledCount,
        'semester': semester,
        'academicYear': academicYear,
      };

  @override
  List<Object?> get props =>
      [id, courseCode, courseName, lecturerId, canManage, enrolledCount];
}

// ─── Attendance Session ──────────────────────────────────────────────────────
enum SessionStatus { pending, openForCheckIn, openForCheckOut, closed }

enum ClassType { normal, catchUp }

class AttendanceSession extends Equatable {
  final String id;
  final String courseId;
  final String courseCode;
  final String courseName;
  final String lecturerId;
  final String courseRepId;
  final ClassType classType;
  final DateTime scheduledDate;
  final DateTime? checkInOpenedAt;
  final DateTime? checkInClosedAt;
  final DateTime? checkOutOpenedAt;
  final DateTime? checkOutClosedAt;
  final SessionStatus status;
  final String? qrToken; // rotating token
  final DateTime? qrTokenExpiry;
  final double classroomLatitude;
  final double classroomLongitude;

  const AttendanceSession({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.lecturerId,
    required this.courseRepId,
    required this.classType,
    required this.scheduledDate,
    this.checkInOpenedAt,
    this.checkInClosedAt,
    this.checkOutOpenedAt,
    this.checkOutClosedAt,
    required this.status,
    this.qrToken,
    this.qrTokenExpiry,
    required this.classroomLatitude,
    required this.classroomLongitude,
  });

  bool get isQrValid =>
      qrToken != null &&
      qrTokenExpiry != null &&
      DateTime.now().isBefore(qrTokenExpiry!);

  factory AttendanceSession.fromMap(Map<String, dynamic> map) =>
      AttendanceSession(
        id: map['id'] ?? '',
        courseId: map['courseId'] ?? '',
        courseCode: map['courseCode'] ?? '',
        courseName: map['courseName'] ?? '',
        lecturerId: map['lecturerId'] ?? '',
        courseRepId: map['courseRepId'] ?? '',
        classType: map['classType'] == 'catchUp'
            ? ClassType.catchUp
            : ClassType.normal,
        scheduledDate: DateTime.parse(map['scheduledDate']),
        checkInOpenedAt: map['checkInOpenedAt'] != null
            ? DateTime.parse(map['checkInOpenedAt'])
            : null,
        checkInClosedAt: map['checkInClosedAt'] != null
            ? DateTime.parse(map['checkInClosedAt'])
            : null,
        checkOutOpenedAt: map['checkOutOpenedAt'] != null
            ? DateTime.parse(map['checkOutOpenedAt'])
            : null,
        checkOutClosedAt: map['checkOutClosedAt'] != null
            ? DateTime.parse(map['checkOutClosedAt'])
            : null,
        status: SessionStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => SessionStatus.pending,
        ),
        qrToken: map['qrToken'],
        qrTokenExpiry: map['qrTokenExpiry'] != null
            ? DateTime.parse(map['qrTokenExpiry'])
            : null,
        classroomLatitude: (map['classroomLatitude'] ?? 0.0).toDouble(),
        classroomLongitude: (map['classroomLongitude'] ?? 0.0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'courseId': courseId,
        'courseCode': courseCode,
        'courseName': courseName,
        'lecturerId': lecturerId,
        'courseRepId': courseRepId,
        'classType': classType.name,
        'scheduledDate': scheduledDate.toIso8601String(),
        'checkInOpenedAt': checkInOpenedAt?.toIso8601String(),
        'checkInClosedAt': checkInClosedAt?.toIso8601String(),
        'checkOutOpenedAt': checkOutOpenedAt?.toIso8601String(),
        'checkOutClosedAt': checkOutClosedAt?.toIso8601String(),
        'status': status.name,
        'qrToken': qrToken,
        'qrTokenExpiry': qrTokenExpiry?.toIso8601String(),
        'classroomLatitude': classroomLatitude,
        'classroomLongitude': classroomLongitude,
      };

  @override
  List<Object?> get props => [id, courseId, status, qrToken];
}

// ─── Attendance Record ───────────────────────────────────────────────────────
enum AttendanceStatus {
  present,
  absent,
  partial
} // partial = checked in but not out

class AttendanceRecord extends Equatable {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String matricNumber;
  final String department;
  final String phoneNumber;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String deviceId;
  final AttendanceStatus status;
  final bool manualAdded;
  final String? manualAddedBy;
  final String? manualAddedByName;
  final DateTime? manualAddedAt;
  final String? manualReason;

  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.matricNumber,
    required this.department,
    this.phoneNumber = '',
    this.checkInTime,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    required this.deviceId,
    required this.status,
    this.manualAdded = false,
    this.manualAddedBy,
    this.manualAddedByName,
    this.manualAddedAt,
    this.manualReason,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) =>
      AttendanceRecord(
        id: map['id'] ?? '',
        sessionId: map['sessionId'] ?? '',
        studentId: map['studentId'] ?? '',
        studentName: map['studentName'] ?? '',
        matricNumber: map['matricNumber'] ?? '',
        department: map['department'] ?? '',
        phoneNumber: map['phoneNumber'] ?? '',
        checkInTime: map['checkInTime'] != null
            ? DateTime.parse(map['checkInTime'])
            : null,
        checkOutTime: map['checkOutTime'] != null
            ? DateTime.parse(map['checkOutTime'])
            : null,
        checkInLatitude: map['checkInLatitude']?.toDouble(),
        checkInLongitude: map['checkInLongitude']?.toDouble(),
        checkOutLatitude: map['checkOutLatitude']?.toDouble(),
        checkOutLongitude: map['checkOutLongitude']?.toDouble(),
        deviceId: map['deviceId'] ?? '',
        status: AttendanceStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => AttendanceStatus.absent,
        ),
        manualAdded: map['manualAdded'] == true,
        manualAddedBy: map['manualAddedBy'],
        manualAddedByName: map['manualAddedByName'],
        manualAddedAt: map['manualAddedAt'] != null
            ? DateTime.tryParse(map['manualAddedAt'].toString())
            : null,
        manualReason: map['manualReason'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'studentId': studentId,
        'studentName': studentName,
        'matricNumber': matricNumber,
        'department': department,
        'phoneNumber': phoneNumber,
        'checkInTime': checkInTime?.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'checkInLatitude': checkInLatitude,
        'checkInLongitude': checkInLongitude,
        'checkOutLatitude': checkOutLatitude,
        'checkOutLongitude': checkOutLongitude,
        'deviceId': deviceId,
        'status': status.name,
        'manualAdded': manualAdded,
        'manualAddedBy': manualAddedBy,
        'manualAddedByName': manualAddedByName,
        'manualAddedAt': manualAddedAt?.toIso8601String(),
        'manualReason': manualReason,
      };

  @override
  List<Object?> get props => [
        id,
        sessionId,
        studentId,
        phoneNumber,
        status,
        manualAdded,
        manualAddedBy,
        manualAddedAt,
      ];
}
