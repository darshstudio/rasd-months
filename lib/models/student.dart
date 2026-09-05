class Student {
  final int? id;
  final String seatingNumber; // رقم الجلوس (المعرف الرئيسي المستهدف في الحفظ والاستدلال الفردي)
  final String name; // اسم الطالب
  final String stage; // المرحلة (الصف) e.g., "الصف الخامس الابتدائي"
  final String className; // اسم الفصل e.g., "5/1"
  final String gender; // الجنس ("ولد" / "بنت")
  final int? classId;

  Student({
    this.id,
    required this.seatingNumber,
    required this.name,
    required this.stage,
    required this.className,
    required this.gender,
    this.classId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seating_number': seatingNumber,
      'name': name,
      'stage': stage,
      'class_name': className,
      'gender': gender,
      'class_id': classId,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      seatingNumber: map['seating_number'] as String,
      name: map['name'] as String,
      stage: map['stage'] as String,
      className: map['class_name'] as String,
      gender: map['gender'] as String,
      classId: map['class_id'] as int?,
    );
  }
}
