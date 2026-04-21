import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../../shared/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/api_service.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../courses/domain/repositories/course_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  final String courseId;
  const AdminDashboardPage({super.key, required this.courseId});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_DashboardData> _dashboardFuture;
  String? _currentRole;
  bool _loadingRole = true;
  bool _isSubmittingAction = false;
  Timer? _refreshTimer;

  static const Duration _dashboardRefreshInterval = Duration(seconds: 8);

  Future<Position?> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final locationService = GetIt.I<LocationService>();
    return await locationService.getCurrentPosition() ??
        await Geolocator.getLastKnownPosition();
  }

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
    _loadCurrentUserRole();
    _refreshTimer = Timer.periodic(_dashboardRefreshInterval, (_) {
      if (!mounted || _isSubmittingAction) return;
      setState(() {
        _dashboardFuture = _loadDashboard();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUserRole() async {
    final api = GetIt.I<ApiService>();
    Map<String, dynamic>? user;
    try {
      final me = await api.get('/auth/me');
      final raw = me['user'];
      if (raw is Map<String, dynamic>) {
        user = raw;
      }
    } catch (_) {
      try {
        user = await api.getCurrentUser();
      } catch (_) {
        user = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _currentRole = user?['role']?.toString();
      _loadingRole = false;
    });
  }

  Future<void> _createSession() async {
    final courseRepo = GetIt.I<CourseRepository>();
    Position? position = await _resolvePosition();
    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location is unavailable. Enable location permission/GPS and try again.'),
        ),
      );
      return;
    }

    try {
      setState(() => _isSubmittingAction = true);
      await courseRepo.createSession(
        AttendanceSession(
          id: '',
          courseId: widget.courseId,
          courseCode: '',
          courseName: '',
          lecturerId: '',
          courseRepId: '',
          classType: ClassType.normal,
          scheduledDate: DateTime.now(),
          status: SessionStatus.pending,
          classroomLatitude: position.latitude,
          classroomLongitude: position.longitude,
        ),
      );

      if (!mounted) return;
      setState(() {
        _isSubmittingAction = false;
        _dashboardFuture = _loadDashboard();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Attendance session started successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingAction = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create session failed: $e')),
      );
    }
  }

  Future<_DashboardData> _loadDashboard() async {
    final courseRepo = GetIt.I<CourseRepository>();
    final attendanceRepo = GetIt.I<AttendanceRepository>();

    final courses = await courseRepo.getCoursesForStudent('');
    CourseModel? course;
    for (final c in courses) {
      if (c.id == widget.courseId) {
        course = c;
        break;
      }
    }

    final sessions = await courseRepo.getSessionsForCourse(widget.courseId);
    final active = await courseRepo.getActiveSession(widget.courseId);
    final latestSession = sessions.isNotEmpty ? sessions.first : null;
    final actionable = active ?? latestSession;
    final sessionStatus = actionable?.status.name ?? 'none';
    final sessionIsActive =
        sessionStatus == SessionStatus.openForCheckIn.name ||
            sessionStatus == SessionStatus.openForCheckOut.name;

    if (actionable == null) {
      return _DashboardData(
        courseCode: course?.courseCode ?? widget.courseId,
        courseName: course?.courseName ?? 'Course Session',
        lecturerName: course?.lecturerName ?? 'Unknown Lecturer',
        sessionId: null,
        sessionStatus: 'none',
        totalSessions: sessions.length,
        canManage: course?.canManage ?? false,
        enrolled: course?.enrolledCount ?? 0,
        present: 0,
        absent: 0,
        partial: 0,
        sessionIsActive: false,
      );
    }

    final records = await attendanceRepo.getSessionAttendance(actionable.id);
    final enrolled = course?.enrolledCount ?? records.length;
    final present =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final partial =
        records.where((r) => r.status == AttendanceStatus.partial).length;
    final absent =
        (enrolled - present - partial) < 0 ? 0 : (enrolled - present - partial);

    return _DashboardData(
      courseCode: course?.courseCode ?? widget.courseId,
      courseName: course?.courseName ?? 'Course Session',
      lecturerName: course?.lecturerName ?? 'Unknown Lecturer',
      sessionId: actionable.id,
      sessionStatus: actionable.status.name,
      totalSessions: sessions.length,
      canManage: course?.canManage ?? false,
      enrolled: enrolled,
      present: present,
      absent: absent,
      partial: partial,
      sessionIsActive: sessionIsActive,
    );
  }

  Future<void> _openCheckOut(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) {
      _showNoActiveSession();
      return;
    }
    final courseRepo = GetIt.I<CourseRepository>();
    try {
      setState(() => _isSubmittingAction = true);
      await courseRepo.openCheckOut(sessionId);
      if (!mounted) return;
      setState(() {
        _isSubmittingAction = false;
        _dashboardFuture = _loadDashboard();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session moved to check-out phase.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingAction = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open check-out failed: $e')),
      );
    }
  }

  Future<void> _closeSession(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) {
      _showNoActiveSession();
      return;
    }
    final courseRepo = GetIt.I<CourseRepository>();
    try {
      setState(() => _isSubmittingAction = true);
      await courseRepo.closeSession(sessionId);
      if (!mounted) return;
      setState(() {
        _isSubmittingAction = false;
        _dashboardFuture = _loadDashboard();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session closed successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingAction = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Close session failed: $e')),
      );
    }
  }

  Future<void> _updateSessionLocation(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) {
      _showNoActiveSession();
      return;
    }

    final api = GetIt.I<ApiService>();
    Position? position = await _resolvePosition();
    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot update location: GPS unavailable.')),
      );
      return;
    }

    try {
      final detail = await api.get('/sessions/$sessionId');
      final raw = detail['session'] as Map<String, dynamic>?;
      if (raw == null) throw Exception('Session details unavailable');

      await api.put(
        '/sessions/$sessionId',
        data: {
          'course_id': (raw['course_id'] ?? widget.courseId).toString(),
          'class_type': (raw['class_type'] ?? 'normal').toString(),
          'scheduled_date':
              (raw['scheduled_date'] ?? DateTime.now().toIso8601String())
                  .toString(),
          'classroom_latitude': position.latitude,
          'classroom_longitude': position.longitude,
        },
      );

      if (!mounted) return;
      setState(() => _dashboardFuture = _loadDashboard());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session location updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update session failed: $e')),
      );
    }
  }

  void _showNoActiveSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No active session found for this course.')),
    );
  }

  Future<void> _showManualAddDialog(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) {
      _showNoActiveSession();
      return;
    }

    final identifierCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manual Attendance Add'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: identifierCtrl,
              decoration: const InputDecoration(
                labelText: 'Student email or matric number',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;

    final api = GetIt.I<ApiService>();
    try {
      await api.post(
        '/attendance/manual-add',
        data: {
          'session_id': sessionId,
          'student_identifier': identifierCtrl.text.trim(),
          'reason':
              reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      setState(() {
        _dashboardFuture = _loadDashboard();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manual attendance added and logged.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Manual add failed: $e')),
      );
    }
  }

  void _goTo(String route, String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      _showNoActiveSession();
      return;
    }
    context.push('$route/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final sessionId = data?.sessionId;
        return Scaffold(
          appBar: AppBar(title: const Text('Admin Dashboard')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNavy,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                    (data?.courseCode ?? widget.courseId)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ),
                              if (sessionId != null)
                                if (data?.sessionIsActive == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Session Active',
                                        style: TextStyle(
                                            color: AppTheme.successGreen,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11)),
                                  ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(data?.courseName ?? 'Course Session',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(data?.lecturerName ?? 'Live data from backend',
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Total sessions: ${data?.totalSessions ?? 0}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 430) {
                        final cardWidth = (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _StatBox(
                                  label: 'Enrolled',
                                  value: '${data?.enrolled ?? 0}',
                                  color: AppTheme.primaryNavy),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _StatBox(
                                  label: 'Present',
                                  value: '${data?.present ?? 0}',
                                  color: AppTheme.successGreen),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _StatBox(
                                  label: 'Absent',
                                  value: '${data?.absent ?? 0}',
                                  color: AppTheme.errorRed),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _StatBox(
                                  label: 'Partial',
                                  value: '${data?.partial ?? 0}',
                                  color: AppTheme.warningAmber),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                                label: 'Enrolled',
                                value: '${data?.enrolled ?? 0}',
                                color: AppTheme.primaryNavy),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatBox(
                                label: 'Present',
                                value: '${data?.present ?? 0}',
                                color: AppTheme.successGreen),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatBox(
                                label: 'Absent',
                                value: '${data?.absent ?? 0}',
                                color: AppTheme.errorRed),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatBox(
                                label: 'Partial',
                                value: '${data?.partial ?? 0}',
                                color: AppTheme.warningAmber),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Session Status',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _SessionControl(
                    sessionNumber: 1,
                    phase: sessionId != null
                        ? _sessionPhaseLabel(data?.sessionStatus)
                        : 'No Active Session',
                    isOpen: data?.sessionIsActive == true,
                    openedAt: sessionId != null
                        ? (data?.sessionIsActive == true
                            ? 'Active session is live'
                            : 'Latest session is closed')
                        : null,
                    onShowQR: () => _goTo('/generate-qr', sessionId),
                    onViewLive: () => _goTo('/live-attendance', sessionId),
                  ),
                  if (sessionId != null &&
                      data?.canManage == true &&
                      data?.sessionIsActive == true) ...[
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 420) {
                          return Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isSubmittingAction
                                      ? null
                                      : () => _openCheckOut(sessionId),
                                  icon: const Icon(Icons.logout_outlined),
                                  label: const Text('Open Check-Out'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _updateSessionLocation(sessionId),
                                  icon: const Icon(
                                      Icons.edit_location_alt_outlined),
                                  label: const Text('Update Session Location'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmittingAction
                                      ? null
                                      : () => _closeSession(sessionId),
                                  icon: const Icon(Icons.stop_circle_outlined),
                                  label: const Text('Close Session'),
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSubmittingAction
                                    ? null
                                    : () => _openCheckOut(sessionId),
                                icon: const Icon(Icons.logout_outlined),
                                label: const Text('Open Check-Out'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _updateSessionLocation(sessionId),
                                icon: const Icon(
                                    Icons.edit_location_alt_outlined),
                                label: const Text('Update Location'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSubmittingAction
                                    ? null
                                    : () => _closeSession(sessionId),
                                icon: const Icon(Icons.stop_circle_outlined),
                                label: const Text('Close Session'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Actions',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (data?.canManage == true) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isSubmittingAction ||
                                data?.sessionIsActive == true)
                            ? null
                            : _createSession,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(_isSubmittingAction
                            ? 'Processing...'
                            : (data?.sessionIsActive == true
                                ? 'Session Already Active'
                                : 'Start Attendance Session')),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (data?.canManage != true) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: const Text(
                        'You can view this course but cannot manage its attendance session actions.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF9A3412)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!_loadingRole && _currentRole == 'super_admin') ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showManualAddDialog(sessionId),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Manual Add Student'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.people_outline,
                          label: 'View Roster',
                          color: AppTheme.primaryNavy,
                          onTap: () => _goTo('/live-attendance', sessionId),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.download_outlined,
                          label: 'Export Sheet',
                          color: AppTheme.successGreen,
                          onTap: () => _goTo('/export', sessionId),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _sessionPhaseLabel(String? status) {
    switch (status) {
      case 'openForCheckIn':
        return 'Open for Check-In';
      case 'openForCheckOut':
        return 'Open for Check-Out';
      case 'closed':
        return 'Closed';
      default:
        return 'No Active Session';
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: TextStyle(fontSize: 9, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _SessionControl extends StatelessWidget {
  final int sessionNumber;
  final String phase;
  final bool isOpen;
  final String? openedAt;
  final VoidCallback onShowQR;
  final VoidCallback onViewLive;

  const _SessionControl({
    required this.sessionNumber,
    required this.phase,
    required this.isOpen,
    this.openedAt,
    required this.onShowQR,
    required this.onViewLive,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session $sessionNumber — $phase',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOpen ? '● Open' : 'Closed',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOpen
                              ? AppTheme.successGreen
                              : AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
              if (openedAt != null) ...[
                const SizedBox(height: 4),
                Text('Opened at $openedAt',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 360) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isOpen ? onShowQR : null,
                            icon: const Icon(Icons.qr_code, size: 16),
                            label: Text(isOpen ? 'Show QR' : 'Session Closed',
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onViewLive,
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('Live View',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isOpen ? onShowQR : null,
                          icon: const Icon(Icons.qr_code, size: 16),
                          label: Text(isOpen ? 'Show QR' : 'Session Closed',
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onViewLive,
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Live View',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}

class _DashboardData {
  final String courseCode;
  final String courseName;
  final String lecturerName;
  final String? sessionId;
  final String sessionStatus;
  final bool sessionIsActive;
  final int totalSessions;
  final bool canManage;
  final int enrolled;
  final int present;
  final int absent;
  final int partial;

  const _DashboardData({
    required this.courseCode,
    required this.courseName,
    required this.lecturerName,
    required this.sessionId,
    required this.sessionStatus,
    required this.sessionIsActive,
    required this.totalSessions,
    required this.canManage,
    required this.enrolled,
    required this.present,
    required this.absent,
    required this.partial,
  });
}
