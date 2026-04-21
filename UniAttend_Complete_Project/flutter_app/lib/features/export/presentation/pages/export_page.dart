import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/export_service.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';

class ExportPage extends StatefulWidget {
  final String sessionId;
  const ExportPage({super.key, required this.sessionId});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  late Future<_ExportSummary> _summaryFuture;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<_ExportSummary> _loadSummary() async {
    final api = GetIt.I<ApiService>();
    final attendanceRepo = GetIt.I<AttendanceRepository>();
    final sessionRes = await api.get('/sessions/${widget.sessionId}');
    final session =
        (sessionRes['session'] as Map<String, dynamic>? ?? const {});
    final records = await attendanceRepo.getSessionAttendance(widget.sessionId);

    final present =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final partial =
        records.where((r) => r.status == AttendanceStatus.partial).length;
    final total = records.length;
    final date =
        DateTime.tryParse((session['scheduled_date'] ?? '').toString());

    final sessionModel = _toSessionModel(session);

    return _ExportSummary(
      session: sessionModel,
      records: records,
      course:
          '${session['course_code'] ?? '-'} — ${session['course_name'] ?? '-'}',
      date: date != null
          ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
          : '-',
      lecturer: (session['lecturer_name'] ?? '-').toString(),
      courseDelegate:
          (session['course_rep_name'] ?? session['lecturer_name'] ?? '-')
              .toString(),
      classType: (session['class_type'] ?? '-').toString().replaceAll('_', '-'),
      startTime: _formatSessionTime(
        DateTime.tryParse((session['check_in_opened_at'] ?? '').toString()) ??
            DateTime.tryParse((session['scheduled_date'] ?? '').toString()),
      ),
      endTime: _formatSessionTime(
        DateTime.tryParse((session['check_out_closed_at'] ?? '').toString()) ??
            DateTime.tryParse(
                (session['check_out_opened_at'] ?? '').toString()),
      ),
      attendance: '$present present, $partial partial, $total total records',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ExportSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final s = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Export Attendance')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Session Summary',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          const Divider(height: 20),
                          _SummaryRow('Session ID', widget.sessionId),
                          _SummaryRow('Date', s?.date ?? '-'),
                          _SummaryRow('Course', s?.course ?? '-'),
                          _SummaryRow('Lecturer', s?.lecturer ?? '-'),
                          _SummaryRow(
                              'Course Delegate', s?.courseDelegate ?? '-'),
                          _SummaryRow('Class Type', s?.classType ?? '-'),
                          _SummaryRow('Start Time', s?.startTime ?? '-'),
                          _SummaryRow('End Time', s?.endTime ?? '-'),
                          _SummaryRow('Attendance', s?.attendance ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Export Format',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _ExportOption(
                    icon: Icons.table_chart_outlined,
                    label: 'Excel (.xlsx)',
                    subtitle: 'Full attendance list with check-in/out times',
                    color: const Color(0xFF217346),
                    onTap: _isExporting || s == null
                        ? null
                        : () => _export(context, s, 'excel'),
                  ),
                  const SizedBox(height: 10),
                  _ExportOption(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF Report',
                    subtitle: 'Formatted for department filing with ICT header',
                    color: const Color(0xFFD32F2F),
                    onTap: _isExporting || s == null
                        ? null
                        : () => _export(context, s, 'pdf'),
                  ),
                  const SizedBox(height: 10),
                  _ExportOption(
                    icon: Icons.code_outlined,
                    label: 'CSV (.csv)',
                    subtitle: 'Raw data for statistical analysis',
                    color: const Color(0xFF1565C0),
                    onTap: _isExporting || s == null
                        ? null
                        : () => _export(context, s, 'csv'),
                  ),
                  if (_isExporting) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exported file includes:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF166534))),
                        SizedBox(height: 6),
                        Text(
                          '✓ Student name, matriculation no., department\n'
                          '✓ Check-in and check-out timestamps\n'
                          '✓ GPS coordinates at time of scan\n'
                          '✓ Device ID used for each scan\n'
                          '✓ ICT Cameroon logo header\n'
                          '✓ Lecturer name, course code, date',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _export(
    BuildContext context,
    _ExportSummary summary,
    String format,
  ) async {
    setState(() => _isExporting = true);
    final exportService = GetIt.I<ExportService>();
    try {
      File? file;
      if (format == 'excel') {
        file = await exportService.exportToExcel(
          session: summary.session,
          records: summary.records,
          lecturerName: summary.lecturer,
          courseDelegateName: summary.courseDelegate,
          startTimeLabel: summary.startTime,
          endTimeLabel: summary.endTime,
        );
      } else if (format == 'pdf') {
        file = await exportService.exportToPdf(
          session: summary.session,
          records: summary.records,
          lecturerName: summary.lecturer,
          courseDelegateName: summary.courseDelegate,
          startTimeLabel: summary.startTime,
          endTimeLabel: summary.endTime,
        );
      } else {
        file = await exportService.exportToCsv(
          session: summary.session,
          records: summary.records,
        );
      }

      if (!mounted) return;

      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate export file.')),
        );
      } else {
        await exportService.shareFile(file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  AttendanceSession _toSessionModel(Map<String, dynamic> raw) {
    final classTypeRaw = (raw['class_type'] ?? 'normal').toString();
    final classType =
        classTypeRaw == 'catch_up' ? ClassType.catchUp : ClassType.normal;
    final statusRaw = (raw['status'] ?? 'pending').toString();
    final status = statusRaw == 'open_for_check_in'
        ? SessionStatus.openForCheckIn
        : statusRaw == 'open_for_check_out'
            ? SessionStatus.openForCheckOut
            : statusRaw == 'closed'
                ? SessionStatus.closed
                : SessionStatus.pending;

    return AttendanceSession(
      id: (raw['id'] ?? widget.sessionId).toString(),
      courseId: (raw['course_id'] ?? '').toString(),
      courseCode: (raw['course_code'] ?? '').toString(),
      courseName: (raw['course_name'] ?? '').toString(),
      lecturerId: (raw['lecturer_id'] ?? '').toString(),
      courseRepId: (raw['course_rep_id'] ?? '').toString(),
      classType: classType,
      scheduledDate:
          DateTime.tryParse((raw['scheduled_date'] ?? '').toString()) ??
              DateTime.now(),
      status: status,
      checkInOpenedAt:
          DateTime.tryParse((raw['check_in_opened_at'] ?? '').toString()),
      checkInClosedAt:
          DateTime.tryParse((raw['check_in_closed_at'] ?? '').toString()),
      checkOutOpenedAt:
          DateTime.tryParse((raw['check_out_opened_at'] ?? '').toString()),
      checkOutClosedAt:
          DateTime.tryParse((raw['check_out_closed_at'] ?? '').toString()),
      classroomLatitude: (raw['classroom_latitude'] ?? 0.0).toDouble(),
      classroomLongitude: (raw['classroom_longitude'] ?? 0.0).toDouble(),
    );
  }

  String _formatSessionTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ExportSummary {
  final AttendanceSession session;
  final List<AttendanceRecord> records;
  final String course;
  final String date;
  final String lecturer;
  final String courseDelegate;
  final String classType;
  final String startTime;
  final String endTime;
  final String attendance;

  const _ExportSummary({
    required this.session,
    required this.records,
    required this.course,
    required this.date,
    required this.lecturer,
    required this.courseDelegate,
    required this.classType,
    required this.startTime,
    required this.endTime,
    required this.attendance,
  });
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: color,
                              fontSize: 14)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.download_outlined, color: color),
              ],
            ),
          ),
        ),
      );
}
