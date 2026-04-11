import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/university.dart';

class PdfService {
  // ─── Renkler (letterhead'den alındı) ─────────────────────────────────────
  static const _navy    = PdfColor.fromInt(0xFF1E3A6E);
  static const _crimson = PdfColor.fromInt(0xFFC0293A);
  // Açık pembe filigran rengi
  static const _watermarkPink = PdfColor.fromInt(0xFFE8B0B8);

  // ─── Logo önbelleği ───────────────────────────────────────────────────────
  static Uint8List? _cachedLogo;

  static Future<Uint8List?> _loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo;
    try {
      final raw   = await rootBundle.load('assets/images/logo.png');
      final bytes = raw.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 260);
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
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          // Sol kenar: filigran + çizgi için geniş marjin
          margin: const pw.EdgeInsets.fromLTRB(68, 110, 38, 130),
          buildBackground: (context) => _buildBackground(bold),
        ),
        header: (_) => _buildHeader(logo, bold, regular),
        footer: (_) => _buildFooter(regular, bold),
        build: (_) => [_buildContent(studentName, selected, bold, regular)],
      ),
    );

    return pdf.save();
  }

  // ─── SAYFA ARKA PLANI (filigran + çizgi + sağ alt köşe) ──────────────────
  static pw.Widget _buildBackground(pw.Font bold) {
    // A4 nokta boyutları
    const pageW = 595.28;
    const pageH = 841.89;

    return pw.Stack(
      children: [
        // ── İnce dikey navy çizgi (sol kenara yakın) ──
        pw.Positioned(
          left: 30,
          top: 0,
          child: pw.Container(
            width: 1.5,
            height: pageH,
            color: _navy,
          ),
        ),

        // ── MYEDUCOACH dikey filigran ──
        // Rotated metin: normal soldan-sağa yazı, 90° döndürülünce
        // aşağıdan yukarıya okunur (M altta, H üstte)
        pw.Positioned(
          left: -168,          // döndürüldükten sonra merkezi sol kenarda kalır
          top: pageH / 2 - 12, // dikey merkez
          child: pw.Transform.rotateBox(
            angle: -math.pi / 2,   // 90° saat yönünde döndür → aşağıdan yukarıya
            child: pw.Text(
              'MYEDUCOACH',
              style: pw.TextStyle(
                font: bold,
                fontSize: 52,
                color: _watermarkPink,
                letterSpacing: 3,
              ),
            ),
          ),
        ),

        // ── Sağ alt köşe dekorasyon: navy dikdörtgen + kırmızı üçgen ──
        pw.Positioned(
          right: 0,
          bottom: 0,
          child: pw.CustomPaint(
            size: const PdfPoint(95, 58),
            painter: (canvas, size) {
              // Navy dikdörtgen (sol bölüm)
              canvas.setFillColor(_navy);
              canvas.drawRect(0, 0, 68, size.y);
              canvas.fillPath();

              // Kırmızı/crimson üçgen (sağ bölüm)
              canvas.setFillColor(_crimson);
              canvas.moveTo(68, 0);
              canvas.lineTo(size.x, 0);
              canvas.lineTo(size.x, size.y);
              canvas.lineTo(68, size.y);
              canvas.closePath();
              canvas.fillPath();

              // Üçgen şeklinde kesi: navy üstünde kırmızı köşegen çizgisi
              canvas.setFillColor(_crimson);
              canvas.moveTo(0, size.y);
              canvas.lineTo(68, size.y);
              canvas.lineTo(68, 0);
              canvas.closePath();
              canvas.fillPath();

              // Tekrar navy (sol üçgen)
              canvas.setFillColor(_navy);
              canvas.moveTo(0, 0);
              canvas.lineTo(68, 0);
              canvas.lineTo(0, size.y);
              canvas.closePath();
              canvas.fillPath();
            },
          ),
        ),
      ],
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
        // Adresler (sol) + Logo (sağ)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Sol: iki ofis adresi
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '1479 Sk. No:16, Kat:2, D:5, Kenet Sitesi, Alsancak / İzmir',
                      style: pw.TextStyle(
                        font: regular, fontSize: 7.5, color: _navy,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Mühürdar Cad. Yücel Apt. No:51/4 Kat:3 Kadıköy / İstanbul',
                      style: pw.TextStyle(
                        font: regular, fontSize: 7.5, color: _navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            // Sağ: Logo
            if (logo != null)
              pw.Image(logo, height: 58, fit: pw.BoxFit.contain)
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('MYEDU COACH',
                    style: pw.TextStyle(font: bold, fontSize: 18, color: _navy)),
                  pw.Text('YURTDIŞI EĞİTİM',
                    style: pw.TextStyle(font: regular, fontSize: 9,
                        color: _navy, letterSpacing: 1.5)),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 10),
        // Ayraç çizgisi (navy, kalınca)
        pw.Divider(color: _navy, thickness: 1.0),
      ],
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Font regular, pw.Font bold) {
    const fs = 7.5;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _navy, thickness: 0.6),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // ── E-posta ve web ──
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _footerRow(regular, '✉', 'info@myeducoach.com', fs),
                pw.SizedBox(height: 5),
                _footerRow(regular, '⊕', 'www.myeducoach.com', fs),
              ],
            ),
            pw.SizedBox(width: 32),
            // ── Telefon numaraları ──
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _footerRow(regular, '☎', '+90 (552) 441 13 38', fs),
                pw.SizedBox(height: 3),
                _footerRow(regular, '☎', '+90 (216) 441 13 38', fs),
                pw.SizedBox(height: 3),
                _footerRow(regular, '☎', '+90 (232) 441 13 38', fs),
              ],
            ),
            pw.Expanded(child: pw.Container()),
          ],
        ),
      ],
    );
  }

  static pw.Widget _footerRow(pw.Font font, String icon, String text, double fs) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(icon,
          style: pw.TextStyle(font: font, fontSize: fs + 1, color: _navy)),
        pw.SizedBox(width: 5),
        pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: fs, color: _navy)),
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
                // Numara balonu
                pw.Container(
                  width: 22, height: 22,
                  decoration: const pw.BoxDecoration(
                    color: _navy,
                    shape: pw.BoxShape.circle,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '$index',
                    style: pw.TextStyle(
                      font: bold, fontSize: 9, color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                // Üniversite bilgileri
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        uni.name,
                        style: pw.TextStyle(
                          font: bold, fontSize: 11.5, color: _navy,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        uni.program,
                        style: pw.TextStyle(
                          font: regular, fontSize: 10.5,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.UrlLink(
                        destination: uni.url,
                        child: pw.Text(
                          uni.url,
                          style: pw.TextStyle(
                            font: regular, fontSize: 8.5, color: _navy,
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
