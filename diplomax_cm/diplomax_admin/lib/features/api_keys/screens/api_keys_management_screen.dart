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

class APIKeysManagementScreen extends ConsumerWidget {
  const APIKeysManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Keys Management'),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _GL,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _G),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: _G),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'API Keys are used by institutions to authenticate requests. Rotate keys regularly for security.',
                      style: GoogleFonts.rubik(fontSize: 13, color: _T2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Active API Keys',
              style: GoogleFonts.rubik(
                fontSize: 18,
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
                        Expanded(
                          flex: 2,
                          child: const _HeaderCell('Institution'),
                        ),
                        Expanded(
                          flex: 2,
                          child: const _HeaderCell('API Key (Masked)'),
                        ),
                        Expanded(flex: 1, child: const _HeaderCell('Created')),
                        Expanded(
                          flex: 1,
                          child: const _HeaderCell('Last Used'),
                        ),
                        Expanded(flex: 1, child: const _HeaderCell('Actions')),
                      ],
                    ),
                  ),
                  const _APIKeyRow(
                    institution: 'ICT University',
                    apiKey: 'sk_live_4eC39HqLyjWDarhtT88***',
                    created: '2024-01-15',
                    lastUsed: '2024-04-08 10:45',
                  ),
                  const Divider(height: 1),
                  const _APIKeyRow(
                    institution: 'IAFS University',
                    apiKey: 'sk_live_7nF48IrMzxXbesuiU99***',
                    created: '2024-02-20',
                    lastUsed: '2024-04-07 16:20',
                  ),
                  const Divider(height: 1),
                  const _APIKeyRow(
                    institution: 'UYI',
                    apiKey: 'sk_live_2pG55JsNaYYcftvjV44***',
                    created: '2024-03-10',
                    lastUsed: '2024-04-08 09:15',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Revoked API Keys',
              style: GoogleFonts.rubik(
                fontSize: 18,
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
                          flex: 2,
                          child: Text(
                            'Institution',
                            style: GoogleFonts.rubik(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'API Key (Masked)',
                            style: GoogleFonts.rubik(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Revoked',
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
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'State University',
                            style: GoogleFonts.rubik(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'sk_live_old_key_revoked***',
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: _T2,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '2024-03-05',
                            style: GoogleFonts.rubik(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Suspected Compromise',
                            style: GoogleFonts.rubik(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
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

class _APIKeyRow extends StatelessWidget {
  const _APIKeyRow({
    required this.institution,
    required this.apiKey,
    required this.created,
    required this.lastUsed,
  });
  final String institution;
  final String apiKey;
  final String created;
  final String lastUsed;

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
              flex: 2,
              child: Tooltip(
                message: 'Demo key: $apiKey',
                child: Text(
                  apiKey,
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
              child: Text(created, style: GoogleFonts.rubik(fontSize: 13)),
            ),
            Expanded(
              flex: 1,
              child: Text(
                lastUsed,
                style: GoogleFonts.rubik(fontSize: 12, color: _T2),
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
                        builder: (_) => _FullKeyDialog(apiKey: apiKey),
                      );
                    },
                    tooltip: 'Show Full Key',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        size: 18, color: Colors.orange),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            _RotateKeyDialog(institution: institution),
                      );
                    },
                    tooltip: 'Rotate Key',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FullKeyDialog extends StatelessWidget {
  const _FullKeyDialog({required this.apiKey});
  final String apiKey;

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Full API Key',
                style: GoogleFonts.rubik(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _BG,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _BD),
                ),
                child: SelectableText(
                  apiKey,
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _RotateKeyDialog extends StatelessWidget {
  const _RotateKeyDialog({required this.institution});
  final String institution;

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rotate API Key',
                style: GoogleFonts.rubik(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Institution: $institution',
                style: GoogleFonts.rubik(fontSize: 14, color: _T2),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A new key will be generated. The old key will be revoked within 24 hours.',
                        style: GoogleFonts.rubik(fontSize: 12),
                      ),
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
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('API key rotated successfully'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('Rotate Key'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
