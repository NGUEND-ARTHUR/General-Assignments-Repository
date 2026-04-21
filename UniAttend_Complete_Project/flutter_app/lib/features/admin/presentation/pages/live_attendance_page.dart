import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';

class LiveAttendancePage extends StatefulWidget {
  final String sessionId;
  const LiveAttendancePage({super.key, required this.sessionId});

  @override
  State<LiveAttendancePage> createState() => _LiveAttendancePageState();
}

class _LiveAttendancePageState extends State<LiveAttendancePage> {
  late final AttendanceBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.I<AttendanceBloc>();
    _bloc.add(LoadSessionAttendance(widget.sessionId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Attendance'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  _bloc.add(LoadSessionAttendance(widget.sessionId)),
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: () => context.push('/export/${widget.sessionId}'),
            ),
          ],
        ),
        body: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            if (state is AttendanceLoading || state is AttendanceInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AttendanceLoaded) {
              final records = state.records;
              final present = records
                  .where((r) => r.status == AttendanceStatus.present)
                  .length;
              final absent = records
                  .where((r) => r.status == AttendanceStatus.absent)
                  .length;
              final partial = records
                  .where((r) => r.status == AttendanceStatus.partial)
                  .length;
              final manual = records.where((r) => r.manualAdded).length;

              return Column(
                children: [
                  // Stats header
                  Container(
                    color: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _LiveStat(
                            label: 'Present',
                            value: present,
                            color: AppTheme.successGreen),
                        _LiveStat(
                            label: 'Partial',
                            value: partial,
                            color: AppTheme.warningAmber),
                        _LiveStat(
                            label: 'Absent',
                            value: absent,
                            color: AppTheme.errorRed),
                        _LiveStat(
                            label: 'Total',
                            value: records.length,
                            color: Colors.white),
                        _LiveStat(
                            label: 'Manual',
                            value: manual,
                            color: const Color(0xFFF97316)),
                      ],
                    ),
                  ),
                  // Legend
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      children: [
                        _LegendDot(
                            color: AppTheme.successGreen, label: 'In + Out'),
                        SizedBox(width: 12),
                        _LegendDot(
                            color: AppTheme.warningAmber, label: 'In only'),
                        SizedBox(width: 12),
                        _LegendDot(color: Color(0xFFE2E8F0), label: 'Absent'),
                        SizedBox(width: 12),
                        _LegendDot(
                            color: Color(0xFFF97316), label: 'Manual add'),
                      ],
                    ),
                  ),
                  // List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: records.length,
                      itemBuilder: (context, i) {
                        final r = records[i];
                        return _AttendanceRow(index: i + 1, record: r);
                      },
                    ),
                  ),
                ],
              );
            }
            return const Center(child: Text('No data'));
          },
        ),
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _LiveStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );
}

class _AttendanceRow extends StatelessWidget {
  final int index;
  final AttendanceRecord record;
  const _AttendanceRow({required this.index, required this.record});

  @override
  Widget build(BuildContext context) {
    Color checkInColor, checkOutColor;
    switch (record.status) {
      case AttendanceStatus.present:
        checkInColor = AppTheme.successGreen;
        checkOutColor = AppTheme.successGreen;
        break;
      case AttendanceStatus.partial:
        checkInColor = AppTheme.successGreen;
        checkOutColor = const Color(0xFFE2E8F0);
        break;
      case AttendanceStatus.absent:
        checkInColor = const Color(0xFFE2E8F0);
        checkOutColor = const Color(0xFFE2E8F0);
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('$index',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ),
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryNavy.withOpacity(0.15),
              child: Text(
                record.studentName.isNotEmpty ? record.studentName[0] : '?',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.studentName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${record.matricNumber}  •  ${record.department}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary)),
                  if (record.manualAdded) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Manually added by ${record.manualAddedByName ?? 'admin'}${record.manualReason != null && record.manualReason!.isNotEmpty ? ' • ${record.manualReason}' : ''}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Check-in / check-out dots
            Row(
              children: [
                _AttendanceDot(color: checkInColor, tooltip: 'Check-In'),
                const SizedBox(width: 4),
                _AttendanceDot(color: checkOutColor, tooltip: 'Check-Out'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceDot extends StatelessWidget {
  final Color color;
  final String tooltip;
  const _AttendanceDot({required this.color, required this.tooltip});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}
