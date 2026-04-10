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
  static const _grey300 = PdfColors.grey300;
  static const _grey600 = PdfColors.grey600;

  // ─── Logo önbelleği ───────────────────────────────────────────────────────
  static Uint8List? _cachedLogo;

  static Future<Uint8List?> _loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo;
    try {
      final raw   = await rootBundle.load('assets/images/logo.png');
      final bytes = raw.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 220);
      final frame = await codec.getNextFrame();
      final resized = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (resized == null) return null;
      _cachedLogo = resized.buffer.asUint8List();
      return _cachedLogo;
    } catch (_) {
      return null;
    }
  }

  // ─── Ana üretim fonksiyonu ────────────────────────────────────────────────
  static Future<Uint8List> generatePdf({
    required String studentName,
    required List<University> selected,
  }) async {
    final bold    = await PdfGoogleFonts.robotoBold();
    final regular = await PdfGoogleFonts.robotoRegular();

    final logoBytes = await _loadLogo();
    final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    final pdf = pw.Document(compress: true);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // ── Marjinler: header/footer binmesin ──
        margin: const pw.EdgeInsets.fromLTRB(40, 100, 40, 120),

        // ── Header: her sayfada tekrar eder ──
        header: (_) => _buildHeader(logo, bold, regular),

        // ── Footer: her sayfada tekrar eder ──
        footer: (_) => _buildFooter(regular, bold),

        // ── Body ──
        build: (_) => [_buildContent(studentName, selected, bold, regular)],
      ),
    );

    return pdf.save();
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  // Üstten 100 birim marjin içine sığar.
  // pw.MultiPage bunu marjin alanına absolute olarak basar.
  static pw.Widget _buildHeader(
    pw.MemoryImage? logo,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo — ortalanmış, max yükseklik 65
          if (logo != null)
            pw.Center(
              child: pw.Image(
                logo,
                height: 65,
                fit: pw.BoxFit.contain,
              ),
            )
          else
            pw.Center(
              child: pw.Text(
                'MYEDU COACH',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 20,
                  color: _navy,
                ),
              ),
            ),
          pw.SizedBox(height: 10),
          // Ayraç çizgisi
          pw.Divider(color: _grey300, thickness: 0.8),
        ],
      ),
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────
  // Alttan 120 birim marjin içine sığar.
  static pw.Widget _buildFooter(pw.Font regular, pw.Font bold) {
    const small = 8.0;

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Üst ayraç
          pw.Divider(color: _grey300, thickness: 0.8),
          pw.SizedBox(height: 8),

          // ── Üst satır: İzmir | İstanbul ──────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Sol sütun — İzmir Ofisi
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'İzmir Ofisi',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: small,
                        color: _navy,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '1479 Sk. No:16, Kat:2, D:5, Kenet Sitesi, Alsancak / İzmir',
                      style: pw.TextStyle(font: regular, fontSize: small, color: _grey600),
                    ),
                    pw.Text(
                      'Tel: +90 (232) 441 13 38',
                      style: pw.TextStyle(font: regular, fontSize: small, color: _grey600),
                    ),
                  ],
                ),
              ),

              // Dikey ayraç
              pw.Container(
                width: 0.5,
                height: 30,
                color: _grey300,
                margin: const pw.EdgeInsets.symmetric(horizontal: 16),
              ),

              // Sağ sütun — İstanbul Ofisi
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'İstanbul Ofisi',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: small,
                        color: _navy,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Mühürdar Cad. Yücel Apt. No:51/4 Kat:3 Kadıköy / İstanbul',
                      style: pw.TextStyle(font: regular, fontSize: small, color: _grey600),
                    ),
                    pw.Text(
                      'Tel: +90 (216) 441 13 38',
                      style: pw.TextStyle(font: regular, fontSize: small, color: _grey600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 8),

          // Alt ince çizgi
          pw.Divider(color: _grey300, thickness: 0.5),
          pw.SizedBox(height: 5),

          // ── Alt satır: genel iletişim — ortalanmış ───────────────────────
          pw.Center(
            child: pw.Text(
              'info@myeducoach.com  |  www.myeducoach.com  |  Mobil: +90 (552) 441 13 38',
              style: pw.TextStyle(
                font: regular,
                fontSize: small - 0.5,
                color: _grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── İÇERİK ───────────────────────────────────────────────────────────────
  static pw.Widget _buildContent(
    String studentName,
    List<University> selected,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Başlık
        pw.Text(
          studentName.isNotEmpty
              ? '$studentName — Üniversite Tavsiye Listesi'
              : 'Üniversite Tavsiye Listesi',
          style: pw.TextStyle(font: bold, fontSize: 13, color: _navy),
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: _navy, thickness: 0.5),
        pw.SizedBox(height: 14),

        // Üniversite listesi
        ...selected.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final uni   = entry.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Numara
                pw.Container(
                  width: 22, height: 22,
                  decoration: const pw.BoxDecoration(
                    color: _navy,
                    shape: pw.BoxShape.circle,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '$index',
                    style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
                  ),
                ),
                pw.SizedBox(width: 10),
                // Bilgiler
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        uni.name,
                        style: pw.TextStyle(font: bold, fontSize: 11.5, color: _navy),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        uni.program,
                        style: pw.TextStyle(font: regular, fontSize: 10.5, color: PdfColors.black),
                      ),
                      pw.SizedBox(height: 3),
                      pw.UrlLink(
                        destination: uni.url,
                        child: pw.Text(
                          uni.url,
                          style: pw.TextStyle(
                            font: regular,
                            fontSize: 8.5,
                            color: _navy,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
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
