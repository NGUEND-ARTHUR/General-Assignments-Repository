// ═══════════════════════════════════════════════════════════════════════════
// DIPLOMAX CM — University Document Input Hub
// Entry point that routes to all 5 input methods:
//   1. Manual form (field by field)
//   2. PDF scan (OCR extracts from existing PDF)
//   3. CSV bulk import (multiple students at once)
//   4. Photo / camera scan (OCR from photo)
//   5. Template fill (pre-filled form for common document types)
// ═══════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _green = Color(0xFF0F6E56);
const _greenLight = Color(0xFFE1F5EE);
const _blue = Color(0xFF185FA5);
const _blueLight = Color(0xFFE6F1FB);
const _amber = Color(0xFFBA7517);
const _amberLight = Color(0xFFFAEEDA);
const _purple = Color(0xFF534AB7);
const _purpleLight = Color(0xFFEEEDFE);
const _coral = Color(0xFF993C1D);
const _coralLight = Color(0xFFFAECE7);
const _bg = Color(0xFFF7F6F2);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE0DDD5);
const _textPri = Color(0xFF1A1A1A);
const _textSec = Color(0xFF6B6B6B);

class DocumentInputHubScreen extends StatelessWidget {
  const DocumentInputHubScreen({super.key});

  static const _methods = [
    _InputMethod(
      icon: Icons.edit_note_rounded,
      title: 'Manual form',
      subtitle: 'Enter all fields by hand — the most precise method',
      color: _green,
      bgColor: _greenLight,
      route: '/issue/form',
      badge: null,
    ),
    _InputMethod(
      icon: Icons.picture_as_pdf_rounded,
      title: 'Scan existing PDF',
      subtitle:
          'Upload an existing university PDF — OCR extracts all fields automatically',
      color: _blue,
      bgColor: _blueLight,
      route: '/issue/pdf-scan',
      badge: 'OCR',
    ),
    _InputMethod(
      icon: Icons.table_chart_rounded,
      title: 'CSV bulk import',
      subtitle: 'Import a spreadsheet of multiple students at once',
      color: _amber,
      bgColor: _amberLight,
      route: '/issue/csv',
      badge: 'Bulk',
    ),
    _InputMethod(
      icon: Icons.camera_alt_rounded,
      title: 'Camera / photo scan',
      subtitle: 'Take a photo of a paper document — OCR reads it live',
      color: _purple,
      bgColor: _purpleLight,
      route: '/issue/photo',
      badge: 'Camera',
    ),
    _InputMethod(
      icon: Icons.description_rounded,
      title: 'Fill a template',
      subtitle:
          'Choose a standard document type and fill only the student-specific fields',
      color: _coral,
      bgColor: _coralLight,
      route: '/issue/template',
      badge: 'Quick',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Issue a document',
              style:
                  GoogleFonts.instrumentSerif(fontSize: 22, color: _textPri)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: _greenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _green.withOpacity(0.25))),
                  child: Row(children: [
                    const Icon(Icons.info_rounded, color: _green, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            'Choose how you want to enter the document data. '
                            'All methods produce the same cryptographically signed result.',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: _green, height: 1.5))),
                  ])),
              const SizedBox(height: 20),
              Text('Input methods',
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textPri)),
              const SizedBox(height: 12),
              ..._methods.map((m) => _MethodCard(method: m)),
            ],
          ),
        ),
      );
}

class _InputMethod {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final String route;
  final String? badge;
  const _InputMethod({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.route,
    this.badge,
  });
}

class _MethodCard extends StatelessWidget {
  final _InputMethod method;
  const _MethodCard({required this.method});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go(method.route),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]),
          child: Row(children: [
            Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: method.bgColor,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(method.icon, color: method.color, size: 26)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text(method.title,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textPri)),
                    if (method.badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: method.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(method.badge!,
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: method.color))),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(method.subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _textSec,
                          fontWeight: FontWeight.w300,
                          height: 1.4)),
                ])),
            Icon(Icons.chevron_right_rounded,
                color: _textSec.withOpacity(0.4), size: 20),
          ]),
        ),
      );
}
