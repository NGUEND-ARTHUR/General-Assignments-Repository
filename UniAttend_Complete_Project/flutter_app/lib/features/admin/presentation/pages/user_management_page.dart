import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/api_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late Future<List<Map<String, dynamic>>> _usersFuture;
  String _roleFilter = 'all';
  String? _busyUserId;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final api = GetIt.I<ApiService>();
    final response = await api.get('/admin/users');
    final list = (response['users'] as List<dynamic>? ?? const []);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> users) {
    if (_roleFilter == 'all') return users;
    return users
        .where((user) => (user['role'] ?? '').toString() == _roleFilter)
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = _loadUsers();
    });
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final fullNameCtrl =
        TextEditingController(text: (user['full_name'] ?? '').toString());
    final emailCtrl =
        TextEditingController(text: (user['email'] ?? '').toString());
    final matricCtrl =
        TextEditingController(text: (user['matric_number'] ?? '').toString());
    final departmentCtrl =
        TextEditingController(text: (user['department'] ?? '').toString());
    final phoneCtrl =
        TextEditingController(text: (user['phone_number'] ?? '').toString());
    String role = (user['role'] ?? 'student').toString();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: matricCtrl,
                decoration: const InputDecoration(labelText: 'Matric Number'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: departmentCtrl,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(
                      value: 'course_rep', child: Text('Course Rep')),
                  DropdownMenuItem(value: 'lecturer', child: Text('Lecturer')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(
                      value: 'super_admin', child: Text('Super Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    role = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    setState(() => _busyUserId = user['id']?.toString());
    final api = GetIt.I<ApiService>();
    try {
      await api.put(
        '/admin/users/${user['id']}',
        data: {
          'full_name': fullNameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'matric_number': matricCtrl.text.trim(),
          'department': departmentCtrl.text.trim(),
          'phone_number':
              phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
          'role': role,
        },
      );
      if (!mounted) return;
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _toggleBlock(Map<String, dynamic> user) async {
    final isActive = user['is_active'] == true || user['isActive'] == true;
    final api = GetIt.I<ApiService>();
    setState(() => _busyUserId = user['id']?.toString());
    try {
      if (isActive) {
        final reasonCtrl = TextEditingController();
        final shouldBlock = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Block User'),
            content: TextField(
              controller: reasonCtrl,
              decoration:
                  const InputDecoration(labelText: 'Block reason (optional)'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Block'),
              ),
            ],
          ),
        );
        if (shouldBlock != true) return;
        await api.post(
          '/admin/users/${user['id']}/block',
          data: {
            'reason':
                reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
          },
        );
      } else {
        await api.post('/admin/users/${user['id']}/unblock', data: {});
      }
      if (!mounted) return;
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isActive ? 'User blocked.' : 'User unblocked.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Delete ${user['full_name'] ?? user['email'] ?? 'this user'} permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    setState(() => _busyUserId = user['id']?.toString());
    final api = GetIt.I<ApiService>();
    try {
      await api.delete('/admin/users/${user['id']}');
      if (!mounted) return;
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin User Management')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Failed to load users: ${snapshot.error}'));
          }

          final users = _applyFilter(snapshot.data ?? const []);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RoleChip(
                        label: 'All',
                        selected: _roleFilter == 'all',
                        onTap: () => setState(() => _roleFilter = 'all')),
                    _RoleChip(
                        label: 'Students',
                        selected: _roleFilter == 'student',
                        onTap: () => setState(() => _roleFilter = 'student')),
                    _RoleChip(
                        label: 'Course Reps',
                        selected: _roleFilter == 'course_rep',
                        onTap: () =>
                            setState(() => _roleFilter = 'course_rep')),
                    _RoleChip(
                        label: 'Lecturers',
                        selected: _roleFilter == 'lecturer',
                        onTap: () => setState(() => _roleFilter = 'lecturer')),
                    _RoleChip(
                        label: 'Admins',
                        selected: _roleFilter == 'admin',
                        onTap: () => setState(() => _roleFilter = 'admin')),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Users: ${users.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (users.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No users match the selected role filter.'),
                    ),
                  ),
                ...users.map((user) {
                  final isBusy = _busyUserId == user['id']?.toString();
                  final active =
                      user['is_active'] == true || user['isActive'] == true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (user['full_name'] ?? '-').toString(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  active ? 'Active' : 'Blocked',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? AppTheme.successGreen
                                        : AppTheme.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                              '${user['email'] ?? '-'} • ${(user['role'] ?? '-').toString()}'),
                          const SizedBox(height: 4),
                          Text('Matric: ${user['matric_number'] ?? '-'}'),
                          Text('Department: ${user['department'] ?? '-'}'),
                          Text('Phone: ${user['phone_number'] ?? '-'}'),
                          Text('Created: ${user['created_at'] ?? '-'}'),
                          if ((user['blocked_reason'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text('Blocked reason: ${user['blocked_reason']}'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed:
                                    isBusy ? null : () => _editUser(user),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    isBusy ? null : () => _toggleBlock(user),
                                icon: Icon(
                                    active ? Icons.block : Icons.lock_open),
                                label: Text(active ? 'Block' : 'Unblock'),
                              ),
                              ElevatedButton.icon(
                                onPressed:
                                    isBusy ? null : () => _deleteUser(user),
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorRed),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
