import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_strings.dart';

const _G = Color(0xFF0F6E56);
const _GL = Color(0xFFE1F5EE);
const _BG = Color(0xFFF7F6F2);
const _SUR = Color(0xFFFFFFFF);
const _BD = Color(0xFFE0DDD5);
const _T1 = Color(0xFF1A1A1A);
const _T2 = Color(0xFF6B6B6B);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.dashboardTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'admin@diplomax.cm',
                  style: GoogleFonts.rubik(color: Colors.white),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.go('/login'),
              tooltip: AppStrings.logout,
            ),
          ],
        ),
        drawer: _buildSidebar(context),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 768;
                    final childWidth = isSmall
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 24) / 3;

                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        _DashboardCard(
                          title: AppStrings.dashboardPendingApplications,
                          value: '12',
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                          width: childWidth - 24,
                        ),
                        _DashboardCard(
                          title: AppStrings.dashboardApprovedInstitutions,
                          value: '24',
                          icon: Icons.check_circle,
                          color: _G,
                          width: childWidth - 24,
                        ),
                        _DashboardCard(
                          title: AppStrings.dashboardActiveAdmins,
                          value: '8',
                          icon: Icons.admin_panel_settings,
                          color: Colors.blue,
                          width: childWidth - 24,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  AppStrings.dashboardRecentActivity,
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _T1,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRecentActivityTable(),
              ],
            ),
          ),
        ),
      );

  Widget _buildSidebar(BuildContext context) => Drawer(
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
                    'System Administration Portal',
                    style: GoogleFonts.rubik(fontSize: 12, color: _GL),
                  ),
                ],
              ),
            ),
            _DrawerItem(
              title: AppStrings.navDashboard,
              icon: Icons.dashboard,
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
            _DrawerItem(
              title: AppStrings.navInstitutions,
              icon: Icons.school,
              onTap: () {
                Navigator.pop(context);
                context.go('/institutions');
              },
            ),
            _DrawerItem(
              title: AppStrings.navAdmins,
              icon: Icons.admin_panel_settings,
              onTap: () {
                Navigator.pop(context);
                context.go('/admins');
              },
            ),
            _DrawerItem(
              title: AppStrings.navAuditLogs,
              icon: Icons.history,
              onTap: () {
                Navigator.pop(context);
                context.go('/audit-logs');
              },
            ),
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
                context.go('/login');
              },
            ),
          ],
        ),
      );

  Widget _buildRecentActivityTable() => Container(
        decoration: BoxDecoration(
          color: _SUR,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _GL,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Action',
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.bold,
                        color: _G,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Admin',
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.bold,
                        color: _G,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Entity',
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.bold,
                        color: _G,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Time',
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.bold,
                        color: _G,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _RecentActivityRow(
              action: 'institution_approved',
              admin: 'admin@diplomax.cm',
              entity: 'ICTU',
              time: '2 hours ago',
            ),
            const Divider(height: 1),
            const _RecentActivityRow(
              action: 'admin_created',
              admin: 'superadmin@diplomax.cm',
              entity: 'john.doe@diplomax.cm',
              time: '5 hours ago',
            ),
          ],
        ),
      );
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _SUR,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.rubik(fontSize: 14, color: _T2),
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.rubik(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
}

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
        title: Text(title, style: GoogleFonts.rubik(fontSize: 14)),
        onTap: onTap,
      );
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({
    required this.action,
    required this.admin,
    required this.entity,
    required this.time,
  });
  final String action;
  final String admin;
  final String entity;
  final String time;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(action, style: GoogleFonts.rubik(fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Text(admin, style: GoogleFonts.rubik(fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Text(entity, style: GoogleFonts.rubik(fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: Text(time,
                  style: GoogleFonts.rubik(fontSize: 12, color: _T2)),
            ),
          ],
        ),
      );
}
