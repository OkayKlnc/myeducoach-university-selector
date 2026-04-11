import 'dart:math' as math;
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
  static const _watermarkPink = PdfColor.fromInt(0xFFDDA8B0);

  // A4 nokta boyutları
  static const _pageW = 595.28;
  static const _pageH = 841.89;

  // ─── Logo önbelleği ───────────────────────────────────────────────────────
  static ui.Image? _cachedImage;
  static pw.MemoryImage? _cachedLogo;

  static Future<pw.MemoryImage?> _loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo;
    try {
      final raw   = await rootBundle.load('assets/images/logo.png');
      final bytes = raw.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 260);
      final frame = await codec.getNextFrame();
      _cachedImage = frame.image;
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
          // Sol kenar: filigran + çizgi için 65pt
          margin: const pw.EdgeInsets.fromLTRB(65, 108, 38, 125),
          buildBackground: (context) => _buildBackground(bold),
        ),
        header: (_) => _buildHeader(logo, bold, regular),
        footer: (_) => _buildFooter(regular, bold),
        build: (_) => [_buildContent(studentName, selected, bold, regular)],
      ),
    );

    return pdf.save();
  }

  // ─── ARKA PLAN: filigran + sol çizgi + sağ alt köşe ──────────────────────
  //
  // buildBackground koordinatları SAYFA KÖKENLİ (0,0 = sol üst köşe).
  // Stack overflow: visible → negatif left ile sayfa marjin alanına yerleştirme.
  //
  static pw.Widget _buildBackground(pw.Font bold) {
    // "MYEDUCOACH" @ fontSize 58, Roboto Bold tahmini genişlik ≈ 370pt
    // 90° saat yönü dönüş sonrası: genişlik ≈ 70pt, yükseklik ≈ 370pt
    // İstenen merkez: x=33 (65pt sol marjinin ortası), y=420 (sayfa ortası)
    // Positioned left = merkez_x - metin_genişliği/2 = 33 - 185 = -152
    // Positioned top  = merkez_y - metin_yüksekliği/2 = 420 - 35 = 385
    const double wmFontSize = 58;
    const double wmEstWidth = 370; // tahmini yatay genişlik
    const double wmEstHeight = 70; // tahmini yükseklik (cap height)
    const double wmCenterX = 33;
    const double wmCenterY = _pageH / 2;
    const double wmLeft = wmCenterX - wmEstWidth / 2; // ≈ -152
    const double wmTop  = wmCenterY - wmEstHeight / 2; // ≈ 386

    return pw.SizedBox(
      width: _pageW,
      height: _pageH,
      child: pw.Stack(
        overflow: pw.Overflow.visible, // negatif koordinatları kırpmaz
        children: [

          // ── 1. Sol ince navy dikey çizgi ──────────────────────────────────
          pw.Positioned(
            left: 28,
            top: 0,
            child: pw.Container(
              width: 1.5,
              height: _pageH,
              color: _navy,
            ),
          ),

          // ── 2. MYEDUCOACH dikey filigran ──────────────────────────────────
          pw.Positioned(
            left: wmLeft,
            top: wmTop,
            child: pw.Transform.rotateBox(
              angle: -math.pi / 2, // 90° saat yönü → aşağıdan yukarıya okunur
              child: pw.Text(
                'MYEDUCOACH',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: wmFontSize,
                  color: _watermarkPink,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          // ── 3. Sağ alt köşe dekorasyon ────────────────────────────────────
          // Orijinal antetli kağıtta: navy + kırmızı geometrik şekil
          pw.Positioned(
            right: 0,
            bottom: 0,
            child: pw.CustomPaint(
              size: const PdfPoint(95, 58),
              painter: (canvas, size) {
                final w = size.x;
                final h = size.y;

                // PDF koordinatı: y=0 altta, y=h üstte.
                // Positioned(bottom:0) → bu widget sayfanın alt-sağına yapışık.

                // Navy üçgen (alt-sol)
                canvas.setFillColor(_navy);
                canvas.moveTo(0, 0);       // sol alt
                canvas.lineTo(w, 0);       // sağ alt
                canvas.lineTo(0, h);       // sol üst
                canvas.closePath();
                canvas.fillPath();

                // Crimson üçgen (üst-sağ)
                canvas.setFillColor(_crimson);
                canvas.moveTo(w, 0);       // sağ alt
                canvas.lineTo(w, h);       // sağ üst
                canvas.lineTo(0, h);       // sol üst
                canvas.closePath();
                canvas.fillPath();
              },
            ),
          ),
        ],
      ),
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
            // Sol: ofis adresleri
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
            // Sağ: logo
            if (logo != null)
              pw.Image(logo, height: 62, fit: pw.BoxFit.contain)
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('MYEDU COACH',
                    style: pw.TextStyle(font: bold, fontSize: 18, color: _navy)),
                  pw.Text('YURTDIŞI EĞİTİM',
                    style: pw.TextStyle(font: regular, fontSize: 8,
                        color: _navy, letterSpacing: 1.5)),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _navy, thickness: 1.0),
      ],
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────
  // Unicode ikon karakterleri (✉ ☎ vb.) Roboto'da yok → düz metin kullan
  static pw.Widget _buildFooter(pw.Font regular, pw.Font bold) {
    const fs = 7.5;
    final style = pw.TextStyle(font: regular, fontSize: fs, color: _navy);
    final boldStyle = pw.TextStyle(font: bold, fontSize: fs, color: _navy);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _navy, thickness: 0.6),
        pw.SizedBox(height: 7),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Sol sütun: e-posta + web
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'E: ', style: boldStyle),
                  pw.TextSpan(text: 'info@myeducoach.com', style: style),
                ])),
                pw.SizedBox(height: 4),
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'W: ', style: boldStyle),
                  pw.TextSpan(text: 'www.myeducoach.com', style: style),
                ])),
              ],
            ),
            pw.SizedBox(width: 36),
            // Sağ sütun: telefon numaraları
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'T: ', style: boldStyle),
                  pw.TextSpan(text: '+90 (552) 441 13 38', style: style),
                ])),
                pw.SizedBox(height: 4),
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'T: ', style: boldStyle),
                  pw.TextSpan(text: '+90 (216) 441 13 38', style: style),
                ])),
                pw.SizedBox(height: 4),
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'T: ', style: boldStyle),
                  pw.TextSpan(text: '+90 (232) 441 13 38', style: style),
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
          final index = entry.key + 1;
          final uni   = entry.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Numara balonu
                pw.Container(
                  width: 22, height: 22,
                  decoration: const pw.BoxDecoration(
                    color: _navy,
                    shape: pw.BoxShape.circle,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text('$index',
                    style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white)),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(uni.name,
                        style: pw.TextStyle(font: bold, fontSize: 11.5, color: _navy)),
                      pw.SizedBox(height: 2),
                      pw.Text(uni.program,
                        style: pw.TextStyle(font: regular, fontSize: 10.5,
                            color: PdfColors.black)),
                      pw.SizedBox(height: 3),
                      pw.UrlLink(
                        destination: uni.url,
                        child: pw.Text(uni.url,
                          style: pw.TextStyle(
                            font: regular, fontSize: 8.5, color: _navy,
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
    );
  }
}
