import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../bloc/attendance_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class ScanQrPage extends StatefulWidget {
  final String sessionId;
  const ScanQrPage({super.key, required this.sessionId});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  late final AttendanceBloc _bloc;
  bool _scanned = false;
  bool _isCheckOut = false;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.I<AttendanceBloc>();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _scanned = true;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (_isCheckOut) {
      _bloc.add(ScanAndCheckOut(
        qrPayload: barcode!.rawValue!,
        expectedSessionId: widget.sessionId,
        user: authState.user,
      ));
    } else {
      _bloc.add(ScanAndCheckIn(
        qrPayload: barcode!.rawValue!,
        expectedSessionId: widget.sessionId,
        user: authState.user,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceCheckInSuccess) {
            _showResult(
              context,
              success: true,
              title: 'Checked In!',
              message:
                  'Check-in recorded at ${TimeOfDay.fromDateTime(state.record.checkInTime!).format(context)}.\nRemember to scan again at the end of class.',
            );
          } else if (state is AttendanceCheckOutSuccess) {
            _showResult(
              context,
              success: true,
              title: 'Checked Out!',
              message: 'You are marked PRESENT for this class. Well done!',
            );
          } else if (state is AttendanceError) {
            setState(() => _scanned = false);
            _showResult(
              context,
              success: false,
              title: 'Error',
              message: state.message,
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isCheckOut ? 'Check-Out Scan' : 'Check-In Scan'),
            actions: [
              TextButton(
                onPressed: () => setState(() {
                  _isCheckOut = !_isCheckOut;
                  _scanned = false;
                }),
                child: Text(
                  _isCheckOut ? 'Switch to Check-In' : 'Switch to Check-Out',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Phase indicator
              Container(
                padding: const EdgeInsets.all(16),
                color: _isCheckOut
                    ? AppTheme.warningAmber.withOpacity(0.15)
                    : const Color(0xFFEFF6FF),
                child: Row(
                  children: [
                    Icon(
                      _isCheckOut ? Icons.logout : Icons.login,
                      color: _isCheckOut
                          ? AppTheme.warningAmber
                          : AppTheme.primaryNavy,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCheckOut
                                ? 'Session 2 — Check-Out'
                                : 'Session 1 — Check-In',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _isCheckOut
                                ? 'Scan the QR code at the end of class'
                                : 'Scan the QR code displayed by the course rep',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // QR Scanner viewport
              Expanded(
                child: BlocBuilder<AttendanceBloc, AttendanceState>(
                  builder: (context, state) {
                    if (state is AttendanceLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                                'Verifying location and recording attendance…'),
                          ],
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        MobileScanner(onDetect: _onDetect),
                        // Overlay frame
                        Center(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _isCheckOut
                                    ? AppTheme.warningAmber
                                    : AppTheme.primaryNavy,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 40,
                          left: 0,
                          right: 0,
                          child: Text(
                            'Align the QR code within the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 8)
                                ]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Sensor status bar
              _SensorStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  void _showResult(BuildContext context,
      {required bool success, required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error,
                color: success ? AppTheme.successGreen : AppTheme.errorRed),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SensorStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF0F172A),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SensorChip(icon: Icons.location_on, label: 'GPS', active: true),
          _SensorChip(icon: Icons.phone_android, label: 'Device', active: true),
          _SensorChip(
              icon: Icons.qr_code_scanner, label: 'Camera', active: true),
        ],
      ),
    );
  }
}

class _SensorChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _SensorChip(
      {required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: active ? AppTheme.successGreen : AppTheme.errorRed),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: active ? AppTheme.successGreen : AppTheme.errorRed)),
        ],
      );
}
