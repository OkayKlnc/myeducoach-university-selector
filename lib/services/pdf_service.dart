import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/university.dart';

class PdfService {
  // ─── Renkler ──────────────────────────────────────────────────────────────
  static const _navy    = PdfColor.fromInt(0xFF1E3A6E);
  static const _crimson = PdfColor.fromInt(0xFFC0293A);

  // ─── Logo önbelleği ───────────────────────────────────────────────────────
  static pw.MemoryImage? _cachedLogo;

  static Future<pw.MemoryImage?> _loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo;
    try {
      final raw   = await rootBundle.load('assets/images/logo.png');
      final bytes = raw.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 300);
      final frame = await codec.getNextFrame();
      final resized = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (resized == null) return null;
      _cachedLogo = pw.MemoryImage(resized.buffer.asUint8List());
      return _cachedLogo;
    } catch (_) {
      return null;
    }
  }

  // ─── Ana üretim fonksiyonu ────────────────────────────────────────────────
  // Marjinler küçültüldü → 8 üniversite tek sayfaya sığsın
  static Future<Uint8List> generatePdf({
    required String studentName,
    required List<University> selected,
  }) async {
    final bold    = await PdfGoogleFonts.robotoBold();
    final regular = await PdfGoogleFonts.robotoRegular();
    final logo    = await _loadLogo();

    final pdf = pw.Document(compress: true);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          // Üst/alt marjin küçültüldü — header ve footer yer açmak için
          margin: const pw.EdgeInsets.fromLTRB(48, 68, 48, 72),
        ),
        header: (_) => _buildHeader(logo, bold),
        footer: (_) => _buildFooter(regular, bold),
        build: (_) => [_buildContent(studentName, selected, bold, regular)],
      ),
    );

    return pdf.save();
  }

  // ─── HEADER — sadece logo ortada, kompakt ─────────────────────────────────
  static pw.Widget _buildHeader(pw.MemoryImage? logo, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Center(
          child: logo != null
              ? pw.Image(logo, height: 46, fit: pw.BoxFit.contain)
              : pw.Text(
                  'MYEDUCOACH',
                  style: pw.TextStyle(font: bold, fontSize: 18, color: _navy),
                ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _navy, thickness: 0.8),
        pw.SizedBox(height: 2),
      ],
    );
  }

  // ─── FOOTER — iki sütun ofis bilgisi, kompakt ────────────────────────────
  static pw.Widget _buildFooter(pw.Font regular, pw.Font bold) {
    const fs = 7.0;
    final s = pw.TextStyle(font: regular, fontSize: fs, color: _navy);
    final b = pw.TextStyle(font: bold,    fontSize: fs, color: _navy);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _navy, thickness: 0.5),
        pw.SizedBox(height: 5),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── İstanbul ──
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Istanbul Office', style: b),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Muhurdar Cad. Yucel Apt. No:51/4 Kat:3  Kadikoy / Istanbul',
                    style: s,
                  ),
                  pw.SizedBox(height: 2),
                  pw.RichText(text: pw.TextSpan(children: [
                    pw.TextSpan(text: 'Tel: ', style: b),
                    pw.TextSpan(text: '+90 (216) 441 13 38', style: s),
                  ])),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            // ── İzmir ──
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Izmir Office', style: b),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '1479 Sk. No:16, Kat:2, D:5, Kenet Sitesi  Alsancak / Izmir',
                    style: s,
                  ),
                  pw.SizedBox(height: 2),
                  pw.RichText(text: pw.TextSpan(children: [
                    pw.TextSpan(text: 'Tel: ', style: b),
                    pw.TextSpan(text: '+90 (232) 441 13 38   ', style: s),
                    pw.TextSpan(text: 'GSM: ', style: b),
                    pw.TextSpan(text: '+90 (552) 441 13 38', style: s),
                  ])),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── İÇERİK — kompakt, 8 üniversite tek sayfaya sığar ───────────────────
  static pw.Widget _buildContent(
    String studentName,
    List<University> selected,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          studentName.isNotEmpty
              ? '$studentName — Universite Tavsiye Listesi'
              : 'Universite Tavsiye Listesi',
          style: pw.TextStyle(font: bold, fontSize: 12, color: _navy),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _crimson, thickness: 0.5),
        pw.SizedBox(height: 10),
        ...selected.asMap().entries.map((entry) {
          final i   = entry.key + 1;
          final uni = entry.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 14),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 22, height: 22,
                  decoration: const pw.BoxDecoration(
                    color: _navy, shape: pw.BoxShape.circle,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text('$i',
                    style: pw.TextStyle(font: bold, fontSize: 9,
                        color: PdfColors.white)),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(uni.name,
                        style: pw.TextStyle(font: bold, fontSize: 12.5,
                            color: _navy)),
                      pw.SizedBox(height: 2),
                      pw.Text(uni.program,
                        style: pw.TextStyle(font: regular, fontSize: 11,
                            color: PdfColors.black)),
                      pw.SizedBox(height: 2),
                      pw.UrlLink(
                        destination: uni.url,
                        child: pw.Text(uni.url,
                          style: pw.TextStyle(font: regular, fontSize: 8.5,
                              color: _navy,
                              decoration: pw.TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
