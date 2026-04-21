import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

const _G = Color(0xFF0F6E56);
const _GL = Color(0xFFE1F5EE);
const _BG = Color(0xFFF7F6F2);
const _SUR = Color(0xFFFFFFFF);
const _T1 = Color(0xFF1A1A1A);
const _T2 = Color(0xFF6B6B6B);

class InstitutionDetailScreen extends ConsumerWidget {
  const InstitutionDetailScreen({required this.institutionId, Key? key})
      : super(key: key);
  final String institutionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: const Text('Institution Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/institutions'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ICT University Cameroon',
                style: GoogleFonts.rubik(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const _DetailSection(
                title: 'Basic Information',
                children: [
                  _DetailRow('Name', 'ICT University Cameroon'),
                  _DetailRow('Type', 'University'),
                  _DetailRow('City', 'Yaoundé'),
                  _DetailRow('Email', 'admin@ictu.cm'),
                ],
              ),
              const SizedBox(height: 24),
              const _DetailSection(
                title: 'Admin Contact',
                children: [
                  _DetailRow('Name', 'John Doe'),
                  _DetailRow('Email', 'john.doe@ictu.cm'),
                  _DetailRow('Phone', '+237 2 72 00 00 00'),
                  _DetailRow('Title', 'Registrar'),
                ],
              ),
              const SizedBox(height: 24),
              _DetailSection(
                title: 'Documents',
                children: [
                  ListTile(
                    title: const Text('Accreditation Certificate'),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Download'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _SUR,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: Text(
                title,
                style:
                    GoogleFonts.rubik(fontWeight: FontWeight.bold, color: _G),
              ),
            ),
            ...children,
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text('$label:',
                style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(value, style: GoogleFonts.rubik(color: _T2)),
            ),
          ],
        ),
      );
}
