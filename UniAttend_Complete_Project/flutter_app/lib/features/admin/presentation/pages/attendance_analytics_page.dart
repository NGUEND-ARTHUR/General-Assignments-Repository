import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/api_service.dart';

class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({super.key});

  @override
  State<AttendanceAnalyticsPage> createState() =>
      _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  late Future<Map<String, dynamic>> _dashboardFuture;
  Future<Map<String, dynamic>>? _detailFuture;
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<Map<String, dynamic>> _loadDashboard() async {
    final api = GetIt.I<ApiService>();
    return api.get('/analytics/dashboard');
  }

  Future<Map<String, dynamic>> _loadCourseAnalytics(String courseId) async {
    final api = GetIt.I<ApiService>();
    return api.get('/analytics/course/$courseId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Analytics')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Failed to load analytics: ${snapshot.error}'));
          }

          final courses =
              (snapshot.data?['courses'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .toList();

          if (courses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No courses available for analytics yet.'),
              ),
            );
          }

          if (_selectedCourseId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _selectedCourseId = (courses.first['id'] ?? '').toString();
                _detailFuture = _loadCourseAnalytics(_selectedCourseId!);
              });
            });
          }

          final selectedCourse = courses.firstWhere(
            (course) => (course['id'] ?? '').toString() == _selectedCourseId,
            orElse: () => courses.first,
          );

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardFuture = _loadDashboard();
                if (_selectedCourseId != null) {
                  _detailFuture = _loadCourseAnalytics(_selectedCourseId!);
                }
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: (selectedCourse['id'] ?? '').toString(),
                  items: courses
                      .map(
                        (course) => DropdownMenuItem(
                          value: (course['id'] ?? '').toString(),
                          child: Text(
                            '${course['courseCode'] ?? course['course_code'] ?? '-'} • ${course['courseName'] ?? course['course_name'] ?? '-'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedCourseId = value;
                      _detailFuture = _loadCourseAnalytics(value);
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Select Course'),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>>(
                  future: _detailFuture,
                  builder: (context, detailSnapshot) {
                    if (detailSnapshot.connectionState !=
                        ConnectionState.done) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    if (detailSnapshot.hasError) {
                      return Center(
                          child: Text(
                              'Failed to load course analytics: ${detailSnapshot.error}'));
                    }

                    final course = (detailSnapshot.data?['course']
                            as Map<String, dynamic>?) ??
                        const {};
                    final students =
                        (detailSnapshot.data?['students'] as List<dynamic>? ??
                                const [])
                            .whereType<Map<String, dynamic>>()
                            .toList();
                    final sessions =
                        (detailSnapshot.data?['sessions'] as List<dynamic>? ??
                                const [])
                            .whereType<Map<String, dynamic>>()
                            .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${course['courseCode'] ?? '-'} • ${course['courseName'] ?? '-'}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    '${course['lecturerName'] ?? '-'} • ${course['semester'] ?? '-'} • ${course['academicYear'] ?? '-'}'),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _MetricCard(
                                        label: 'Enrolled',
                                        value: course['enrolledCount'] ?? 0,
                                        color: AppTheme.primaryNavy),
                                    _MetricCard(
                                        label: 'Sessions',
                                        value: course['sessionCount'] ?? 0,
                                        color: AppTheme.accentGold),
                                    _MetricCard(
                                        label: 'Present',
                                        value: course['presentCount'] ?? 0,
                                        color: AppTheme.successGreen),
                                    _MetricCard(
                                        label: 'Partial',
                                        value: course['partialCount'] ?? 0,
                                        color: AppTheme.warningAmber),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Student Attendance',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...students.map((student) {
                          final rate =
                              (student['attendanceRate'] ?? 0).toString();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (student['fullName'] ?? '-')
                                              .toString(),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text('$rate%',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryNavy)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                      '${student['email'] ?? '-'} • ${student['matricNumber'] ?? '-'}'),
                                  Text(
                                      '${student['department'] ?? '-'} • ${student['phoneNumber'] ?? '-'}'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _MiniStat(
                                          label: 'Attended',
                                          value: student['attendedCount'] ?? 0),
                                      _MiniStat(
                                          label: 'Present',
                                          value: student['presentCount'] ?? 0),
                                      _MiniStat(
                                          label: 'Partial',
                                          value: student['partialCount'] ?? 0),
                                      _MiniStat(
                                          label: 'Check-ins',
                                          value: student['checkInCount'] ?? 0),
                                      _MiniStat(
                                          label: 'Check-outs',
                                          value: student['checkOutCount'] ?? 0),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (students.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                  'No enrolled students for this course yet.'),
                            ),
                          ),
                        const SizedBox(height: 12),
                        const Text(
                          'Recent Sessions',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...sessions.map((session) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text((session['scheduled_date'] ?? '-')
                                  .toString()),
                              subtitle: Text(
                                  '${session['class_type'] ?? '-'} • ${session['status'] ?? '-'}'),
                              trailing: Text((session['id'] ?? '').toString()),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final Object value;
  final Color color;

  const _MetricCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final Object value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 11)),
    );
  }
}
