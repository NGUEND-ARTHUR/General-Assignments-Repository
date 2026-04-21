import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../bloc/course_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/api_service.dart';
import '../../domain/repositories/course_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CourseBloc _courseBloc;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _courseBloc = GetIt.I<CourseBloc>();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _courseBloc.add(LoadCourses(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return BlocProvider.value(
      value: _courseBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(user),
              Expanded(
                child: _selectedTab == 0
                    ? _CoursesTab(user: user)
                    : _selectedTab == 1
                        ? _HistoryTab()
                        : _ProfileTab(user: user),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (i) => setState(() => _selectedTab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGold,
                ),
                child: const Center(
                  child: Text('ICT',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('UniAttend',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Hello, ${user?.fullName.split(' ').first ?? 'Student'} 👋',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (user != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(user.matricNumber, Icons.badge_outlined),
                _chip(user.department, Icons.school_outlined),
                _chip(_roleLabel(user.role), Icons.group_outlined),
              ],
            ),
            const SizedBox(height: 10),
            _RoleApplicationStatusBanner(user: user),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.role == 'super_admin')
                  OutlinedButton.icon(
                    onPressed: () => context.push('/super-admin/users'),
                    icon: const Icon(Icons.people_outline, color: Colors.white),
                    label: const Text('Manage Users',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                if (user.role == 'super_admin')
                  OutlinedButton.icon(
                    onPressed: () => context.push('/role-approvals'),
                    icon: const Icon(Icons.verified_user_outlined,
                        color: Colors.white),
                    label: const Text('Role Approvals',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                if (user.role == 'course_rep' ||
                    user.role == 'lecturer' ||
                    user.role == 'admin' ||
                    user.role == 'super_admin')
                  OutlinedButton.icon(
                    onPressed: () => context.push('/analytics'),
                    icon: const Icon(Icons.analytics_outlined,
                        color: Colors.white),
                    label: const Text('Attendance Analytics',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'course_rep':
        return 'Course Rep';
      case 'lecturer':
        return 'Lecturer';
      case 'admin':
        return 'Admin';
      case 'super_admin':
        return 'Super Admin';
      default:
        return 'Student';
    }
  }

  Widget _chip(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      );
}

// ─── Courses Tab ──────────────────────────────────────────────────────────────
class _CoursesTab extends StatelessWidget {
  final UserModel? user;
  const _CoursesTab({this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        if (state is CourseLoading || state is CourseInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CourseError) {
          return Center(child: Text(state.message));
        }
        if (state is CoursesLoaded) {
          final currentRole = user?.role;
          final activeByCourse = {
            for (final s in state.activeSessions) s.courseId: s,
          };
          final activeCourses = state.courses
              .where((c) => activeByCourse.containsKey(c.id))
              .toList();
          final otherCourses = state.courses
              .where((c) => !activeByCourse.containsKey(c.id))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _DashboardAnalyticsCard(),
              const SizedBox(height: 12),
              _PrivilegedActions(
                user: user,
                courses: state.courses,
                activeSessions: state.activeSessions,
              ),
              if (user != null &&
                  (currentRole == 'course_rep' ||
                      currentRole == 'lecturer' ||
                      currentRole == 'admin' ||
                      currentRole == 'super_admin'))
                const SizedBox(height: 8),
              _SectionHeader(title: 'Active Now', count: activeCourses.length),
              if (activeCourses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No active attendance session right now.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ...activeCourses.map(
                (c) => _CourseCard(
                  course: c,
                  isActive: true,
                  user: user,
                  activeSessionId: activeByCourse[c.id]?.id,
                ),
              ),
              const SizedBox(height: 8),
              _SectionHeader(
                  title: 'Today\'s Courses', count: otherCourses.length),
              ...otherCourses.map(
                (c) => _CourseCard(
                  course: c,
                  isActive: false,
                  user: user,
                  activeSessionId: null,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _RoleApplicationStatusBanner extends StatefulWidget {
  final UserModel user;
  const _RoleApplicationStatusBanner({required this.user});

  @override
  State<_RoleApplicationStatusBanner> createState() =>
      _RoleApplicationStatusBannerState();
}

class _RoleApplicationStatusBannerState
    extends State<_RoleApplicationStatusBanner> {
  late Future<List<Map<String, dynamic>>> _future;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      _refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final api = GetIt.I<ApiService>();
    final res = await api.get('/auth/role-applications/me');
    final list = (res['applications'] as List<dynamic>? ?? const []);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.role != 'student') {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'Role: Student. To become Course Rep, Lecturer, or Admin, apply during registration.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          );
        }

        final latest = snapshot.data!.first;
        final requestedRole =
            (latest['requested_role'] ?? 'unknown').toString();
        final status = (latest['status'] ?? 'pending').toString();

        Color statusColor;
        String statusLabel;
        switch (status) {
          case 'approved':
            statusColor = const Color(0xFF22C55E);
            statusLabel = 'Approved';
            break;
          case 'rejected':
            statusColor = const Color(0xFFEF4444);
            statusLabel = 'Rejected';
            break;
          default:
            statusColor = const Color(0xFFF59E0B);
            statusLabel = 'Pending Super Admin Review';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Role application: $requestedRole • $statusLabel',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: _refresh,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.refresh, size: 14, color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryNavy,
                      fontWeight: FontWeight.w600)),
            )
          ],
        ),
      );
}

class _DashboardAnalyticsCard extends StatefulWidget {
  const _DashboardAnalyticsCard();

  @override
  State<_DashboardAnalyticsCard> createState() =>
      _DashboardAnalyticsCardState();
}

class _DashboardAnalyticsCardState extends State<_DashboardAnalyticsCard> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final repo = GetIt.I<CourseRepository>();
    return repo.getDashboardAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final summary =
            (snapshot.data?['summary'] as Map<String, dynamic>?) ?? const {};
        final visibleCourses = (summary['visibleCourseCount'] ?? 0).toString();
        final enrolled = (summary['totalEnrolledCount'] ?? 0).toString();
        final activeSessions = (summary['activeSessionCount'] ?? 0).toString();
        final present = (summary['presentCount'] ?? 0).toString();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Analytics',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 400;
                    final tileWidth = narrow
                        ? (constraints.maxWidth - 10) / 2
                        : (constraints.maxWidth - 30) / 4;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                            width: tileWidth,
                            child: _StatCard(
                                label: 'Visible Courses',
                                value: visibleCourses,
                                color: AppTheme.primaryNavy)),
                        SizedBox(
                            width: tileWidth,
                            child: _StatCard(
                                label: 'Enrolled',
                                value: enrolled,
                                color: AppTheme.accentGold)),
                        SizedBox(
                            width: tileWidth,
                            child: _StatCard(
                                label: 'Active Sessions',
                                value: activeSessions,
                                color: AppTheme.successGreen)),
                        SizedBox(
                            width: tileWidth,
                            child: _StatCard(
                                label: 'Present Marks',
                                value: present,
                                color: AppTheme.errorRed)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrivilegedActions extends StatefulWidget {
  final UserModel? user;
  final List<CourseModel> courses;
  final List<AttendanceSession> activeSessions;

  const _PrivilegedActions({
    required this.user,
    required this.courses,
    required this.activeSessions,
  });

  @override
  State<_PrivilegedActions> createState() => _PrivilegedActionsState();
}

class _PrivilegedActionsState extends State<_PrivilegedActions> {
  String? _selectedCourseId;

  Future<void> _showCreateCourseDialog() async {
    final user = widget.user;
    if (user == null) return;

    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final semesterCtrl = TextEditingController(text: 'Semester 1');
    final yearCtrl =
        TextEditingController(text: DateTime.now().year.toString());
    final lecturerIdentifierCtrl = TextEditingController(
      text: user.role == 'lecturer' ? user.fullName : '',
    );
    final courseRepIdCtrl = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Course Code'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: semesterCtrl,
                decoration: const InputDecoration(labelText: 'Semester'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Academic Year'),
              ),
              if (user.role == 'admin' || user.role == 'super_admin') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: lecturerIdentifierCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lecturer Name',
                    helperText:
                        'Required for admin/super admin course creation',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: courseRepIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course Rep ID (Optional)',
                    helperText:
                        'Enter the user ID of the course representative for this course',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;

    final code = codeCtrl.text.trim().toUpperCase();
    final name = nameCtrl.text.trim();
    final semester = semesterCtrl.text.trim();
    final year = int.tryParse(yearCtrl.text.trim());
    final lecturerIdentifier = lecturerIdentifierCtrl.text.trim();
    final courseRepId = courseRepIdCtrl.text.trim();

    if (code.isEmpty || name.isEmpty || semester.isEmpty || year == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    if ((user.role == 'admin' || user.role == 'super_admin') &&
        lecturerIdentifier.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lecturer name is required for this role.')),
      );
      return;
    }

    final api = GetIt.I<ApiService>();
    try {
      await api.post(
        '/courses',
        data: {
          'course_code': code,
          'course_name': name,
          'semester': semester,
          'academic_year': year,
          if (user.role == 'admin' || user.role == 'super_admin') ...{
            'lecturer_identifier': lecturerIdentifier,
            'lecturerIdentifier': lecturerIdentifier,
            if (courseRepId.isNotEmpty) ...{
              'course_rep_id': courseRepId,
              'courseRepId': courseRepId,
            },
          },
        },
      );

      if (!mounted) return;
      context.read<CourseBloc>().add(LoadCourses(user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course created successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create course failed: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedCourseId =
        widget.courses.isNotEmpty ? widget.courses.first.id : null;
  }

  @override
  void didUpdateWidget(covariant _PrivilegedActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCourseId != null &&
        widget.courses.any((course) => course.id == _selectedCourseId)) {
      return;
    }
    _selectedCourseId =
        widget.courses.isNotEmpty ? widget.courses.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user?.role;
    final isPrivileged = role == 'course_rep' ||
        role == 'lecturer' ||
        role == 'admin' ||
        role == 'super_admin';

    if (!isPrivileged) {
      return const SizedBox.shrink();
    }

    final selectedCourse = widget.courses.isNotEmpty
        ? widget.courses.firstWhere(
            (course) => course.id == _selectedCourseId,
            orElse: () => widget.courses.first,
          )
        : null;
    final manageableCourses = widget.courses.where((c) => c.canManage).toList();
    final selectedManageableCourse = manageableCourses.isEmpty
        ? null
        : manageableCourses.firstWhere(
            (course) => course.id == _selectedCourseId,
            orElse: () => manageableCourses.first,
          );
    final selectedManageableCourseId = selectedManageableCourse?.id;
    final activeByCourse = {
      for (final session in widget.activeSessions) session.courseId: session,
    };
    final selectedActiveSession =
        selectedCourse != null ? activeByCourse[selectedCourse.id] : null;
    final hasActiveSession = selectedActiveSession != null;
    final hasManageableCourse = selectedManageableCourse != null;
    final canCreateCourse =
        role == 'lecturer' || role == 'admin' || role == 'super_admin';

    final actionCards = <Widget>[
      _ActionTile(
        icon: Icons.dashboard_outlined,
        title: 'Open Dashboard',
        subtitle: hasManageableCourse
            ? 'Manage your course and attendance tools'
            : 'No manageable course assigned yet',
        enabled: hasManageableCourse,
        onTap: hasManageableCourse
            ? () => context.push('/admin/${selectedManageableCourse.id}')
            : null,
      ),
      if (canCreateCourse)
        _ActionTile(
          icon: Icons.menu_book_outlined,
          title: 'Create Course',
          subtitle: 'Add a new course before creating attendance sessions',
          enabled: true,
          onTap: _showCreateCourseDialog,
        ),
      if (hasManageableCourse)
        _ActionTile(
          icon: Icons.add_circle_outline,
          title: 'Create Session',
          subtitle: 'Open the dashboard to create a new attendance session',
          enabled: true,
          onTap: selectedManageableCourseId == null
              ? null
              : () => context.push('/admin/$selectedManageableCourseId'),
        ),
      _ActionTile(
        icon: Icons.groups_outlined,
        title: 'Live Attendance',
        subtitle: hasActiveSession
            ? 'View students currently marked in the session'
            : 'Available when a session is active',
        enabled: hasActiveSession,
        onTap: hasActiveSession
            ? () => context.push('/live-attendance/${selectedActiveSession.id}')
            : null,
      ),
      _ActionTile(
        icon: Icons.download_outlined,
        title: 'Export Sheet',
        subtitle: hasActiveSession
            ? 'Download Excel, PDF, or CSV attendance reports'
            : 'Export becomes available when a session is active',
        enabled: hasActiveSession,
        onTap: hasActiveSession
            ? () => context.push('/export/${selectedActiveSession.id}')
            : null,
      ),
      _ActionTile(
        icon: Icons.qr_code_2_outlined,
        title: 'Show QR',
        subtitle: hasActiveSession
            ? 'Generate or refresh the attendance QR'
            : 'Requires an active session',
        enabled: hasActiveSession,
        onTap: hasActiveSession
            ? () => context.push('/generate-qr/${selectedActiveSession.id}')
            : null,
      ),
      if (role == 'super_admin')
        _ActionTile(
          icon: Icons.verified_user_outlined,
          title: 'Role Approvals',
          subtitle:
              'Approve or reject course rep, lecturer, and admin requests',
          enabled: true,
          onTap: () => context.push('/role-approvals'),
        ),
      if (role == 'super_admin')
        _ActionTile(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Audit All Roles',
          subtitle: 'Review role applications and governance decisions',
          enabled: true,
          onTap: () => context.push('/role-approvals'),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_roleTitle(role ?? 'student')} Actions',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'These are the actions available for the role you just signed into.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            if (widget.courses.length > 1) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCourseId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: widget.courses
                    .map(
                      (course) => DropdownMenuItem<String>(
                        value: course.id,
                        child:
                            Text('${course.courseCode} - ${course.courseName}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCourseId = value;
                  });
                },
              ),
            ],
            if (widget.courses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                selectedCourse == null
                    ? 'No course selected'
                    : 'Selected: ${selectedCourse.courseCode} • ${selectedCourse.courseName}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 560;
                final tileWidth = isCompact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: actionCards
                      .map((card) => SizedBox(width: tileWidth, child: card))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _roleTitle(String role) {
    switch (role) {
      case 'course_rep':
        return 'Course Rep';
      case 'lecturer':
        return 'Lecturer';
      case 'admin':
        return 'Admin';
      case 'super_admin':
        return 'Super Admin';
      default:
        return 'Student';
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppTheme.primaryNavy : AppTheme.textSecondary;
    return Material(
      color: enabled
          ? AppTheme.primaryNavy.withOpacity(0.06)
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? AppTheme.primaryNavy.withOpacity(0.16)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final bool isActive;
  final UserModel? user;
  final String? activeSessionId;
  const _CourseCard(
      {required this.course,
      required this.isActive,
      this.user,
      this.activeSessionId});

  @override
  Widget build(BuildContext context) {
    final isRep = user?.role == 'course_rep' ||
        user?.role == 'lecturer' ||
        user?.role == 'admin' ||
        user?.role == 'super_admin';
    final canScan = activeSessionId != null && activeSessionId!.isNotEmpty;
    final targetRoute = isRep
        ? '/admin/${course.id}'
        : canScan
            ? '/scan/$activeSessionId'
            : '/scan/${course.id}';
    final allowTap = isRep || isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: allowTap ? () => context.push(targetRoute) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(course.courseCode,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  if (isActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Session Open',
                              style: TextStyle(
                                  color: AppTheme.successGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Not Started',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 10)),
                    ),
                  const Spacer(),
                  if (isActive)
                    Icon(
                      isRep
                          ? Icons.admin_panel_settings
                          : Icons.qr_code_scanner,
                      color: AppTheme.primaryNavy,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(course.courseName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            course.lecturerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${course.enrolledCount} students',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              if (isRep || isActive) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(targetRoute),
                    icon: Icon(
                        isRep
                            ? Icons.admin_panel_settings
                            : Icons.qr_code_scanner,
                        size: 16),
                    label: Text(isRep ? 'Open Dashboard' : 'Scan to Check In'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────
class _HistoryTab extends StatefulWidget {
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  late final Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final api = GetIt.I<ApiService>();
    final response = await api.get('/attendance/me');
    final list = (response['records'] as List<dynamic>? ?? const []);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Failed to load history: ${snapshot.error}'));
        }

        final history = snapshot.data ?? const <Map<String, dynamic>>[];
        final total = history.length;
        final present =
            history.where((e) => (e['status'] ?? '') == 'present').length;
        final absent =
            history.where((e) => (e['status'] ?? '') == 'absent').length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 380) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _StatCard(
                          label: 'Total Classes',
                          value: '$total',
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _StatCard(
                          label: 'Present',
                          value: '$present',
                          color: AppTheme.successGreen,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _StatCard(
                          label: 'Absent',
                          value: '$absent',
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Classes',
                        value: '$total',
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Present',
                        value: '$present',
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Absent',
                        value: '$absent',
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('Recent Attendance',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No attendance records yet.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ...history.map((h) {
              final scheduledDate =
                  DateTime.tryParse((h['scheduled_date'] ?? '').toString());
              final date = scheduledDate != null
                  ? DateFormat('dd/MM/yyyy').format(scheduledDate)
                  : '-';
              final rawStatus = (h['status'] ?? '').toString();
              final status = rawStatus == 'present'
                  ? 'Present'
                  : rawStatus == 'absent'
                      ? 'Absent'
                      : 'Partial';
              return _HistoryItem(
                courseCode: (h['course_code'] ?? '-').toString(),
                date: date,
                status: status,
              );
            }),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _HistoryItem extends StatelessWidget {
  final String courseCode, date, status;
  const _HistoryItem(
      {required this.courseCode, required this.date, required this.status});

  Color get _statusColor {
    switch (status) {
      case 'Present':
        return AppTheme.successGreen;
      case 'Absent':
        return AppTheme.errorRed;
      default:
        return AppTheme.warningAmber;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Center(
                    child: Icon(Icons.class_outlined,
                        color: AppTheme.primaryNavy, size: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(courseCode,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final UserModel? user;
  const _ProfileTab({this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryNavy,
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.fullName ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              Text(user?.email ?? '',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ProfileField(
            label: 'Matriculation No.', value: user?.matricNumber ?? ''),
        _ProfileField(label: 'Department', value: user?.department ?? ''),
        _ProfileField(label: 'Role', value: user?.role ?? ''),
        _ProfileField(label: 'Phone', value: user?.phoneNumber ?? ''),
        if (user != null &&
            (user!.role == 'student' || user!.role == 'course_rep'))
          const _ManagedCoursesCard(),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            context.read<AuthBloc>().add(LogoutRequested());
            context.go('/login');
          },
          icon: const Icon(Icons.logout, color: AppTheme.errorRed),
          label: const Text('Sign Out',
              style: TextStyle(color: AppTheme.errorRed)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.errorRed),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _ManagedCoursesCard extends StatefulWidget {
  const _ManagedCoursesCard();

  @override
  State<_ManagedCoursesCard> createState() => _ManagedCoursesCardState();
}

class _ManagedCoursesCardState extends State<_ManagedCoursesCard> {
  late Future<List<CourseModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CourseModel>> _load() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    if (user == null) return const [];
    return GetIt.I<CourseRepository>().getCoursesForStudent(user.id);
  }

  Future<void> _manageCourses() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    if (user == null) return;

    final repo = GetIt.I<CourseRepository>();
    final catalog = await repo.getPublicCourseCatalog();
    final current = await repo.getCoursesForStudent(user.id);
    final selected = current.map((course) => course.id).toSet();

    if (!mounted) return;
    final didSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Manage My Courses'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select the courses you are currently registered for.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    if (catalog.isEmpty)
                      const Text('No courses available yet.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: catalog.map((course) {
                          final isSelected = selected.contains(course.id);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(course.courseCode),
                            onSelected: (value) {
                              setDialogState(() {
                                if (value) {
                                  selected.add(course.id);
                                } else {
                                  selected.remove(course.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (didSave != true) return;

    final currentIds = current.map((course) => course.id).toSet();
    final toAdd = selected.difference(currentIds);
    final toRemove = currentIds.difference(selected);

    for (final courseId in toAdd) {
      await repo.enrollInCourse(courseId);
    }
    for (final courseId in toRemove) {
      await repo.unenrollFromCourse(courseId);
    }

    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CourseModel>>(
      future: _future,
      builder: (context, snapshot) {
        final courses = snapshot.data ?? const <CourseModel>[];
        final count = courses.length;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Courses',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _manageCourses,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Add/Remove'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$count course(s) currently registered',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                if (courses.isEmpty)
                  const Text(
                    'No courses selected yet.',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: courses
                        .map(
                          (course) => Chip(
                            label: Text(course.courseCode),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label, value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary))),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
