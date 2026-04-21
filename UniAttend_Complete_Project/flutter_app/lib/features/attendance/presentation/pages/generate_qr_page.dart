import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/api_service.dart';

class GenerateQrPage extends StatefulWidget {
  final String sessionId;
  const GenerateQrPage({super.key, required this.sessionId});

  @override
  State<GenerateQrPage> createState() => _GenerateQrPageState();
}

class _GenerateQrPageState extends State<GenerateQrPage> {
  late final ApiService _api;
  late Timer _timer;
  String _payload = '';
  String _sessionStatus = 'pending';
  int _secondsLeft = AppConstants.qrRotationSeconds;
  bool _isCheckOut = false;

  @override
  void initState() {
    super.initState();
    _api = GetIt.I<ApiService>();
    _loadSessionContext();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        _refreshQr();
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _loadSessionContext() async {
    try {
      final res = await _api.get('/sessions/${widget.sessionId}');
      final raw = res['session'];
      if (raw is Map<String, dynamic>) {
        final status = (raw['status'] ?? 'pending').toString();
        if (!mounted) return;
        setState(() => _sessionStatus = status);
        _refreshQr();
      }
    } catch (_) {
      // Keep fallback behavior if session context fetch fails.
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _refreshQr() {
    _loadQrFromServer();
  }

  Future<void> _loadQrFromServer() async {
    try {
      final phase = _isCheckOut ? 'checkout' : 'checkin';
      final response = await _api.get(
        '/sessions/${widget.sessionId}/qr',
        queryParameters: {'phase': phase},
      );
      final payload = (response['payload'] ?? '').toString();
      final expires = int.tryParse(
              (response['expires_in_seconds'] ?? AppConstants.qrRotationSeconds)
                  .toString()) ??
          AppConstants.qrRotationSeconds;
      if (!mounted) return;
      setState(() {
        _payload = payload;
        _secondsLeft = expires;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load QR code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsLeft / AppConstants.qrRotationSeconds;
    final isUrgent = _secondsLeft <= 10;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCheckOut ? 'Check-Out QR Code' : 'Check-In QR Code'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Phase toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _PhaseButton(
                      label: 'Session 1 — Check-In',
                      active: !_isCheckOut,
                      onTap: () {
                        setState(() => _isCheckOut = false);
                        _refreshQr();
                      },
                    ),
                    _PhaseButton(
                      label: 'Session 2 — Check-Out',
                      active: _isCheckOut,
                      onTap: () {
                        setState(() => _isCheckOut = true);
                        _refreshQr();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // QR Code card
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Session ${widget.sessionId.toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isCheckOut
                              ? 'End-of-class scan'
                              : 'Start-of-class scan',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Session status: $_sessionStatus',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const Spacer(),
                        // Rotating QR
                        QrImageView(
                          data: _payload,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppTheme.primaryNavy,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const Spacer(),
                        // Timer ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: isUrgent
                                    ? AppTheme.errorRed
                                    : AppTheme.successGreen,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '$_secondsLeft',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: isUrgent
                                        ? AppTheme.errorRed
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                const Text('sec',
                                    style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'QR rotates every ${AppConstants.qrRotationSeconds}s to prevent sharing',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sensor verification row
              const Row(
                children: [
                  _VerificationChip(icon: Icons.qr_code, label: 'Rotating QR'),
                  SizedBox(width: 8),
                  _VerificationChip(
                      icon: Icons.location_on, label: 'GPS Verified'),
                  SizedBox(width: 8),
                  _VerificationChip(
                      icon: Icons.phone_android, label: 'Device Lock'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PhaseButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryNavy : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
}

class _VerificationChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _VerificationChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: AppTheme.successGreen),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
