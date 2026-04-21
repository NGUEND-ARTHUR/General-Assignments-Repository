import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/models.dart';
import '../../../courses/domain/repositories/course_repository.dart';

class RegisterPage extends StatefulWidget {
  final String? initialRole;
  const RegisterPage({super.key, this.initialRole});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _matricCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedDept = AppConstants.departments.first;
  String _selectedRole = AppConstants.roleStudent;
  late Future<List<CourseModel>> _catalogFuture;
  final Set<String> _selectedCourseIds = {};
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    final initialRole = widget.initialRole;
    if (initialRole != null && AppConstants.roleValues.contains(initialRole)) {
      _selectedRole = initialRole;
      _setDefaultDeptForRole(initialRole);
    }
    _catalogFuture = _loadCatalog();
  }

  void _setDefaultDeptForRole(String role) {
    if (role == 'admin') {
      _selectedDept = 'ICT';
    } else if (role == 'lecturer') {
      _selectedDept = 'Admin';
    }
  }

  bool get _canPickCourses =>
      _selectedRole == 'student' || _selectedRole == 'course_rep';

  Future<List<CourseModel>> _loadCatalog() async {
    final repo = GetIt.I<CourseRepository>();
    return repo.getPublicCourseCatalog();
  }

  void _syncSelectionToRole() {
    if (!_canPickCourses) {
      _selectedCourseIds.clear();
    }
    _catalogFuture = _loadCatalog();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _matricCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // For admin/lecturer, use email-based matric if not provided
    String matricNumber = _matricCtrl.text.trim().toUpperCase();
    if ((matricNumber.isEmpty) &&
        (_selectedRole == 'admin' || _selectedRole == 'lecturer')) {
      // Extract prefix from email before @
      final emailPrefix = _emailCtrl.text.trim().split('@')[0].toUpperCase();
      matricNumber = '${_selectedRole.toUpperCase()}_$emailPrefix';
    }

    final user = UserModel(
      id: '',
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      matricNumber: matricNumber,
      department: _selectedDept,
      phoneNumber: _phoneCtrl.text.trim(),
      role: _selectedRole,
      createdAt: DateTime.now(),
    );
    context.read<AuthBloc>().add(
          RegisterRequested(
            user: user,
            password: _passCtrl.text,
            selectedCourseIds: _selectedCourseIds.toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go('/home');
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorRed),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Account'),
          leading: BackButton(
            onPressed: () => context.go(
              widget.initialRole == null
                  ? '/login'
                  : '/login?role=${widget.initialRole}',
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Account & Apply Role',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                      widget.initialRole == null
                          ? 'Pick your role from the landing page, then create or sign in to your account.'
                          : 'You are registering as ${_roleTitle(widget.initialRole!)}. Role upgrades are reviewed by the super admin.',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 28),
                  _field(_nameCtrl, 'Full Name', Icons.person_outline,
                      validator: (v) => v == null || v.trim().length < 3
                          ? 'Enter your full name'
                          : null),
                  const SizedBox(height: 14),
                  _field(
                      _emailCtrl,
                      'ICT University Email (@ictuniversity.edu.cm)',
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress, validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!v.toLowerCase().contains('@ictuniversity.edu.cm')) {
                      return 'Please use your ICT University email (@ictuniversity.edu.cm)';
                    }
                    return null;
                  }),
                  const SizedBox(height: 14),
                  if (_selectedRole == 'student' ||
                      _selectedRole == 'course_rep')
                    _field(_matricCtrl, 'Matriculation Number',
                        Icons.badge_outlined,
                        hint: 'e.g. 21SEN0042',
                        validator: (v) => v == null || v.trim().length < 6
                            ? 'Enter your matric number'
                            : null),
                  if (_selectedRole == 'student' ||
                      _selectedRole == 'course_rep')
                    const SizedBox(height: 14),
                  _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().length < 9
                          ? 'Enter a valid phone number'
                          : null),
                  const SizedBox(height: 14),
                  if (_selectedRole == 'student' ||
                      _selectedRole == 'course_rep')
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedDept,
                      decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.school_outlined)),
                      items: AppConstants.departments
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDept = v!),
                    ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                        labelText: 'Role Application',
                        prefixIcon: Icon(Icons.group_outlined)),
                    items: const [
                      DropdownMenuItem(
                          value: 'student', child: Text('Student')),
                      DropdownMenuItem(
                          value: 'course_rep',
                          child: Text('Course Representative (Student Lead)')),
                      DropdownMenuItem(
                          value: 'lecturer', child: Text('Lecturer (Apply)')),
                      DropdownMenuItem(
                          value: 'admin', child: Text('Admin (Apply)')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedRole = v!;
                        _setDefaultDeptForRole(v);
                        _syncSelectionToRole();
                      });
                    },
                  ),
                  if (_canPickCourses) ...[
                    const SizedBox(height: 18),
                    FutureBuilder<List<CourseModel>>(
                      future: _catalogFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Course catalog failed to load: ${snapshot.error}',
                            style: const TextStyle(
                                color: AppTheme.errorRed, fontSize: 12),
                          );
                        }

                        final catalog = snapshot.data ?? const <CourseModel>[];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Courses',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pick the courses you are registered for. You can adjust them later from your profile.',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            if (catalog.isEmpty)
                              const Text(
                                'No courses are available yet.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary),
                              )
                            else
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: catalog
                                    .map(
                                      (course) => FilterChip(
                                        selected: _selectedCourseIds
                                            .contains(course.id),
                                        label: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                120,
                                          ),
                                          child: Text(
                                            '${course.courseCode} • ${course.courseName}',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedCourseIds.add(course.id);
                                            } else {
                                              _selectedCourseIds
                                                  .remove(course.id);
                                            }
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              '${_selectedCourseIds.length} course(s) selected',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_selectedRole != 'student')
                    Text(
                      _selectedRole == 'admin' || _selectedRole == 'lecturer'
                          ? 'Staff roles require super admin approval. Your governance permissions will be granted after review.'
                          : 'This request will be submitted for super admin approval. Your account is created as student first, then upgraded after approval.',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 8
                        ? 'Password must be at least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _submit,
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Create Account'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _roleTitle(String role) {
    switch (role) {
      case 'course_rep':
        return 'Course Representative';
      case 'lecturer':
        return 'Lecturer';
      case 'admin':
        return 'Admin';
      case 'super_admin':
        return 'Super Admin';
      default:
        return 'Student';
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
        validator: validator,
      );
}
