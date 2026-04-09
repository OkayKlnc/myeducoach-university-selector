class University {
  final String id;
  final String name;
  final String program;
  final String url;
  final String country;
  final String field;
  final String city;
  final String level; // "Lisans" veya "Yüksek Lisans"

  University({
    required this.id,
    required this.name,
    required this.program,
    required this.url,
    required this.country,
    required this.field,
    required this.city,
    required this.level,
  });

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      id: json['id'] as String,
      name: json['name'] as String,
      program: json['program'] as String,
      url: json['url'] as String,
      country: json['country'] as String,
      field: json['field'] as String,
      city: json['city'] as String,
      level: json['level'] as String? ?? 'Lisans',
    );
  }
}
