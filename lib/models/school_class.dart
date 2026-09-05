class SchoolClass {
  final int? id;
  final String stage; // "الحلقة الابتدائية" / "الحلقة الإعدادية"
  final String gradeLevel; // e.g., "الصف الخامس الابتدائي"
  final String className; // e.g., "5/1" or "5A"

  SchoolClass({
    this.id,
    required this.stage,
    required this.gradeLevel,
    required this.className,
  });

  String get displayName => "$gradeLevel - $className";

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stage': stage,
      'grade_level': gradeLevel,
      'class_name': className,
    };
  }

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      id: map['id'] as int?,
      stage: map['stage'] as String,
      gradeLevel: map['grade_level'] as String,
      className: map['class_name'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolClass &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          gradeLevel == other.gradeLevel &&
          className == other.className;

  @override
  int get hashCode => stage.hashCode ^ gradeLevel.hashCode ^ className.hashCode;
}
