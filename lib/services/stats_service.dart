import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pdf_event.dart';
import '../models/user_profile.dart';

class StatsService {
  static final _db = FirebaseFirestore.instance;

  // PDF oluşturma olayını kaydet
  static Future<void> logPdfEvent({
    required UserProfile user,
    required String studentName,
    required List<String> universities,
  }) async {
    await _db.collection('pdf_events').add({
      'userId':       user.uid,
      'userFullName': user.fullName,
      'userEmail':    user.email,
      'studentName':  studentName,
      'universities': universities,
      'createdAt':    FieldValue.serverTimestamp(),
    });
  }

  // Tüm olayları çek (admin)
  static Future<List<PdfEvent>> getAllEvents() async {
    final snap = await _db
        .collection('pdf_events')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => PdfEvent.fromMap(d.id, d.data()))
        .toList();
  }

  // Tüm kullanıcıları çek (admin)
  static Future<List<UserProfile>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs
        .map((d) => UserProfile.fromMap(d.id, d.data()))
        .toList();
  }

  // Zaman aralığı filtresi
  static List<PdfEvent> filterByPeriod(
      List<PdfEvent> events, String period) {
    final now = DateTime.now();
    DateTime cutoff;
    switch (period) {
      case 'Günlük':
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case 'Haftalık':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 'Aylık':
        cutoff = DateTime(now.year, now.month, 1);
        break;
      case 'Yıllık':
        cutoff = DateTime(now.year, 1, 1);
        break;
      default:
        return events;
    }
    return events
        .where((e) => e.createdAt.isAfter(cutoff))
        .toList();
  }

  // Kullanıcı bazlı sayım
  static Map<String, int> countByUser(List<PdfEvent> events) {
    final map = <String, int>{};
    for (final e in events) {
      map[e.userFullName] = (map[e.userFullName] ?? 0) + 1;
    }
    // Azalan sıraya göre sırala
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }
}
