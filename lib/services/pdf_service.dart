import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/university.dart';

class PdfService {
  // Kurumsal bilgiler — değiştirmeniz gereken tek yer burası
  static const _izmir =
      '1479 Sk. No:16, Kat:2, D:5, Kenet Sitesi, Alsancak / İzmir';
  static const _istanbul =
      'Mühürdar Cad. Yücel Apt. No: 51/4 K:3 Kadıköy / İstanbul';
  static const _email = 'info@myeducoach.com';
  static const _website = 'www.myeducoach.com';
  static const _whatsapp = '+90 (552) 441 13 38';
  static const _phoneIzmir = '+90 (232) 441 13 38';
  static const _phoneIstanbul = '+90 (216) 441 13 38';

  // Kurumsal renkler (ekran görüntüsündeki belgeye uygun)
  static const _navyBlue = PdfColor.fromInt(0xFF1E3A6E);
  static const _crimsonRed = PdfColor.fromInt(0xFFB71C1C);

  static Future<Uint8List> generatePdf({
    required String studentName,
    required List<University> selected,
  }) async {
    final pdf = pw.Document();

    // Font yükle (Türkçe karakter desteği için)
    final regular = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();
    final italic = await PdfGoogleFonts.robotoItalic();
    final boldItalic = await PdfGoogleFonts.robotoBoldItalic();

    // Logo yükle (assets/images/logo.png dosyasını koymanız gerekiyor)
    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      // Logo dosyası bulunamazsa logosuz devam et
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        header: (context) => _buildHeader(logo, bold, regular),
        footer: (context) => _buildFooter(regular, bold),
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(55, 30, 40, 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Öğrenci adı başlığı
                pw.Text(
                  studentName.isNotEmpty
                      ? '$studentName — Üniversite Tavsiye Listesi'
                      : 'Üniversite Tavsiye Listesi',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 13,
                    color: _navyBlue,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(color: _navyBlue, thickness: 0.5),
                pw.SizedBox(height: 12),

                // Üniversiteler
                ...selected.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final uni = entry.value;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 18),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Numara + Okul adı
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 22,
                              height: 22,
                              decoration: pw.BoxDecoration(
                                color: _navyBlue,
                                shape: pw.BoxShape.circle,
                              ),
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '$index',
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 10,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    uni.name,
                                    style: pw.TextStyle(
                                      font: bold,
                                      fontSize: 12,
                                      color: _navyBlue,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    uni.program,
                                    style: pw.TextStyle(
                                      font: boldItalic,
                                      fontSize: 10.5,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.UrlLink(
                                    destination: uni.url,
                                    child: pw.Text(
                                      uni.url,
                                      style: pw.TextStyle(
                                        font: italic,
                                        fontSize: 9,
                                        color: _navyBlue,
                                        decoration: pw.TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage? logo,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      children: [
        // Üst bant: adresler sol, logo sağ
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(40, 18, 40, 14),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Adresler
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _izmir,
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    _istanbul,
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              // Logo veya isim
              if (logo != null)
                pw.Image(logo, width: 130, height: 55, fit: pw.BoxFit.contain)
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'MYEDU COACH',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 18,
                        color: _navyBlue,
                      ),
                    ),
                    pw.Text(
                      'YURTDIŞI EĞİTİM',
                      style: pw.TextStyle(
                        font: regular,
                        fontSize: 9,
                        color: _crimsonRed,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // Mavi çizgi
        pw.Container(height: 3.5, color: _navyBlue),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font regular, pw.Font bold) {
    return pw.Column(
      children: [
        pw.Container(height: 1, color: PdfColors.grey300),
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(30, 10, 30, 10),
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Sol: email + website
              pw.Row(
                children: [
                  _footerItem(regular, '✉', _email),
                  pw.SizedBox(width: 20),
                  _footerItem(regular, '🌐', _website),
                ],
              ),
              // Sağ: telefonlar
              pw.Row(
                children: [
                  _footerItem(regular, '📱', _whatsapp),
                  pw.SizedBox(width: 16),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _phoneIzmir,
                        style: pw.TextStyle(font: regular, fontSize: 8),
                      ),
                      pw.Text(
                        _phoneIstanbul,
                        style: pw.TextStyle(font: regular, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        // Alt kırmızı şerit
        pw.Container(height: 6, color: _crimsonRed),
      ],
    );
  }

  static pw.Widget _footerItem(pw.Font font, String icon, String text) {
    return pw.Row(
      children: [
        pw.Text(icon, style: pw.TextStyle(fontSize: 9)),
        pw.SizedBox(width: 4),
        pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey800),
        ),
      ],
    );
  }
}
