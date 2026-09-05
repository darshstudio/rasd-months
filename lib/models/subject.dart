enum AssessmentType {
  grades, // درجات
  passFail, // اجتاز / لم يجتز
}

class Subject {
  final int? id;
  final String name; // اسم المادة
  final String stage; // "الحلقة الابتدائية" / "الحلقة الإعدادية"
  final String gradeLevel; // الصف الدراسي
  final AssessmentType assessmentType; // شكل التقييم (درجات / اجتاز ولم يجتز)

  Subject({
    this.id,
    required this.name,
    required this.stage,
    required this.gradeLevel,
    this.assessmentType = AssessmentType.grades,
  });

  bool get isPassFail => assessmentType == AssessmentType.passFail;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stage': stage,
      'grade_level': gradeLevel,
      'assessment_type': assessmentType == AssessmentType.passFail ? 'pass_fail' : 'grades',
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      name: map['name'] as String,
      stage: map['stage'] as String,
      gradeLevel: map['grade_level'] as String,
      assessmentType: map['assessment_type'] == 'pass_fail'
          ? AssessmentType.passFail
          : AssessmentType.grades,
    );
  }
}
