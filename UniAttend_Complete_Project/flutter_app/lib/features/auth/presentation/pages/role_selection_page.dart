import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = [
      const _RoleChoice(
        role: AppConstants.roleStudent,
        title: 'Student',
        subtitle: 'Attend classes, check your history, and track approvals.',
      ),
      const _RoleChoice(
        role: AppConstants.roleCourseRep,
        title: 'Course Representative',
        subtitle: 'Manage attendance sessions for your course.',
      ),
      const _RoleChoice(
        role: AppConstants.roleLecturer,
        title: 'Lecturer',
        subtitle: 'Open sessions, monitor live attendance, and export sheets.',
      ),
      const _RoleChoice(
        role: AppConstants.roleAdmin,
        title: 'Admin',
        subtitle: 'Oversee attendance operations, sessions, and exports.',
      ),
      const _RoleChoice(
        role: AppConstants.roleSuperAdmin,
        title: 'Super Admin',
        subtitle: 'Platform owner access for role approvals and governance.',
        canRegister: false,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'ICT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UniAttend',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose the role you want to use in the app.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Select role',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a role, then sign in. For Course Rep, Lecturer, and Admin, new users register first and are reviewed by Super Admin.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ...roles.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _RoleCard(choice: choice),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChoice {
  final String role;
  final String title;
  final String subtitle;
  final bool canRegister;

  const _RoleChoice({
    required this.role,
    required this.title,
    required this.subtitle,
    this.canRegister = true,
  });
}

class _RoleCard extends StatelessWidget {
  final _RoleChoice choice;

  const _RoleCard({required this.choice});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: AppTheme.primaryNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        choice.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/login?role=${choice.role}'),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: choice.canRegister
                      ? ElevatedButton(
                          onPressed: () =>
                              context.go('/register?role=${choice.role}'),
                          child: const Text('Register'),
                        )
                      : const ElevatedButton(
                          onPressed: null,
                          child: Text('Register Disabled'),
                        ),
                ),
              ],
            ),
            if (!choice.canRegister) ...[
              const SizedBox(height: 8),
              const Text(
                'Super Admin accounts are provisioned by backend bootstrap credentials and should sign in directly.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
