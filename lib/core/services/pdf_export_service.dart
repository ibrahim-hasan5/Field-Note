import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/field_notes/models/field_note_model.dart';

/// Generates a PDF report for a [FieldNoteModel] and shares / previews it.
class PdfExportService {
  /// Generate PDF and share it (mobile / desktop).
  /// On web, opens the PDF in a print-preview dialog via [Printing].
  static Future<void> exportAndShare(FieldNoteModel note) async {
    final pdf = await _buildPdf(note);
    final bytes = await pdf.save();

    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) => bytes);
      return;
    }

    final dir = await getTemporaryDirectory();
    final safeTitle = note.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final file = File('${dir.path}/FieldNote_$safeTitle.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Field Note Report: ${note.title}',
    );
  }

  /// Generate PDF and open the platform print dialog.
  static Future<void> printNote(FieldNoteModel note) async {
    final pdf = await _buildPdf(note);
    final bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  static Future<pw.Document> _buildPdf(FieldNoteModel note) async {
    final pdf = pw.Document();

    // Resolved values
    final parsedDate = DateTime.tryParse(note.noteDate) ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(parsedDate);
    final formattedTime = DateFormat('hh:mm a').format(parsedDate);
    final generatedAt = DateFormat('MMM dd yyyy, hh:mm a').format(DateTime.now());

    // Status color mapping
    PdfColor statusColor;
    switch (note.status) {
      case 'COMPLETED':
        statusColor = const PdfColor.fromInt(0xFF10B981);
        break;
      case 'IN_PROGRESS':
        statusColor = const PdfColor.fromInt(0xFF2563EB);
        break;
      default:
        statusColor = const PdfColor.fromInt(0xFF64748B);
    }

    final primaryColor = const PdfColor.fromInt(0xFF0F766E);
    final lightGrey = const PdfColor.fromInt(0xFFF1F5F9);
    final darkText = const PdfColor.fromInt(0xFF0F172A);
    final secondaryText = const PdfColor.fromInt(0xFF64748B);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // ── Header ──────────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'FIELD NOTE REPORT',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        note.status,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  note.title,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${note.siteName ?? 'Unknown Site'}${note.customerName != null ? ' • ${note.customerName}' : ''}',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFB2DFDB),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Meta Info Grid ───────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: lightGrey,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                _metaItem('Date', formattedDate, darkText, secondaryText),
                pw.SizedBox(width: 40),
                _metaItem('Time', formattedTime, darkText, secondaryText),
                pw.SizedBox(width: 40),
                _metaItem('Status', note.status, darkText, secondaryText),
                if (note.syncStatus == 'synced') ...[
                  pw.SizedBox(width: 40),
                  _metaItem('Sync', 'Cloud Synced', darkText, secondaryText),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Description ────────────────────────────────────────────────
          _sectionTitle('Observations & Notes', primaryColor),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFE2E8F0),
              ),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              note.description?.isNotEmpty == true
                  ? note.description!
                  : 'No detailed observations were recorded for this field note.',
              style: pw.TextStyle(
                fontSize: 11,
                color: note.description?.isNotEmpty == true
                    ? darkText
                    : secondaryText,
                lineSpacing: 4,
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // ── GPS Location ────────────────────────────────────────────────
          if (note.latitude != null && note.longitude != null) ...[
            _sectionTitle('GPS Location', primaryColor),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Latitude',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: secondaryText,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        note.latitude!.toStringAsFixed(6),
                        style:
                            pw.TextStyle(fontSize: 12, color: darkText),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 40),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Longitude',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: secondaryText,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        note.longitude!.toStringAsFixed(6),
                        style:
                            pw.TextStyle(fontSize: 12, color: darkText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Footer ──────────────────────────────────────────────────────
          pw.Divider(color: const PdfColor.fromInt(0xFFE2E8F0)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated by Field Note App',
                style: pw.TextStyle(fontSize: 9, color: secondaryText),
              ),
              pw.Text(
                generatedAt,
                style: pw.TextStyle(fontSize: 9, color: secondaryText),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 14,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaItem(
      String label, String value, PdfColor dark, PdfColor secondary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 9,
                color: secondary,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 11, color: dark)),
      ],
    );
  }
}
