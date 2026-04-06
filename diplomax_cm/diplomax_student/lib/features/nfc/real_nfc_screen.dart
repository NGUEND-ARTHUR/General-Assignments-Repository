// ═══════════════════════════════════════════════════════════════════════════
// DIPLOMAX CM — Real NFC Screen
// Uses nfc_manager package to read NDEF records from physical diploma chips
// and verify the embedded hash against the blockchain.
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

const _green = Color(0xFF0F6E56);
const _greenLight = Color(0xFFE1F5EE);
const _blue = Color(0xFF185FA5);
const _blueLight = Color(0xFFE6F1FB);
const _red = Color(0xFFA32D2D);
const _redLight = Color(0xFFFCEBEB);
const _bg = Color(0xFFF7F6F2);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE0DDD5);
const _textPri = Color(0xFF1A1A1A);
const _textSec = Color(0xFF6B6B6B);

enum _NfcMode { read, write }

enum _NfcState { idle, scanning, processing, success, error, unsupported }

class NfcResult {
  final bool authentic;
  final String? documentId;
  final String? title;
  final String? studentName;
  final String? matricule;
  final String? university;
  final String? mention;
  final String? issueDate;
  final String? hashSha256;
  final bool? blockchainAuthentic;
  final String? nfcUid;
  final String? errorMessage;

  const NfcResult({
    required this.authentic,
    this.documentId,
    this.title,
    this.studentName,
    this.matricule,
    this.university,
    this.mention,
    this.issueDate,
    this.hashSha256,
    this.blockchainAuthentic,
    this.nfcUid,
    this.errorMessage,
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

class NfcService {
  final Dio _dio;
  NfcService(this._dio);

  /// Checks if this device supports NFC.
  Future<bool> isAvailable() => NfcManager.instance.isAvailable();

  /// Starts a real NFC session.
  /// On iOS: shows the system NFC sheet.
  /// On Android: listens for NFC tags in the background.
  ///
  /// Reads the NDEF record from the diploma chip, extracts the
  /// Diplomax payload (document_id + hash), and verifies on the blockchain.
  Future<NfcResult> readDiplomaChip() async {
    final completer = _Completer<NfcResult>();

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // Stop scanning after first tag
          await NfcManager.instance.stopSession();

          // Get the tag identifier (UID)
          final uid = _extractUid(tag);

          // Try to read NDEF data from the chip
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            completer.complete(NfcResult(
              authentic: false,
              nfcUid: uid,
              errorMessage: 'This NFC chip does not contain NDEF data. '
                  'It may not be a Diplomax-registered diploma.',
            ));
            return;
          }

          final cached = ndef.cachedMessage;
          if (cached == null || cached.records.isEmpty) {
            completer.complete(NfcResult(
              authentic: false,
              nfcUid: uid,
              errorMessage: 'NFC chip is empty or unreadable.',
            ));
            return;
          }

          // Parse the NDEF text record
          final payload = _parseNdefText(cached.records.first);
          if (payload == null) {
            completer.complete(NfcResult(
              authentic: false,
              nfcUid: uid,
              errorMessage: 'Could not parse NFC chip data.',
            ));
            return;
          }

          // Payload format: "diplomax:v1:{document_id}:{hash_sha256}"
          final parts = payload.split(':');
          if (parts.length < 4 || parts[0] != 'diplomax') {
            // Try verifying by UID if no Diplomax payload
            final result = await _verifyByUid(uid);
            completer.complete(result);
            return;
          }

          final documentId = parts[2];
          final hashSha256 = parts[3];

          // Verify against our backend (which queries the blockchain)
          final result = await _verifyByHash(documentId, hashSha256, uid);
          completer.complete(result);
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: 'Read error');
          completer.complete(NfcResult(
            authentic: false,
            errorMessage: 'NFC read error: ${e.toString()}',
          ));
        }
      },
      // iOS: shown in the system NFC modal
      alertMessage: 'Hold the diploma near your phone',
    );

    return completer.future;
  }

  /// Writes a Diplomax NDEF record to an NFC chip.
  /// Used by the university app to register chips on physical diplomas.
  Future<bool> writeDiplomaChip({
    required String documentId,
    required String hashSha256,
  }) async {
    final completer = _Completer<bool>();
    final payload = 'diplomax:v1:$documentId:$hashSha256';

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          await NfcManager.instance
              .stopSession(errorMessage: 'This NFC chip is not writable');
          completer.complete(false);
          return;
        }

        try {
          final record = NdefRecord.createText(payload);
          final message = NdefMessage([record]);
          await ndef.write(message);
          await NfcManager.instance.stopSession();
          completer.complete(true);
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: 'Write failed');
          completer.complete(false);
        }
      },
      alertMessage: 'Hold the NFC chip near your phone to program it',
    );

    return completer.future;
  }

  Future<void> stopSession() => NfcManager.instance.stopSession();

  // ── Private helpers ──────────────────────────────────────────────────────

  String? _extractUid(NfcTag tag) {
    final data = tag.data;
    // Try common UID fields across tag types
    final uid = data['nfca']?['identifier'] ??
        data['nfcb']?['applicationData'] ??
        data['nfcf']?['identifier'] ??
        data['iso15693']?['identifier'];
    if (uid is List) {
      return (uid as List<int>)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':')
          .toUpperCase();
    }
    return null;
  }

  String? _parseNdefText(NdefRecord record) {
    try {
      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
        final payload = record.payload;
        // NDEF Text record: first byte = status, next N = language code, rest = text
        final languageCodeLength = payload[0] & 0x3F;
        final text = utf8.decode(payload.sublist(1 + languageCodeLength));
        return text;
      }
      // Try raw UTF-8
      return utf8.decode(record.payload);
    } catch (_) {
      return null;
    }
  }

  Future<NfcResult> _verifyByUid(String? uid) async {
    if (uid == null) {
      return const NfcResult(
          authentic: false, errorMessage: 'No NFC UID found');
    }
    try {
      final response = await _dio.get('/nfc/verify/${uid.replaceAll(':', '')}');
      final d = response.data as Map<String, dynamic>;
      return NfcResult(
        authentic: d['found'] == true,
        documentId: d['document_id'],
        title: d['title'],
        studentName: d['student_name'],
        matricule: d['matricule'],
        university: d['university'],
        mention: d['mention'],
        issueDate: d['issue_date'],
        hashSha256: d['hash_sha256'],
        blockchainAuthentic: d['blockchain_authentic'],
        nfcUid: uid,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return NfcResult(
          authentic: false,
          nfcUid: uid,
          errorMessage: 'This NFC chip is not registered in Diplomax CM.',
        );
      }
      return NfcResult(
          authentic: false, nfcUid: uid, errorMessage: 'Verification failed');
    }
  }

  Future<NfcResult> _verifyByHash(
      String documentId, String hashSha256, String? uid) async {
    try {
      final response = await _dio.get(
        '/blockchain/verify/$documentId',
        queryParameters: {'hash': hashSha256},
      );
      final d = response.data as Map<String, dynamic>;

      // Also fetch document details
      Map<String, dynamic>? doc;
      try {
        final dr = await _dio.get('/documents/$documentId');
        doc = dr.data as Map<String, dynamic>;
      } catch (_) {}

      return NfcResult(
        authentic: d['is_authentic'] == true,
        documentId: documentId,
        title: doc?['title'],
        studentName: doc?['student_name'],
        matricule: doc?['matricule'],
        university: doc?['university'],
        mention: doc?['mention'],
        issueDate: doc?['issue_date'],
        hashSha256: hashSha256,
        blockchainAuthentic: d['is_authentic'],
        nfcUid: uid,
      );
    } catch (e) {
      return NfcResult(
        authentic: false,
        nfcUid: uid,
        errorMessage: 'Blockchain verification failed: ${e.toString()}',
      );
    }
  }
}

