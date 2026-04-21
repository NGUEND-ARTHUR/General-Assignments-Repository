import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/attendance/presentation/pages/scan_qr_page.dart';
import '../../features/attendance/presentation/pages/generate_qr_page.dart';
import '../../features/courses/presentation/pages/home_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/live_attendance_page.dart';
import '../../features/admin/presentation/pages/user_management_page.dart';
import '../../features/admin/presentation/pages/attendance_analytics_page.dart';
import '../../features/admin/presentation/pages/role_approvals_page.dart';
import '../../features/export/presentation/pages/export_page.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final authRepository = GetIt.I<AuthRepository>();
      final user = await authRepository.getCurrentUser();
      final path = state.matchedLocation;

      const publicRoutes = {
        '/splash',
        '/role-select',
        '/login',
        '/register',
      };

      final isPublic = publicRoutes.contains(path);
      if (user == null) {
        if (!isPublic) return '/role-select';
        return null;
      }

      if (path == '/role-select' || path == '/login' || path == '/register') {
        return '/home';
      }

      final role = user.role;
      final isStaff = role == 'course_rep' ||
          role == 'lecturer' ||
          role == 'admin' ||
          role == 'super_admin';

      if (path.startsWith('/admin/') && !isStaff) return '/home';
      if (path.startsWith('/live-attendance/') && !isStaff) return '/home';
      if (path.startsWith('/export/') && !isStaff) return '/home';
      if (path.startsWith('/generate-qr/') && !isStaff) return '/home';
      if (path == '/role-approvals' && role != 'super_admin') return '/home';
      if (path.startsWith('/super-admin/') && role != 'super_admin') {
        return '/home';
      }
      if (path == '/analytics' && !isStaff) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(
          path: '/role-select', builder: (_, __) => const RoleSelectionPage()),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginPage(
          initialRole: state.uri.queryParameters['role'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegisterPage(
          initialRole: state.uri.queryParameters['role'],
        ),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(
        path: '/scan/:sessionId',
        builder: (_, state) =>
            ScanQrPage(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/generate-qr/:sessionId',
        builder: (_, state) =>
            GenerateQrPage(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/admin/:courseId',
        builder: (_, state) =>
            AdminDashboardPage(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: '/live-attendance/:sessionId',
        builder: (_, state) =>
            LiveAttendancePage(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/export/:sessionId',
        builder: (_, state) =>
            ExportPage(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
          path: '/role-approvals',
          builder: (_, __) => const RoleApprovalsPage()),
      GoRoute(
          path: '/super-admin/users',
          builder: (_, __) => const UserManagementPage()),
      GoRoute(
          path: '/analytics',
          builder: (_, __) => const AttendanceAnalyticsPage()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
