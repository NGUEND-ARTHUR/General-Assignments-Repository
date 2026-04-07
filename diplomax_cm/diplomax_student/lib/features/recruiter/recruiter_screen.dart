import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/api/student_documents_api.dart';

class RecruiterScreen extends StatefulWidget {
  const RecruiterScreen({super.key});
  @override
  State<RecruiterScreen> createState() => _RecruiterState();
}

class _RecruiterState extends State<RecruiterScreen>
    with SingleTickerProviderStateMixin {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final _shareApi = ApiClient();
  final _api = StudentDocumentsApi.instance;
  final _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final _tokenCtrl = TextEditingController();
  late AnimationController _scanCtrl;
  _RecStep _step = _RecStep.idle;
  bool _valid = false;
  bool _autoScanLocked = false;
  String? _error;
  String _studentName = 'Étudiant';
  String _matricule = '—';
  Map<String, dynamic>? _previewDoc;
  Map<String, dynamic>? _verifiedShareData;

  @override
  void initState() {
    super.initState();
    _loadPreviewData();
    _scanCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  Future<void> _loadPreviewData() async {
    final storedName = await _storage.read(key: 'student_name');
    final storedMat = await _storage.read(key: 'matricule');
    try {
      final docs = await _api.fetchDocuments(pageSize: 1);
      if (!mounted) return;
      setState(() {
        _studentName = (storedName != null && storedName.trim().isNotEmpty)
            ? storedName
            : 'Étudiant';
        _matricule = (storedMat != null && storedMat.trim().isNotEmpty)
            ? storedMat
            : '—';
        _previewDoc = docs.isNotEmpty ? docs.first : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _studentName = (storedName != null && storedName.trim().isNotEmpty)
            ? storedName
            : 'Étudiant';
        _matricule = (storedMat != null && storedMat.trim().isNotEmpty)
            ? storedMat
            : '—';
      });
    }
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _tokenCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan([String? rawInput]) async {
    final token = _extractToken(rawInput ?? _tokenCtrl.text);
    if (token.isEmpty) {
      setState(() {
        _error = 'Entrez un token ou un lien de partage valide.';
      });
      return;
    }

    setState(() {
      _step = _RecStep.scanning;
      _valid = false;
      _error = null;
      _verifiedShareData = null;
      _autoScanLocked = true;
    });

    try {
      setState(() => _step = _RecStep.checking);

      final previewRes = await _shareApi.dio.get('/shares/$token/preview');
      final preview = Map<String, dynamic>.from(previewRes.data as Map);

      final verificationMode =
          (preview['verification_mode'] ?? 'liveness').toString().toLowerCase();

      Map<String, dynamic> access;
      if (verificationMode == 'liveness') {
        final startRes = await _shareApi.dio
            .post('/liveness/start', queryParameters: {'share_token': token});
        final sessionId = (startRes.data['session_id'] ?? '').toString();
        if (sessionId.isEmpty) throw Exception('Session liveness invalide');

        final challenges =
            (startRes.data['challenges'] as List?)?.whereType<Map>().toList() ??
                const [];

        for (int i = 0; i < challenges.length; i++) {
          final challenge = Map<String, dynamic>.from(challenges[i]);
          final step = (challenge['step'] as num?)?.toInt() ?? (i + 1);
          final axis = (challenge['axis'] ?? 'y').toString();
          final direction = (challenge['direction'] ?? 'right').toString();
          final threshold = (challenge['threshold'] as num?)?.toDouble() ?? 0.6;
          final instruction =
              (challenge['instruction'] ?? 'Effectuez le mouvement demandé')
                  .toString();

          final proceed = await _confirmChallenge(instruction);
          if (!proceed) {
            throw Exception('Vérification annulée');
          }

          final evidence = await _captureMotionEvidence(
            axis: axis,
            direction: direction,
            threshold: threshold,
          );

          await _shareApi.dio.post(
            '/liveness/$sessionId/challenge/$step',
            data: {
              'detected': evidence.detected,
              'sensor_variance': evidence.variance,
            },
          );

          if (!evidence.detected) {
            throw Exception('Mouvement non détecté au challenge $step');
          }
        }

        final accessRes = await _shareApi.dio.get('/shares/$token/access',
            queryParameters: {'liveness_session_id': sessionId});
        access = Map<String, dynamic>.from(accessRes.data as Map);
      } else {
        final accessRes = await _shareApi.dio.get('/shares/$token/access');
        access = Map<String, dynamic>.from(accessRes.data as Map);
      }

      if (!mounted) return;
      setState(() {
        _step = _RecStep.result;
        _valid = true;
        _verifiedShareData = access;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _RecStep.result;
        _valid = false;
        _error = 'Vérification impossible: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _autoScanLocked = false;
      });
    }
  }

  Future<bool> _confirmChallenge(String instruction) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Challenge liveness', style: GoogleFonts.dmSans()),
        content: Text(
          instruction,
          style: GoogleFonts.dmSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<_MotionEvidence> _captureMotionEvidence({
    required String axis,
    required String direction,
    required double threshold,
    Duration duration = const Duration(milliseconds: 1500),
  }) async {
    final values = <double>[];
    StreamSubscription<GyroscopeEvent>? sub;

    sub = gyroscopeEventStream().listen((event) {
      final value = switch (axis.toLowerCase()) {
        'x' => event.x,
        'y' => event.y,
        'z' => event.z,
        _ => event.y,
      };
      values.add(value);
    });

    await Future.delayed(duration);
    await sub.cancel();

    if (values.isEmpty) {
      return const _MotionEvidence(detected: false, variance: 0);
    }

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final maxAbs = values.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);

    final detected = switch (direction.toLowerCase()) {
      'right' => max >= threshold,
      'down' => max >= threshold,
      'left' => min <= -threshold,
      _ => maxAbs >= threshold,
    };

    return _MotionEvidence(detected: detected, variance: variance);
  }

  Future<String?> _askToken() async {
    final ctrl = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Entrer le token/lien', style: GoogleFonts.dmSans()),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'https://verify.diplomax.cm/s/<token>',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _extractToken(ctrl.text)),
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return token;
  }

  String _extractToken(String input) {
    final value = input.trim();
    if (value.isEmpty) return '';
    if (!value.contains('/')) return value;
    try {
      final uri = Uri.parse(value);
      final segs = uri.pathSegments;
      if (segs.isNotEmpty) return segs.last;
      return value;
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text('Espace Recruteur',
            style: GoogleFonts.instrumentSerif(fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.business_rounded,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text('Mode vérification recruteur',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scanner area
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MobileScanner(
                      controller: _scannerCtrl,
                      onDetect: (capture) {
                        if (_step == _RecStep.checking || _autoScanLocked) {
                          return;
                        }
                        final raw = capture.barcodes
                            .map((b) => b.rawValue)
                            .whereType<String>()
                            .firstWhere(
                              (v) => v.trim().isNotEmpty,
                              orElse: () => '',
                            );
                        if (raw.isEmpty) return;
                        _tokenCtrl.text = raw;
                        _scan(raw);
                      },
                    ),
                  ),
                  if (_step == _RecStep.scanning)
                    AnimatedBuilder(
                      animation: _scanCtrl,
                      builder: (_, __) => Positioned(
                        top: _scanCtrl.value * 220,
                        left: 20,
                        right: 20,
                        child: Container(
                            height: 2,
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                              Colors.transparent,
                              AppColors.accent,
                              Colors.transparent
                            ]))),
                      ),
                    ),
                  Center(child: _scannerCenter()),
                  ..._corners(),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _tokenCtrl,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Token ou lien https://verify.../s/<token>',
                    ),
                  ),
                  if (_error != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: GoogleFonts.dmSans(
                            fontSize: 10, color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Checks during verification
            if (_step == _RecStep.checking) _checkingCard(),

            // Result
            if (_step == _RecStep.result && _valid) ...[
              _resultCard(),
              const SizedBox(height: 16),
              _livenessCheck(),
            ],

            // Actions when idle
            if (_step == _RecStep.idle) ...[
              const SizedBox(height: 4),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Scanner le QR Code du candidat'),
                onPressed: () => _scan(_tokenCtrl.text),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Vérifier via lien de partage'),
                onPressed: () async {
                  final token = await _askToken();
                  if (token == null || token.isEmpty) return;
                  _tokenCtrl.text = token;
                  _scan(token);
                },
              ),
            ],

            if (_step == _RecStep.result && _valid) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Nouvelle vérification'),
                onPressed: () => setState(() {
                  _step = _RecStep.idle;
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scannerCenter() {
    switch (_step) {
      case _RecStep.idle:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.qr_code_2_rounded, color: Colors.white38, size: 52),
          const SizedBox(height: 10),
          Text('Pointez vers le QR Code ou collez un lien',
              style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
        ]);
      case _RecStep.scanning:
        return Text('Lecture...',
            style: GoogleFonts.dmSans(color: AppColors.accent, fontSize: 13));
      case _RecStep.checking:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2),
          const SizedBox(height: 12),
          Text('Vérification serveur...',
              style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
        ]);
      case _RecStep.result:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_valid ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 60, color: _valid ? AppColors.success : AppColors.error),
          const SizedBox(height: 8),
          Text(_valid ? 'Document authentique' : 'Document invalide',
              style: GoogleFonts.dmSans(
                  color: _valid ? AppColors.success : AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          if (!_valid && _error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ]
        ]);
    }
  }

  Widget _checkingCard() {
    final checks = [
      'Lecture du QR Code',
      'Requête serveur universitaire',
      'Vérification hash cryptographique',
      'Contrôle liste noire'
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Column(
        children: checks
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.primary
                                .withOpacity(0.4 + e.key * 0.2))),
                    const SizedBox(width: 12),
                    Text(e.value,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                ))
            .toList(),
      ),
    );
  }

  Widget _resultCard() {
    final doc = _verifiedShareData ?? _previewDoc;
    final title = doc?['title'] as String? ?? 'Document académique';
    final university =
        (doc?['university'] ?? doc?['university_name'] ?? 'Université')
            .toString();
    final mention = doc?['mention'] as String? ?? '—';
    final issueYear = _issueYear(doc?['issue_date'] as String?);
    final hash = doc?['hash_sha256'] as String? ?? '';
    final holder = (doc?['student_name'] as String?) ?? _studentName;
    final matricule = (doc?['matricule'] as String?) ?? _matricule;
    final shortHash = hash.isEmpty
        ? 'Hash indisponible'
        : (hash.length > 44 ? '${hash.substring(0, 44)}...' : hash);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.verified_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text('Document vérifié en temps réel',
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          _infoRow('Titulaire', holder),
          _infoRow('Matricule', matricule),
          _infoRow('Diplôme', title),
          _infoRow('Université', university),
          _infoRow('Mention', mention),
          _infoRow('Année', issueYear),
          _infoRow('Statut', 'Authentique — Non modifié'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.tag_rounded,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(shortHash,
                      style: GoogleFonts.dmSans(
                          fontSize: 10, color: AppColors.textHint))),
            ]),
          ),
        ],
      ),
    );
  }

  String _issueYear(String? issueDate) {
    final parsed = DateTime.tryParse(issueDate ?? '');
    return parsed == null ? '—' : '${parsed.year}';
  }

  Widget _livenessCheck() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vérification biométrique candidat',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.warning)),
          const SizedBox(height: 8),
          Text(
              'Demandez au candidat de confirmer son identité via selfie vidéo pour un contrôle biométrique complet.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.warning, height: 1.5)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.videocam_rounded, size: 16),
            label: const Text('Lancer la vérification Liveness'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              minimumSize: const Size(double.infinity, 40),
            ),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(
              width: 90,
              child: Text(k,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w300))),
          Expanded(
              child: Text(v,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w500))),
        ]),
      );

  List<Widget> _corners() {
    const c = AppColors.accent;
    const s = 24.0;
    const t = 2.0;
    return [
      Positioned(top: 14, left: 14, child: _corner(c, s, t, true, true)),
      Positioned(top: 14, right: 14, child: _corner(c, s, t, true, false)),
      Positioned(bottom: 14, left: 14, child: _corner(c, s, t, false, true)),
      Positioned(bottom: 14, right: 14, child: _corner(c, s, t, false, false)),
    ];
  }

  Widget _corner(Color c, double s, double t, bool top, bool left) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
            border: Border(
          top: top ? BorderSide(color: c, width: t) : BorderSide.none,
          bottom: !top ? BorderSide(color: c, width: t) : BorderSide.none,
          left: left ? BorderSide(color: c, width: t) : BorderSide.none,
          right: !left ? BorderSide(color: c, width: t) : BorderSide.none,
        )),
      );
}

enum _RecStep { idle, scanning, checking, result }

class _MotionEvidence {
  final bool detected;
  final double variance;

  const _MotionEvidence({required this.detected, required this.variance});
}
