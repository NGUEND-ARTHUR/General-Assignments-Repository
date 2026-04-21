import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_strings.dart';

const _G = Color(0xFF0F6E56);
const _GL = Color(0xFFE1F5EE);
const _BG = Color(0xFFF7F6F2);
const _SUR = Color(0xFFFFFFFF);
const _BD = Color(0xFFE0DDD5);
const _T1 = Color(0xFF1A1A1A);
const _T2 = Color(0xFF6B6B6B);

class InstitutionsScreen extends ConsumerWidget {
  const InstitutionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.institutionsTitle),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
        drawer: _buildSidebar(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter and search
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search institution...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: 'pending',
                    items: const [
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(
                        value: 'under_review',
                        child: Text('Under Review'),
                      ),
                      DropdownMenuItem(
                          value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(
                          value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Institutions table
              Container(
                decoration: BoxDecoration(
                  color: _SUR,
                  borderRadius: BorderRadius.circular(8),
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
                          Expanded(flex: 2, child: const _TableHeader('Name')),
                          Expanded(flex: 1, child: const _TableHeader('Type')),
                          Expanded(
                              flex: 1, child: const _TableHeader('Status')),
                          Expanded(flex: 1, child: const _TableHeader('Date')),
                          Expanded(
                              flex: 1, child: const _TableHeader('Actions')),
                        ],
                      ),
                    ),
                    const _InstitutionRow(
                      name: 'ICT University',
                      type: 'University',
                      status: 'pending',
                      date: '2024-04-05',
                    ),
                    const Divider(height: 1),
                    const _InstitutionRow(
                      name: 'ENSP Yaoundé',
                      type: 'Grande Ecole',
                      status: 'approved',
                      date: '2024-03-15',
                    ),
                  ],
                ),
              ),
            ],
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
                ],
              ),
            ),
            _DrawerItem('Dashboard', Icons.dashboard, () {
              Navigator.pop(context);
              context.go('/dashboard');
            }),
            _DrawerItem('Institutions', Icons.school, () {
              Navigator.pop(context);
              context.go('/institutions');
            }),
            _DrawerItem('Admins', Icons.admin_panel_settings, () {
              Navigator.pop(context);
              context.go('/admins');
            }),
            _DrawerItem('Audit Logs', Icons.history, () {
              Navigator.pop(context);
              context.go('/audit-logs');
            }),
            _DrawerItem('Settings', Icons.settings, () {
              Navigator.pop(context);
              context.go('/settings');
            }),
          ],
        ),
      );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.rubik(fontWeight: FontWeight.bold, color: _G),
      );
}

class _InstitutionRow extends StatelessWidget {
  const _InstitutionRow({
    required this.name,
    required this.type,
    required this.status,
    required this.date,
  });
  final String name;
  final String type;
  final String status;
  final String date;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(name, style: GoogleFonts.rubik())),
            Expanded(flex: 1, child: Text(type, style: GoogleFonts.rubik())),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'pending' ? Colors.orange.shade50 : _GL,
                  border: Border.all(
                    color: status == 'pending' ? Colors.orange : _G,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    color: status == 'pending' ? Colors.orange : _G,
                  ),
                ),
              ),
            ),
            Expanded(flex: 1, child: Text(date, style: GoogleFonts.rubik())),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () => context.go('/institutions/123'),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, size: 18, color: _G),
                    onPressed: () {},
                    tooltip: 'Approve',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: _G),
        title: Text(title, style: GoogleFonts.rubik()),
        onTap: onTap,
      );
}