// Simple async completer wrapper
class _Completer<T> {
  late T _value;
  bool _completed = false;
  final _listeners = <void Function(T)>[];
  void complete(T v) {
    _value = v;
    _completed = true;
    for (final l in _listeners) {
      l(v);
    }
  }

  Future<T> get future => Future.microtask(() async {
        while (!_completed) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        return _value;
      });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class RealNfcScreen extends ConsumerStatefulWidget {
  const RealNfcScreen({super.key});
  @override
  ConsumerState<RealNfcScreen> createState() => _RealNfcState();
}

class _RealNfcState extends ConsumerState<RealNfcScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _wave;
  _NfcState _state = _NfcState.idle;
  NfcResult? _result;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _wave =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _checkAvailability();
  }

  @override
  void dispose() {
    _wave.dispose();
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final avail = await NfcManager.instance.isAvailable();
    setState(() {
      _nfcAvailable = avail;
      _state = avail ? _NfcState.idle : _NfcState.unsupported;
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _state = _NfcState.scanning;
      _result = null;
    });
    final svc = NfcService(Dio()..options.baseUrl = kBaseUrl);
    final result = await svc.readDiplomaChip();
    setState(() {
      _result = result;
      _state = result.authentic ? _NfcState.success : _NfcState.error;
    });
  }

  Future<void> _reset() async {
    await NfcManager.instance.stopSession().catchError((_) {});
    setState(() {
      _state = _NfcState.idle;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading:
              BackButton(onPressed: () => context.go('/home'), color: _textPri),
          title: Text('NFC verification',
              style:
                  GoogleFonts.instrumentSerif(fontSize: 22, color: _textPri)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const Spacer(),
            _buildTitle(),
            const SizedBox(height: 48),
            _buildNfcRing(),
            const SizedBox(height: 40),
            if (_result != null) _buildResult(),
            const Spacer(),
            _buildAction(),
            const SizedBox(height: 20),
          ]),
        ),
      );

  Widget _buildTitle() {
    String title, sub;
    Color c = _textPri;
    switch (_state) {
      case _NfcState.idle:
        title = 'NFC diploma verification';
        sub =
            'Hold your physical diploma near the back of the phone to scan its chip.';
        break;
      case _NfcState.scanning:
        title = 'Scanning...';
        sub = 'Keep the diploma still against the back of the phone.';
        break;
      case _NfcState.processing:
        title = 'Verifying on blockchain...';
        sub = 'Querying Hyperledger Fabric. This takes a few seconds.';
        break;
      case _NfcState.success:
        title = 'Diploma authenticated';
        sub = 'This diploma is genuine and verified on the blockchain.';
        c = _green;
        break;
      case _NfcState.error:
        title = 'Verification failed';
        sub = _result?.errorMessage ??
            'This chip is not recognised by Diplomax CM.';
        c = _red;
        break;
      case _NfcState.unsupported:
        title = 'NFC not available';
        sub =
            'This device does not support NFC, or NFC is disabled in Settings.';
        c = const Color(0xFFBA7517);
        break;
    }
    return Column(children: [
      Text(title,
          textAlign: TextAlign.center,
          style: GoogleFonts.instrumentSerif(fontSize: 28, color: c)),
      const SizedBox(height: 10),
      Text(sub,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
              fontSize: 13,
              color: _textSec,
              fontWeight: FontWeight.w300,
              height: 1.6)),
    ]);
  }

  Widget _buildNfcRing() {
    final scanning = _state == _NfcState.scanning;
    final done = _state == _NfcState.success || _state == _NfcState.error;
    final color = _state == _NfcState.success
        ? _green
        : _state == _NfcState.error
            ? _red
            : _green;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(alignment: Alignment.center, children: [
        // Animated wave rings (only while scanning)
        if (scanning)
          ...List.generate(
              3,
              (i) => AnimatedBuilder(
                    animation: _wave,
                    builder: (_, __) {
                      final progress = (_wave.value + i / 3) % 1.0;
                      return Opacity(
                        opacity: (1 - progress) * 0.4,
                        child: Container(
                          width: 80 + progress * 140,
                          height: 80 + progress * 140,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _green, width: 1.5)),
                        ),
                      );
                    },
                  )),
        // Center circle
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 2.5)),
          child: Center(
              child: _state == _NfcState.scanning
                  ? const CircularProgressIndicator(
                      color: _green, strokeWidth: 2)
                  : Icon(
                      done
                          ? (_state == _NfcState.success
                              ? Icons.check_rounded
                              : Icons.close_rounded)
                          : Icons.nfc_rounded,
                      size: 52,
                      color: color)),
        ),
        // NFC UID badge (shown after scan)
        if (_result?.nfcUid != null)
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border)),
              child: Text('UID: ${_result!.nfcUid}',
                  style: GoogleFonts.dmSans(fontSize: 10, color: _textSec)),
            ),
          ),
      ]),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final authentic = r.authentic;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: authentic ? _greenLight : _redLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: authentic ? _green : _red, width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(authentic ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                color: authentic ? _green : _red, size: 20),
            const SizedBox(width: 8),
            Text(authentic ? 'Document authentic' : 'Verification failed',
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: authentic ? _green : _red)),
          ]),
          if (authentic) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFD3D1C7)),
            const SizedBox(height: 10),
            _row('Student', r.studentName ?? '—'),
            _row('Matricule', r.matricule ?? '—'),
            _row('Document', r.title ?? '—'),
            _row('University', r.university ?? '—'),
            _row('Mention', r.mention ?? '—'),
            _row('Issue date', r.issueDate ?? '—'),
            _row('Blockchain',
                r.blockchainAuthentic == true ? 'Verified ✓' : 'Not verified'),
          ],
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
            width: 90,
            child: Text(k,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _textSec,
                    fontWeight: FontWeight.w300))),
        Expanded(
            child: Text(v,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textPri))),
      ]));

  Widget _buildAction() {
    if (_state == _NfcState.unsupported) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.settings_rounded, size: 16),
        label: const Text('Open NFC settings'),
        style: OutlinedButton.styleFrom(
            foregroundColor: _green,
            side: const BorderSide(color: _green),
            minimumSize: const Size(double.infinity, 52)),
        onPressed: () {},
      );
    }
    if (_state == _NfcState.success || _state == _NfcState.error) {
      return Column(children: [
        ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Scan another chip'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
            onPressed: _reset),
        if (_state == _NfcState.success) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('View full document'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: _green),
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: () {
                if (_result?.documentId != null) {
                  context.go('/home/document/${_result!.documentId}');
                }
              }),
        ],
      ]);
    }
    return ElevatedButton.icon(
      icon: _state == _NfcState.scanning
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.nfc_rounded, size: 18),
      label:
          Text(_state == _NfcState.scanning ? 'Scanning...' : 'Start NFC scan'),
      style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52)),
      onPressed: _state == _NfcState.scanning ? null : _startScan,
    );
  }
}
