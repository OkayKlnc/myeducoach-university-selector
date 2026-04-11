import 'dart:math' as math;
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
  static const _watermarkPink = PdfColor.fromInt(0xFFE0AAAF);

  // A4 nokta boyutları
  static const _pageW = 595.28;
  static const _pageH = 841.89;

  // ─── Logo önbelleği ───────────────────────────────────────────────────────
  static pw.MemoryImage? _cachedLogo;

  static Future<pw.MemoryImage?> _loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo;
    try {
      final raw   = await rootBundle.load('assets/images/logo.png');
      final bytes = raw.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 260);
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
          margin: const pw.EdgeInsets.fromLTRB(65, 108, 38, 125),
          buildBackground: (context) => _buildBackground(bold, context),
        ),
        header: (_) => _buildHeader(logo, bold, regular),
        footer: (_) => _buildFooter(regular, bold),
        build: (_) => [_buildContent(studentName, selected, bold, regular)],
      ),
    );

    return pdf.save();
  }

  // ─── ARKA PLAN ────────────────────────────────────────────────────────────
  // CustomPaint → PdfGraphics canvas üzerinden direkt çizim.
  // PDF koordinat sistemi: x sağa, y YUKARI, (0,0) = SOL ALT köşe.
  //
  // buildBackground sayfa koordinatlarını kullanır (0,0 → sol alt, 595×841).
  // Sol marjin: 0–65pt, içerik: 65–557pt, sağ marjin: 557–595pt.
  //
  static pw.Widget _buildBackground(pw.Font bold, pw.Context pwContext) {
    // pw.Font → PdfFont (canvas API için gerekli)
    final pdfFont = bold.getFont(pwContext);

    return pw.CustomPaint(
      size: const PdfPoint(_pageW, _pageH),
      painter: (canvas, size) {
        final w = size.x;  // 595.28
        final h = size.y;  // 841.89

        // ── 1. Sol ince navy dikey çizgi ──────────────────────────────────
        // x=30, y=0'dan y=841'e (PDF'de alt→üst)
        canvas.setFillColor(_navy);
        canvas.drawRect(30, 0, 1.5, h);
        canvas.fillPath();

        // ── 2. MYEDUCOACH dikey filigran ──────────────────────────────────
        // PDF canvas koordinatı: y yukari.
        // Metnin merkezi: x=33 (sol marjin ortası), y=h/2 (sayfa ortası)
        // 90° saat yönünün tersi (CCW) döndürme → metin aşağıdan yukarıya okunur.
        canvas.saveContext();

        // Transform: önce sol marjin ortasına git, sonra 90° CCW döndür
        final xCenter = 33.0;   // sol marjin ortası
        final yCenter = h / 2;  // sayfa dikey ortası

        canvas.setTransform(
          Matrix4.identity()
            ..translate(xCenter, yCenter)
            ..rotateZ(math.pi / 2), // 90° CCW → metin aşağıdan yukarıya
        );

        // "MYEDUCOACH" @ 48pt Roboto Bold — genişlik PdfFont.stringMetrics ile hesaplanır
        const double fontSize = 48.0;
        final double textWidth  = pdfFont.stringMetrics('MYEDUCOACH').width * fontSize;
        const double textHeight = fontSize * 0.7; // cap height tahmini

        canvas.setFillColor(_watermarkPink);
        canvas.drawString(
          pdfFont,
          fontSize,
          'MYEDUCOACH',
          -textWidth / 2,     // yatay merkez
          -textHeight / 2,    // dikey merkez (baseline offset)
        );

        canvas.restoreContext();

        // ── 3. Sağ alt köşe dekorasyonu ───────────────────────────────────
        // PDF y=0 altta. Sağ alt köşe: x=(w-95) → w, y=0 → 58
        //
        // Antetli kağıtta: navy (büyük) + crimson (küçük) geometrik şekil
        // Navy büyük üçgen (alt-sol)
        canvas.setFillColor(_navy);
        canvas.moveTo(w - 95, 0);   // sol alt
        canvas.lineTo(w,      0);   // sağ alt
        canvas.lineTo(w - 95, 58);  // sol üst
        canvas.closePath();
        canvas.fillPath();

        // Crimson küçük üçgen (üst-sağ)
        canvas.setFillColor(_crimson);
        canvas.moveTo(w,      0);   // sağ alt
        canvas.lineTo(w,      58);  // sağ üst
        canvas.lineTo(w - 95, 58);  // sol üst
        canvas.closePath();
        canvas.fillPath();
      },
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(
    pw.MemoryImage? logo,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '1479 Sk. No:16, Kat:2, D:5, Kenet Sitesi, Alsancak / İzmir',
                      style: pw.TextStyle(font: regular, fontSize: 7.5, color: _navy),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Mühürdar Cad. Yücel Apt. No:51/4 Kat:3 Kadıköy / İstanbul',
                      style: pw.TextStyle(font: regular, fontSize: 7.5, color: _navy),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            if (logo != null)
              pw.Image(logo, height: 62, fit: pw.BoxFit.contain)
            else
              pw.Text('MYEDU COACH',
                style: pw.TextStyle(font: bold, fontSize: 18, color: _navy)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _navy, thickness: 1.0),
      ],
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Font regular, pw.Font bold) {
    const fs = 7.5;
    final s = pw.TextStyle(font: regular, fontSize: fs, color: _navy);
    final b = pw.TextStyle(font: bold,    fontSize: fs, color: _navy);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _navy, thickness: 0.6),
        pw.SizedBox(height: 7),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // E-posta ve web
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'E: ', style: b),
                  pw.TextSpan(text: 'info@myeducoach.com', style: s),
                ])),
                pw.SizedBox(height: 4),
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'W: ', style: b),
                  pw.TextSpan(text: 'www.myeducoach.com', style: s),
                ])),
              ],
            ),
            pw.SizedBox(width: 36),
            // Telefon numaraları
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'T: ', style: b),
                  pw.TextSpan(text: '+90 (552) 441 13 38', style: s),
                ])),
                pw.SizedBox(height: 4),
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'T: ', style: b),
                  pw.TextSpan(text: '+90 (216) 441 13 38', style: s),
                ])),
                pw.SizedBox(height: 4),
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'T: ', style: b),
                  pw.TextSpan(text: '+90 (232) 441 13 38', style: s),
                ])),
              ],
            ),
            pw.Expanded(child: pw.Container()),
          ],
        ),
      ],
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
        pw.Text(
          studentName.isNotEmpty
              ? '$studentName — Üniversite Tavsiye Listesi'
              : 'Üniversite Tavsiye Listesi',
          style: pw.TextStyle(font: bold, fontSize: 13, color: _navy),
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: _navy, thickness: 0.5),
        pw.SizedBox(height: 14),
        ...selected.asMap().entries.map((entry) {
          final i   = entry.key + 1;
          final uni = entry.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 22, height: 22,
                  decoration: const pw.BoxDecoration(
                    color: _navy, shape: pw.BoxShape.circle),
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
                        style: pw.TextStyle(font: bold, fontSize: 11.5,
                            color: _navy)),
                      pw.SizedBox(height: 2),
                      pw.Text(uni.program,
                        style: pw.TextStyle(font: regular, fontSize: 10.5,
                            color: PdfColors.black)),
                      pw.SizedBox(height: 3),
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
