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

class DocumentOversightScreen extends ConsumerWidget {
  const DocumentOversightScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Oversight'),
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
            // Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by institution...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: 'all',
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Types')),
                    DropdownMenuItem(value: 'diploma', child: Text('Diploma')),
                    DropdownMenuItem(
                      value: 'transcript',
                      child: Text('Transcript'),
                    ),
                    DropdownMenuItem(
                      value: 'certificate',
                      child: Text('Certificate'),
                    ),
                    DropdownMenuItem(
                      value: 'attestation',
                      child: Text('Attestation'),
                    ),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: 'active',
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'revoked', child: Text('Revoked')),
                    DropdownMenuItem(value: 'all', child: Text('All')),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Documents table
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
                        Expanded(
                          flex: 2,
                          child: const _HeaderCell('Institution'),
                        ),
                        Expanded(flex: 1, child: const _HeaderCell('Type')),
                        Expanded(
                          flex: 1,
                          child: const _HeaderCell('ID Hash (SHA-256)'),
                        ),
                        Expanded(flex: 1, child: const _HeaderCell('Issued')),
                        Expanded(flex: 1, child: const _HeaderCell('Status')),
                        Expanded(flex: 1, child: const _HeaderCell('Actions')),
                      ],
                    ),
                  ),
                  const _DocumentRow(
                    institution: 'ICT University',
                    docType: 'Diploma',
                    hash: 'a3f9c2e1...',
                    issued: '2024-03-15',
                    status: 'Active',
                  ),
                  const Divider(height: 1),
                  const _DocumentRow(
                    institution: 'IAFS University',
                    docType: 'Transcript',
                    hash: 'b4g8d3f2...',
                    issued: '2024-03-10',
                    status: 'Active',
                  ),
                  const Divider(height: 1),
                  const _DocumentRow(
                    institution: 'UYI',
                    docType: 'Certificate',
                    hash: 'c5h7e4g3...',
                    issued: '2024-02-28',
                    status: 'Revoked',
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

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.institution,
    required this.docType,
    required this.hash,
    required this.issued,
    required this.status,
  });
  final String institution;
  final String docType;
  final String hash;
  final String issued;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(institution, style: GoogleFonts.rubik(fontSize: 13)),
            ),
            Expanded(
              flex: 1,
              child: Text(docType, style: GoogleFonts.rubik(fontSize: 13)),
            ),
            Expanded(
              flex: 1,
              child: Tooltip(
                message: 'Full hash: sha256_$hash',
                child: Text(
                  hash,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: _T2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(issued, style: GoogleFonts.rubik(fontSize: 13)),
            ),
            Expanded(
              flex: 1,
              child: Chip(
                label: Text(status),
                backgroundColor: status == 'Active'
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                labelStyle: TextStyle(
                  color: status == 'Active'
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18, color: _G),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => _DocumentDetailDialog(
                          institution: institution,
                          docType: docType,
                          hash: hash,
                        ),
                      );
                    },
                    tooltip: 'View Details',
                  ),
                  if (status == 'Active')
                    IconButton(
                      icon:
                          const Icon(Icons.block, size: 18, color: Colors.red),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document revoked successfully'),
                          ),
                        );
                      },
                      tooltip: 'Revoke Document',
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DocumentDetailDialog extends StatelessWidget {
  const _DocumentDetailDialog({
    required this.institution,
    required this.docType,
    required this.hash,
  });
  final String institution;
  final String docType;
  final String hash;

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Document Details',
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _DetailRow('Institution', institution),
                _DetailRow('Document Type', docType),
                const _DetailRow('Status', 'Active'),
                const _DetailRow('Issued Date', '2024-03-15 14:30:45 UTC'),
                const _DetailRow('Expiry Date', 'Never (permanent)'),
                const Divider(height: 32),
                Text(
                  'SHA-256 Hash',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _BG,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _BD),
                  ),
                  child: SelectableText(
                    'a3f9c2e1d4b8f7c9e2a1b3c5d7f9a2e4c6b8d1f3a5c7e9b2d4f6a8c1e3b5d7',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: _T2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Blockchain Transaction',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _BG,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _BD),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Hash: 0xf7c9e2a1b3c5d7f9a2e4c6b8d1f3a5c7e9b2d4f6',
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Block: 15847392',
                        style: GoogleFonts.rubik(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Timestamp: 2024-03-15 14:35:22 UTC',
                        style: GoogleFonts.rubik(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document revoked successfully'),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Revoke Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(value, style: GoogleFonts.rubik(color: _T2)),
            ),
          ],
        ),
      );
}
