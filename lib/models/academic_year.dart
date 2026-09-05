class AcademicYear {
  final int? id;
  final String name; // e.g., "2025/2026"
  final String dbFileName; // e.g., "rasd_2025_2026.db"
  final bool isLanguageSchool; // true if language school (adds Level / Extra English)
  final bool isActive;
  final String createdAt;

  AcademicYear({
    this.id,
    required this.name,
    required this.dbFileName,
    this.isLanguageSchool = false,
    this.isActive = true,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'db_file_name': dbFileName,
      'is_language_school': isLanguageSchool ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory AcademicYear.fromMap(Map<String, dynamic> map) {
    return AcademicYear(
      id: map['id'] as int?,
      name: map['name'] as String,
      dbFileName: map['db_file_name'] as String,
      isLanguageSchool: (map['is_language_school'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] as String?,
    );
  }
}
