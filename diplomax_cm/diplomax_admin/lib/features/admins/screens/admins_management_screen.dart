import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

const _G = Color(0xFF0F6E56);
const _GL = Color(0xFFE1F5EE);
const _SUR = Color(0xFFFFFFFF);

class AdminsManagementScreen extends ConsumerWidget {
  const AdminsManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: const Text('Admin Management'),
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showCreateAdminDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Admin'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
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
                      Expanded(flex: 2, child: const _HeaderCell('Email')),
                      Expanded(flex: 1, child: const _HeaderCell('Role')),
                      Expanded(flex: 1, child: const _HeaderCell('Status')),
                      Expanded(flex: 1, child: const _HeaderCell('Actions')),
                    ],
                  ),
                ),
                const _AdminRow(
                  email: 'admin@diplomax.cm',
                  role: 'diplomax_admin',
                  status: 'active',
                ),
                const Divider(height: 1),
                const _AdminRow(
                  email: 'john.doe@diplomax.cm',
                  role: 'diplomax_admin',
                  status: 'active',
                ),
              ],
            ),
          ),
        ),
      );

  void _showCreateAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(hintText: 'Email')),
            const SizedBox(height: 16),
            TextField(decoration: const InputDecoration(hintText: 'Full Name')),
            const SizedBox(height: 16),
            DropdownButton<String>(
              isExpanded: true,
              value: 'diplomax_admin',
              items: const [
                DropdownMenuItem(
                  value: 'diplomax_admin',
                  child: Text('Diplomax Admin'),
                ),
                DropdownMenuItem(
                  value: 'ministry_superadmin',
                  child: Text('Ministry Superadmin'),
                ),
                DropdownMenuItem(
                  value: 'ministry_analyst',
                  child: Text('Ministry Analyst'),
                ),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
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
        style: GoogleFonts.rubik(fontWeight: FontWeight.bold, color: _G),
      );
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({
    required this.email,
    required this.role,
    required this.status,
  });
  final String email;
  final String role;
  final String status;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(email)),
            Expanded(flex: 1, child: Text(role)),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'active',
                  style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
