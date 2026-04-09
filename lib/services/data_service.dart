import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/university.dart';

class DataService {
  static List<University>? _cache;

  static Future<List<University>> loadUniversities() async {
    if (_cache != null) return _cache!;
    final jsonString = await rootBundle.loadString('assets/data/universities.json');
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final list = (jsonData['universities'] as List)
        .map((e) => University.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  static List<String> extractFields(List<University> universities) {
    final fields = universities.map((u) => u.field).toSet().toList()..sort();
    return fields;
  }
}
