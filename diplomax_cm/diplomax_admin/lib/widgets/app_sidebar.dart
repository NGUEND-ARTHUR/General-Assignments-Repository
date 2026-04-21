import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_strings.dart';
import '../../providers/user_provider.dart';

const _G = Color(0xFF0F6E56);
const _GL = Color(0xFFE1F5EE);
const _BG = Color(0xFFF7F6F2);
const _SUR = Color(0xFFFFFFFF);
const _T1 = Color(0xFF1A1A1A);
const _T2 = Color(0xFF6B6B6B);

/// Sidebar widget with role-based menu items
class AppSidebar extends ConsumerWidget {
  const AppSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(userProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: _G),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Diplomax Admin',
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.role.label ?? 'System Administration Portal',
                  style: GoogleFonts.rubik(fontSize: 12, color: _GL),
                ),
              ],
            ),
          ),
          // Dashboard - Always visible
          _DrawerItem(
            title: AppStrings.navDashboard,
            icon: Icons.dashboard,
            onTap: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          // Institutions - All roles except analyst can see this
          _DrawerItem(
            title: AppStrings.navInstitutions,
            icon: Icons.school,
            onTap: () {
              Navigator.pop(context);
              context.go('/institutions');
            },
          ),
          // Admins - Only superadmin can see this
          if (currentUser?.canManageAdmins() ?? false)
            _DrawerItem(
              title: AppStrings.navAdmins,
              icon: Icons.admin_panel_settings,
              onTap: () {
                Navigator.pop(context);
                context.go('/admins');
              },
            ),
          // Audit Logs - All roles can see this
          _DrawerItem(
            title: AppStrings.navAuditLogs,
            icon: Icons.history,
            onTap: () {
              Navigator.pop(context);
              context.go('/audit-logs');
            },
          ),
          // Settings - Only superadmin can see this
          if (currentUser?.canAccessSettings() ?? false)
            _DrawerItem(
              title: AppStrings.navSettings,
              icon: Icons.settings,
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
          const Divider(),
          _DrawerItem(
            title: AppStrings.logout,
            icon: Icons.logout,
            onTap: () {
              Navigator.pop(context);
              // Clear user state
              ref.read(userProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

/// Individual drawer item
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: _G),
        title: Text(title, style: GoogleFonts.rubik(fontSize: 14, color: _T1)),
        onTap: onTap,
        hoverColor: _GL,
      );
}
