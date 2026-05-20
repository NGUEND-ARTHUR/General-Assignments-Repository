import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'web_download_helper_mobile.dart'
    if (dart.library.html) 'web_download_helper.dart';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class ExportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  /// Exports attendance records to an Excel (.xlsx) file matching
  /// the ICT Cameroon physical attendance sheet format.
  Future<dynamic> exportToExcel({
    required AttendanceSession session,
    required List<AttendanceRecord> records,
    required String lecturerName,
    String? courseDelegateName,
    String? startTimeLabel,
    String? endTimeLabel,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Attendance'];
    excel.setDefaultSheet('Attendance');

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );
    final subtitleStyle = CellStyle(
      bold: true,
      fontSize: 13,
      horizontalAlign: HorizontalAlign.Center,
    );
    final metaLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D9EAF7'),
      fontColorHex: ExcelColor.fromHexString('#0F172A'),
    );
    final metaValueStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
    );

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 15);
    sheet.setColumnWidth(7, 12);

    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value =
        TextCellValue('INFORMATION AND COMMUNICATION TECHNOLOGY UNIVERSITY');
    titleCell.cellStyle = titleStyle;
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('H1'));

    final titleCell2 = sheet.cell(CellIndex.indexByString('A2'));
    titleCell2.value = TextCellValue('ICT-U CAMEROON');
    titleCell2.cellStyle = subtitleStyle;
    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('H2'));

    final titleCell3 = sheet.cell(CellIndex.indexByString('A3'));
    titleCell3.value = TextCellValue('COURSE ATTENDANCE SHEET');
    titleCell3.cellStyle = subtitleStyle;
    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('H3'));

    _addMetaRow(sheet, 5, 'Course Name', session.courseName, metaLabelStyle,
        metaValueStyle);
    _addMetaRow(sheet, 6, 'Course Code', session.courseCode, metaLabelStyle,
        metaValueStyle);
    _addMetaRow(sheet, 7, 'Date', _dateFormat.format(session.scheduledDate),
        metaLabelStyle, metaValueStyle);
    _addMetaRow(
        sheet,
        8,
        'Class Type',
        session.classType == ClassType.normal
            ? 'Normal Class'
            : 'Catch-Up Class',
        metaLabelStyle,
        metaValueStyle);
    _addMetaRow(sheet, 9, 'Lecturer Name', lecturerName, metaLabelStyle,
        metaValueStyle);
    _addMetaRow(sheet, 10, 'Course Delegate', courseDelegateName ?? '-',
        metaLabelStyle, metaValueStyle);
    _addMetaRow(sheet, 11, 'Start Time', startTimeLabel ?? '-', metaLabelStyle,
        metaValueStyle);
    _addMetaRow(sheet, 12, 'End Time', endTimeLabel ?? '-', metaLabelStyle,
        metaValueStyle);

    // ── Column headers ────────────────────────────────────────────────
    final colHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#0F3460'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final cols = [
      'No.',
      'Full Name',
      'Matriculation No.',
      'Department',
      'Phone No.',
      'Check-In Time',
      'Check-Out Time',
      'Status'
    ];
    for (var i = 0; i < cols.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 14));
      cell.value = TextCellValue(cols[i]);
      cell.cellStyle = colHeaderStyle;
    }

    // ── Data rows ─────────────────────────────────────────────────────
    final presentStyle =
        CellStyle(backgroundColorHex: ExcelColor.fromHexString('#DCFCE7'));
    final absentStyle =
        CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FEE2E2'));
    final partialStyle =
        CellStyle(backgroundColorHex: ExcelColor.fromHexString('#FEF9C3'));

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final rowIndex = 15 + i;
      final statusStyle = record.status == AttendanceStatus.present
          ? presentStyle
          : record.status == AttendanceStatus.partial
              ? partialStyle
              : absentStyle;

      _setCellValue(sheet, rowIndex, 0, '${i + 1}', statusStyle);
      _setCellValue(sheet, rowIndex, 1, record.studentName, statusStyle);
      _setCellValue(sheet, rowIndex, 2, record.matricNumber, statusStyle);
      _setCellValue(sheet, rowIndex, 3, record.department, statusStyle);
      _setCellValue(sheet, rowIndex, 4,
          record.phoneNumber.isEmpty ? '-' : record.phoneNumber, statusStyle);
      _setCellValue(
          sheet,
          rowIndex,
          5,
          record.checkInTime != null
              ? _timeFormat.format(record.checkInTime!)
              : '—',
          statusStyle);
      _setCellValue(
          sheet,
          rowIndex,
          6,
          record.checkOutTime != null
              ? _timeFormat.format(record.checkOutTime!)
              : '—',
          statusStyle);
      _setCellValue(
          sheet, rowIndex, 7, record.status.name.toUpperCase(), statusStyle);
    }

    // ── Save file ─────────────────────────────────────────────────────
    final fileName =
        'attendance_${session.courseCode}_${_dateFormat.format(session.scheduledDate).replaceAll('/', '-')}.xlsx';
    final bytes = excel.save();
    if (bytes == null) return null;
    if (kIsWeb) {
      triggerWebDownload(bytes as Uint8List, fileName,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      return null;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    }
  }

  Future<dynamic> exportToCsv({
    required AttendanceSession session,
    required List<AttendanceRecord> records,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Course Code,Course Name,Session ID,Date');
    buffer.writeln(
        '${session.courseCode},${_escapeCsv(session.courseName)},${session.id},${_dateFormat.format(session.scheduledDate)}');
    buffer.writeln();
    buffer.writeln(
        'No,Full Name,Matriculation No.,Department,Phone No.,Check-In Time,Check-Out Time,Status');

    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      buffer.writeln(
        '${i + 1},${_escapeCsv(r.studentName)},${_escapeCsv(r.matricNumber)},${_escapeCsv(r.department)},${_escapeCsv(r.phoneNumber)},'
        '${r.checkInTime != null ? _timeFormat.format(r.checkInTime!) : ''},'
        '${r.checkOutTime != null ? _timeFormat.format(r.checkOutTime!) : ''},'
        '${r.status.name.toUpperCase()}',
      );
    }

    final fileName =
        'attendance_${session.courseCode}_${_dateFormat.format(session.scheduledDate).replaceAll('/', '-')}.csv';
    final csvBytes = utf8.encode(buffer.toString());
    if (kIsWeb) {
      triggerWebDownload(csvBytes as Uint8List, fileName, 'text/csv');
      return null;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString(), encoding: utf8);
      return file;
    }
  }

  Future<dynamic> exportToPdf({
    required AttendanceSession session,
    required List<AttendanceRecord> records,
    required String lecturerName,
    String? courseDelegateName,
    String? startTimeLabel,
    String? endTimeLabel,
  }) async {
    final doc = pw.Document();
    final logo = await _tryLoadLogo();

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(24),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border:
                  pw.Border.all(color: pdf.PdfColors.blueGrey900, width: 1.5),
            ),
            child: pw.Column(
              children: [
                if (logo != null) ...[
                  pw.Center(child: pw.Image(logo, width: 68, height: 68)),
                  pw.SizedBox(height: 6),
                ],
                pw.Text(
                  'INFORMATION AND COMMUNICATION TECHNOLOGY UNIVERSITY',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'ICT-U CAMEROON',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'COURSE ATTENDANCE SHEET',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(
                color: pdf.PdfColors.blueGrey100, width: 0.8),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(3.2),
              2: const pw.FlexColumnWidth(2.0),
              3: const pw.FlexColumnWidth(2.0),
            },
            children: [
              _pdfMetaRow('Course Name', session.courseName, 'Course Code',
                  session.courseCode),
              _pdfMetaRow(
                  'Date',
                  _dateFormat.format(session.scheduledDate),
                  'Class Type',
                  session.classType == ClassType.normal
                      ? 'Normal Class'
                      : 'Catch-Up Class'),
              _pdfMetaRow('Lecturer Name', lecturerName, 'Course Delegate',
                  courseDelegateName ?? '-'),
              _pdfMetaRow('Start Time', startTimeLabel ?? '-', 'End Time',
                  endTimeLabel ?? '-'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: const [
              'No',
              'Full Name',
              'Matric No',
              'Dept',
              'Phone No',
              'Check-In',
              'Check-Out',
              'Status'
            ],
            data: List.generate(records.length, (i) {
              final r = records[i];
              return [
                '${i + 1}',
                r.studentName,
                r.matricNumber,
                r.department,
                r.phoneNumber.isEmpty ? '-' : r.phoneNumber,
                r.checkInTime != null
                    ? _timeFormat.format(r.checkInTime!)
                    : '-',
                r.checkOutTime != null
                    ? _timeFormat.format(r.checkOutTime!)
                    : '-',
                r.status.name.toUpperCase(),
              ];
            }),
          ),
        ],
      ),
    );

    final fileName =
        'attendance_${session.courseCode}_${_dateFormat.format(session.scheduledDate).replaceAll('/', '-')}.pdf';
    final pdfBytes = await doc.save();
    if (kIsWeb) {
      triggerWebDownload(pdfBytes as Uint8List, fileName, 'application/pdf');
      return null;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file;
    }
  }

  void _addMetaRow(Sheet sheet, int row, String label, String value,
      CellStyle labelStyle, CellStyle valueStyle) {
    final labelCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    labelCell.value = TextCellValue(label);
    labelCell.cellStyle = labelStyle;

    final valueCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    valueCell.value = TextCellValue(value);
    valueCell.cellStyle = valueStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
    );
  }

  pw.TableRow _pdfMetaRow(String leftLabel, String leftValue, String rightLabel,
      String rightValue) {
    pw.Widget cell(String label, String value, {bool isLabel = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.RichText(
          text: pw.TextSpan(
            style: const pw.TextStyle(fontSize: 10, color: pdf.PdfColors.black),
            children: [
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: value),
            ],
          ),
        ),
      );
    }

    return pw.TableRow(
      children: [
        cell(leftLabel, leftValue),
        cell('', '', isLabel: false),
        cell(rightLabel, rightValue),
        cell('', '', isLabel: false),
      ],
    );
  }

  void _setCellValue(
      Sheet sheet, int row, int col, String value, CellStyle style) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = style;
  }

  Future<void> shareFile(dynamic file) async {
    if (kIsWeb || file == null) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Attendance Sheet');
  }

  Future<pw.MemoryImage?> _tryLoadLogo() async {
    const candidates = [
      'assets/images/R.png',
      'assets/images/ictu_logo.png',
      'assets/icons/ictu_logo.png',
      'assets/images/logo.png',
      'assets/icons/logo.png',
    ];

    for (final assetPath in candidates) {
      try {
        final data = await rootBundle.load(assetPath);
        return pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  String _escapeCsv(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}
