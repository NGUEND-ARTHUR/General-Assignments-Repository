import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

const _G = Color(0xFF0F6E56);
const _GL = Color(0xFFE1F5EE);
const _SUR = Color(0xFFFFFFFF);
const _T2 = Color(0xFF6B6B6B);

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Audit Logs')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Filter by action...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                      onPressed: () {}, child: const Text('Export CSV')),
                ],
              ),
              const SizedBox(height: 24),
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
                          Expanded(flex: 1, child: const _HeaderCell('Action')),
                          Expanded(flex: 1, child: const _HeaderCell('Admin')),
                          Expanded(flex: 1, child: const _HeaderCell('Entity')),
                          Expanded(
                              flex: 1, child: const _HeaderCell('Timestamp')),
                          Expanded(flex: 1, child: const _HeaderCell('IP')),
                        ],
                      ),
                    ),
                    const _AuditRow(
                      action: 'institution_approved',
                      admin: 'admin@diplomax.cm',
                      entity: 'ICTU',
                      timestamp: '2024-04-05 14:32:10',
                      ip: '192.168.1.100',
                    ),
                    const Divider(height: 1),
                    const _AuditRow(
                      action: 'admin_created',
                      admin: 'superadmin@diplomax.cm',
                      entity: 'john.doe@diplomax.cm',
                      timestamp: '2024-04-05 10:15:42',
                      ip: '192.168.1.50',
                    ),
                    const Divider(height: 1),
                    const _AuditRow(
                      action: 'institution_suspended',
                      admin: 'admin@diplomax.cm',
                      entity: 'ENSP',
                      timestamp: '2024-04-04 09:20:15',
                      ip: '192.168.1.100',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.rubik(fontWeight: FontWeight.bold, color: _G),
      );
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({
    required this.action,
    required this.admin,
    required this.entity,
    required this.timestamp,
    required this.ip,
  });
  final String action;
  final String admin;
  final String entity;
  final String timestamp;
  final String ip;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(action, style: GoogleFonts.rubik(fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: Text(admin, style: GoogleFonts.rubik(fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: Text(entity, style: GoogleFonts.rubik(fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: Text(
                timestamp,
                style: GoogleFonts.rubik(fontSize: 12, color: _T2),
              ),
            ),
            Expanded(
              flex: 1,
              child:
                  Text(ip, style: GoogleFonts.rubik(fontSize: 12, color: _T2)),
            ),
          ],
        ),
      );
}
