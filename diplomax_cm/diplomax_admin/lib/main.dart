import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/admins/screens/admins_management_screen.dart';
import 'features/audit/screens/audit_logs_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/admin_dashboard_screen.dart';
import 'features/institutions/screens/institution_detail_screen.dart';
import 'features/institutions/screens/institutions_screen.dart';
import 'features/settings/screens/platform_settings_screen.dart';

const _G = Color(0xFF0F6E56);
const _GL = Color(0xFFE1F5EE);
const _BG = Color(0xFFF7F6F2);
const _SUR = Color(0xFFFFFFFF);
const _BD = Color(0xFFE0DDD5);
const _T1 = Color(0xFF1A1A1A);
const _T2 = Color(0xFF6B6B6B);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runApp(const ProviderScope(child: DiplomaxAdminApp()));
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/institutions',
      builder: (context, state) => const InstitutionsScreen(),
    ),
    GoRoute(
      path: '/institutions/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        if (id == null || id.isEmpty) {
          return const InstitutionsScreen();
        }
        return InstitutionDetailScreen(institutionId: id);
      },
    ),
    GoRoute(
      path: '/admins',
      builder: (context, state) => const AdminsManagementScreen(),
    ),
    GoRoute(
      path: '/audit-logs',
      builder: (context, state) => const AuditLogsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const PlatformSettingsScreen(),
    ),
  ],
  redirect: (context, state) {
    // TODO: Implement auth redirect logic
    return null;
  },
);

class DiplomaxAdminApp extends ConsumerWidget {
  const DiplomaxAdminApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Diplomax Admin Portal',
        routerConfig: _router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('fr')],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _G,
            brightness: Brightness.light,
          ),
          fontFamily: GoogleFonts.rubik().fontFamily,
          textTheme: TextTheme(
            headlineLarge: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _T1,
            ),
            headlineMedium: GoogleFonts.rubik(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _T1,
            ),
            headlineSmall: GoogleFonts.rubik(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _T1,
            ),
            titleLarge: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _T1,
            ),
            bodyLarge: GoogleFonts.rubik(fontSize: 16, color: _T2),
            bodyMedium: GoogleFonts.rubik(fontSize: 14, color: _T2),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: _G,
            foregroundColor: _SUR,
            elevation: 0,
            centerTitle: false,
          ),
          scaffoldBackgroundColor: _BG,
        ),
      );
}
