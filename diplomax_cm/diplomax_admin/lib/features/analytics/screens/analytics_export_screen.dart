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

class AnalyticsExportScreen extends ConsumerWidget {
  const AnalyticsExportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Export'),
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
            Text(
              'Platform Analytics',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Analytics cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 24) / 3;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _AnalyticsCard(
                      'Total Institutions',
                      '156',
                      Colors.blue,
                      cardWidth,
                    ),
                    _AnalyticsCard(
                      'Total Documents',
                      '12,847',
                      Colors.green,
                      cardWidth,
                    ),
                    _AnalyticsCard(
                      'Total Students',
                      '45,231',
                      Colors.orange,
                      cardWidth,
                    ),
                    _AnalyticsCard(
                      'Total Revenue',
                      '125.4M FCFA',
                      Colors.purple,
                      cardWidth,
                    ),
                    _AnalyticsCard(
                      'Active Verifications',
                      '8,923',
                      Colors.red,
                      cardWidth,
                    ),
                    _AnalyticsCard(
                      'Fraud Cases',
                      '12',
                      Colors.redAccent,
                      cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              'Revenue Breakdown',
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _RevenueRow(
                    'National Treasury (40%)',
                    '50.2M FCFA',
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _RevenueRow(
                    'Issuing Universities (40%)',
                    '50.2M FCFA',
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _RevenueRow(
                    'Diplomax Platform (20%)',
                    '25.1M FCFA',
                    Colors.orange,
                  ),
                  const Divider(height: 24),
                  const _RevenueRow(
                    'Total Platform Revenue',
                    '125.4M FCFA',
                    _G,
                    bold: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _exportToCSV,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Revenue Report as CSV'),
                      style: ElevatedButton.styleFrom(backgroundColor: _G),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Export Full Analytics',
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
                borderRadius: BorderRadius.circular(12),
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
                  Text(
                    'Select export format and date range, then download full analytics report',
                    style: GoogleFonts.rubik(fontSize: 14, color: _T2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _exportToCSV,
                            icon: const Icon(Icons.file_download),
                            label: const Text('Export as CSV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _G,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _exportToJSON,
                            icon: const Icon(Icons.code),
                            label: const Text('Export as JSON'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportToCSV() {
    // Mock export - would call backend API
    debugPrint('Exporting analytics as CSV...');
  }

  void _exportToJSON() {
    // Mock export - would call backend API
    debugPrint('Exporting analytics as JSON...');
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard(this.title, this.value, this.color, this.width);
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
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.analytics, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.rubik(fontSize: 13, color: _T2)),
      ],
    ),
  );
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow(this.label, this.amount, this.color, {this.bold = false});
  final String label;
  final String amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      Text(
        amount,
        style: GoogleFonts.rubik(
          fontSize: 14,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: bold ? _G : _T2,
        ),
      ),
    ],
  );
}
