import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/university.dart';

class PdfService {
  // ─── Kurumsal bilgiler ─────────────────────────────────────────────────────
  static const _izmir    = '1479 Sk. No:16, Kat:2, D:5, Kenet Sitesi, Alsancak / İzmir';
  static const _istanbul = 'Mühürdar Cad. Yücel Apt. No:51/4 Kat:3 Kadıköy / İstanbul';
  static const _email    = 'info@myeducoach.com';
  static const _website  = 'www.myeducoach.com';
  static const _whatsapp = '+90 (552) 441 13 38';
  static const _telIzmir = '+90 (232) 441 13 38';
  static const _telIst   = '+90 (216) 441 13 38';

  // ─── Renkler ──────────────────────────────────────────────────────────────
  static const _navy    = PdfColor.fromInt(0xFF1E3A6E);
  static const _crimson = PdfColor.fromInt(0xFFB71C1C);
  static const _purple  = PdfColor.fromInt(0xFF7B7FAB); // sol şekil (mavi-mor)
  static const _pink    = PdfColor.fromInt(0xFFD4857A); // sağ şekil (pembe)
  static const _wm      = PdfColor.fromInt(0x14B71C1C); // watermark (~8% opasite)

  // ─── Logo önbelleği ───────────────────────────────────────────────────────
  static Uint8List? _cachedLogo;

  /// Logoyu 120px genişliğine küçültüp PNG olarak döner.
  /// Flutter web'de dart:ui ile yeniden kodlama yapar → boyut dramatik düşer.
  static Future<Uint8List?> _loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo;
    try {
      final raw = await rootBundle.load('assets/images/logo.png');
      final bytes = raw.buffer.asUint8List();

      // Bellekte 120px genişliğe küçült
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 120);
      final frame = await codec.getNextFrame();
      final resized = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (resized == null) return null;
      _cachedLogo = resized.buffer.asUint8List();
      return _cachedLogo;
    } catch (_) {
      return null;
    }
  }

  // ─── PDF üretimi ──────────────────────────────────────────────────────────
  static Future<Uint8List> generatePdf({
    required String studentName,
    required List<University> selected,
  }) async {
    // OPTIMIZASYON: 4 yerine 2 font variant → font boyutu %50 düşer
    final bold    = await PdfGoogleFonts.robotoBold();
    final regular = await PdfGoogleFonts.robotoRegular();

    final logoBytes = await _loadLogo();
    final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    final pdf = pw.Document(compress: true); // zlib stream sıkıştırma

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(60, 10, 40, 90),
        header: (_) => _header(logo, bold, regular),
        footer: (_) => _footer(regular, bold),
        build: (_) => [
          _watermark(bold),       // sol watermark
          _content(studentName, selected, bold, regular),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  static pw.Widget _header(pw.MemoryImage? logo, pw.Font bold, pw.Font regular) {
    return pw.Column(children: [
      // Üst ince çizgi + merkez nokta efekti
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
        pw.Container(width: 1, height: 14, color: PdfColors.grey400),
      ]),
      pw.SizedBox(height: 6),
      // Adres (sol) | Logo (sağ)
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(_izmir,    style: pw.TextStyle(font: regular, fontSize: 7.5, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            pw.Text(_istanbul, style: pw.TextStyle(font: regular, fontSize: 7.5, color: PdfColors.grey600)),
          ]),
          if (logo != null)
            pw.Image(logo, width: 110, fit: pw.BoxFit.contain)
          else
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('MYEDU COACH', style: pw.TextStyle(font: bold, fontSize: 16, color: _navy)),
              pw.Text('YURTDIŞI EĞİTİM', style: pw.TextStyle(font: regular, fontSize: 8, color: _crimson, letterSpacing: 1.5)),
            ]),
        ],
      ),
      pw.SizedBox(height: 8),
      // Yatay çizgi
      pw.Container(height: 1, color: PdfColors.grey300),
      pw.SizedBox(height: 4),
    ]);
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  static pw.Widget _footer(pw.Font regular, pw.Font bold) {
    return pw.Column(children: [
      pw.Container(height: 0.5, color: PdfColors.grey300),
      pw.SizedBox(height: 6),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Sol: email + website
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _footerRow(regular, '✉ ', _email),
            pw.SizedBox(height: 3),
            _footerRow(regular, '⊕ ', _website),
          ]),
          // Sağ: telefonlar + dekoratif şekiller
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              _footerRow(regular, '💬 ', _whatsapp),
              pw.SizedBox(height: 3),
              _footerRow(regular, '📞 ', '$_telIst\n    $_telIzmir'),
            ]),
            pw.SizedBox(width: 10),
            // Dekoratif şekiller (antetli kağıttaki gibi)
            _decorativeShapes(),
          ]),
        ],
      ),
    ]);
  }

  static pw.Widget _footerRow(pw.Font font, String icon, String text) {
    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(icon, style: pw.TextStyle(font: font, fontSize: 8, color: _navy)),
      pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700)),
    ]);
  }

  /// Antetli kağıttaki sağ alt köşe dekoratif şekiller
  static pw.Widget _decorativeShapes() {
    return pw.Stack(children: [
      // Arka plan (mor-mavi)
      pw.Container(
        width: 36, height: 36,
        decoration: pw.BoxDecoration(
          color: _purple,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
      ),
      // Ön plan (pembe) — offset
      pw.Positioned(
        right: 0, bottom: 0,
        child: pw.Container(
          width: 26, height: 26,
          decoration: pw.BoxDecoration(
            color: _pink,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
        ),
      ),
    ]);
  }

  // ─── Sol kenar Watermark ──────────────────────────────────────────────────
  /// Antetli kağıtta solda dikey yazılı soluk "MYEDUCOACH" efekti
  static pw.Widget _watermark(pw.Font bold) {
    return pw.Positioned(
      left: -52,
      top: 60,
      child: pw.Transform.rotate(
        angle: -pi / 2,
        child: pw.Text(
          'MYEDUCOACH',
          style: pw.TextStyle(
            font: bold,
            fontSize: 62,
            color: _wm,
            letterSpacing: 6,
          ),
        ),
      ),
    );
  }

  // ─── İçerik ───────────────────────────────────────────────────────────────
  static pw.Widget _content(
    String studentName,
    List<University> selected,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, left: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Başlık
          pw.Text(
            studentName.isNotEmpty
                ? '$studentName — Üniversite Tavsiye Listesi'
                : 'Üniversite Tavsiye Listesi',
            style: pw.TextStyle(font: bold, fontSize: 12, color: _navy),
          ),
          pw.SizedBox(height: 4),
          pw.Container(height: 0.5, color: _navy),
          pw.SizedBox(height: 14),

          // Üniversiteler
          ...selected.asMap().entries.map((e) {
            final i   = e.key + 1;
            final uni = e.value;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Numara baloncuğu
                  pw.Container(
                    width: 20, height: 20,
                    decoration: pw.BoxDecoration(color: _navy, shape: pw.BoxShape.circle),
                    alignment: pw.Alignment.center,
                    child: pw.Text('$i',
                      style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white)),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(uni.name,
                          style: pw.TextStyle(font: bold, fontSize: 11, color: _navy)),
                        pw.SizedBox(height: 2),
                        pw.Text(uni.program,
                          style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.black)),
                        pw.SizedBox(height: 2),
                        pw.UrlLink(
                          destination: uni.url,
                          child: pw.Text(uni.url,
                            style: pw.TextStyle(
                              font: regular, fontSize: 8.5,
                              color: _navy,
                              decoration: pw.TextDecoration.underline,
                            )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
