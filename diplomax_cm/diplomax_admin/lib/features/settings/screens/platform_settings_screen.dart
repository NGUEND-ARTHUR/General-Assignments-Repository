import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

const _G = Color(0xFF0F6E56);
const _GL = Color(0xFFE1F5EE);
const _SUR = Color(0xFFFFFFFF);

class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PlatformSettingsScreen> createState() =>
      _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState
    extends ConsumerState<PlatformSettingsScreen> {
  late TextEditingController feeDiplomaController;
  late TextEditingController feeTranscriptController;
  late TextEditingController feeAttestaController;

  @override
  void initState() {
    super.initState();
    feeDiplomaController = TextEditingController(text: '2500');
    feeTranscriptController = TextEditingController(text: '1000');
    feeAttestaController = TextEditingController(text: '500');
  }

  @override
  void dispose() {
    feeDiplomaController.dispose();
    feeTranscriptController.dispose();
    feeAttestaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Platform Settings')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsSection(
            title: 'Certification Fees (FCFA)',
            children: [
              _SettingsTextField(
                label: 'Diploma',
                controller: feeDiplomaController,
              ),
              const SizedBox(height: 16),
              _SettingsTextField(
                label: 'Transcript',
                controller: feeTranscriptController,
              ),
              const SizedBox(height: 16),
              _SettingsTextField(
                label: 'Certificate & Attestation',
                controller: feeAttestaController,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'Revenue Split (%)',
            children: [
              _SettingsTextField(
                label: 'National Treasury',
                controller: TextEditingController(text: '40'),
              ),
              const SizedBox(height: 16),
              _SettingsTextField(
                label: 'Issuing University',
                controller: TextEditingController(text: '40'),
              ),
              const SizedBox(height: 16),
              _SettingsTextField(
                label: 'Diplomax Platform',
                controller: TextEditingController(text: '20'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsSection(
            title: 'Security Parameters',
            children: [
              _SettingsTextField(
                label: 'Max Login Attempts',
                controller: TextEditingController(text: '5'),
              ),
              const SizedBox(height: 16),
              _SettingsTextField(
                label: 'Lockout Duration (seconds)',
                controller: TextEditingController(text: '1800'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved successfully')),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
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
            style: GoogleFonts.rubik(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F6E56),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _SettingsTextField extends StatelessWidget {
  const _SettingsTextField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 1,
        child: Text(
          label,
          style: GoogleFonts.rubik(fontWeight: FontWeight.w500),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        flex: 1,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ),
    ],
  );
}
