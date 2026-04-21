import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/user_provider.dart';
import '../../../widgets/app_sidebar.dart';

const _G = Color(0xFF0F6E56);
const _GL = Color(0xFFE1F5EE);
const _BG = Color(0xFFF7F6F2);
const _SUR = Color(0xFFFFFFFF);
const _BD = Color(0xFFE0DDD5);
const _T1 = Color(0xFF1A1A1A);
const _T2 = Color(0xFF6B6B6B);

class SecurityDashboardScreen extends ConsumerWidget {
  const SecurityDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                currentUser?.email ?? 'guest',
                style: GoogleFonts.rubik(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(userProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      drawer: const AppSidebar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security metrics cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 24) / 3;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _SecurityMetricCard(
                      'Failed Login Attempts',
                      '23',
                      Colors.red,
                      cardWidth,
                    ),
                    _SecurityMetricCard(
                      'Suspicious IP Addresses',
                      '5',
                      Colors.orange,
                      cardWidth,
                    ),
                    _SecurityMetricCard(
                      'Documents Revoked (Fraud)',
                      '3',
                      Colors.redAccent,
                      cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              'Recent Security Events',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _SUR,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
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
                        Expanded(flex: 1, child: const _HeaderCell('Severity')),
                        Expanded(
                          flex: 2,
                          child: const _HeaderCell('Event Type'),
                        ),
                        Expanded(flex: 2, child: const _HeaderCell('Details')),
                        Expanded(flex: 1, child: const _HeaderCell('Time')),
                        Expanded(flex: 1, child: const _HeaderCell('Status')),
                      ],
                    ),
                  ),
                  _SecurityEventRow(
                    severity: 'HIGH',
                    severityColor: Colors.red,
                    eventType: 'Failed Login Attempts',
                    details: '5 failed attempts from 192.168.1.100',
                    time: '2 hours ago',
                    status: 'Active',
                  ),
                  const Divider(height: 1),
                  _SecurityEventRow(
                    severity: 'MEDIUM',
                    severityColor: Colors.orange,
                    eventType: 'Suspicious IP Detected',
                    details: 'Unusual login from Nigeria (usual: Canada)',
                    time: '4 hours ago',
                    status: 'Monitored',
                  ),
                  const Divider(height: 1),
                  _SecurityEventRow(
                    severity: 'HIGH',
                    severityColor: Colors.red,
                    eventType: 'Document Revoked (Fraud)',
                    details: 'Suspicious diploma from ICT University',
                    time: '6 hours ago',
                    status: 'Investigated',
                  ),
                  const Divider(height: 1),
                  _SecurityEventRow(
                    severity: 'LOW',
                    severityColor: Colors.blue,
                    eventType: 'API Rate Limit Hit',
                    details: 'Institution IAFS exceeded rate limit',
                    time: '1 day ago',
                    status: 'Resolved',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Blocked IP Addresses',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _SUR,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            'IP Address',
                            style: GoogleFonts.rubik(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Reason',
                            style: GoogleFonts.rubik(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Blocked Date',
                            style: GoogleFonts.rubik(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Actions',
                            style: GoogleFonts.rubik(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _BlockedIPRow(
                    ipAddress: '192.168.1.100',
                    reason: 'Brute force attack (10+ failed attempts)',
                    blockedDate: '2024-04-07',
                  ),
                  const Divider(height: 1),
                  const _BlockedIPRow(
                    ipAddress: '203.45.67.89',
                    reason: 'Suspicious activity detected',
                    blockedDate: '2024-04-05',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Security Configuration',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _SUR,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ConfigRow(
                    'Max Login Attempts',
                    '5',
                    '(before lockout)',
                  ),
                  const SizedBox(height: 12),
                  const _ConfigRow(
                    'Lockout Duration',
                    '30 minutes',
                    '(1800 seconds)',
                  ),
                  const SizedBox(height: 12),
                  const _ConfigRow(
                    'Session Timeout (Liveness)',
                    '15 minutes',
                    '(900 seconds)',
                  ),
                  const SizedBox(height: 12),
                  const _ConfigRow(
                    'Password Expiry',
                    '90 days',
                    '(automatic reset required)',
                  ),
                  const SizedBox(height: 12),
                  const _ConfigRow(
                    'Two-Factor Auth',
                    'Enabled',
                    '(optional for admins)',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Security settings updated'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Security Configuration'),
                      style: ElevatedButton.styleFrom(backgroundColor: _G),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityMetricCard extends StatelessWidget {
  const _SecurityMetricCard(this.title, this.value, this.color, this.width);
  final String title;
  final String value;
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
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.rubik(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.rubik(fontSize: 14, color: _T2)),
          ],
        ),
      );
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.rubik(
          fontWeight: FontWeight.bold,
          color: _G,
          fontSize: 13,
        ),
      );
}

class _SecurityEventRow extends StatelessWidget {
  const _SecurityEventRow({
    required this.severity,
    required this.severityColor,
    required this.eventType,
    required this.details,
    required this.time,
    required this.status,
  });
  final String severity;
  final Color severityColor;
  final String eventType;
  final String details;
  final String time;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Chip(
                label: Text(
                  severity,
                  style: GoogleFonts.rubik(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: severityColor.withOpacity(0.2),
                labelStyle: TextStyle(color: severityColor),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(eventType, style: GoogleFonts.rubik(fontSize: 13)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                details,
                style: GoogleFonts.rubik(fontSize: 12, color: _T2),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(time,
                  style: GoogleFonts.rubik(fontSize: 12, color: _T2)),
            ),
            Expanded(
              flex: 1,
              child: Chip(
                label: Text(status, style: GoogleFonts.rubik(fontSize: 11)),
                backgroundColor: _GL,
              ),
            ),
          ],
        ),
      );
}

class _BlockedIPRow extends StatelessWidget {
  const _BlockedIPRow({
    required this.ipAddress,
    required this.reason,
    required this.blockedDate,
  });
  final String ipAddress;
  final String reason;
  final String blockedDate;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                ipAddress,
                style: GoogleFonts.robotoMono(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                reason,
                style: GoogleFonts.rubik(fontSize: 12, color: _T2),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(blockedDate, style: GoogleFonts.rubik(fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('IP address unblocked')),
                  );
                },
                tooltip: 'Unblock IP',
              ),
            ),
          ],
        ),
      );
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow(this.label, this.value, this.details);
  final String label;
  final String value;
  final String details;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.rubik(fontWeight: FontWeight.bold)),
              Text(details, style: GoogleFonts.rubik(fontSize: 11, color: _T2)),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _G,
            ),
          ),
        ],
      );
}
