class GradeRecord {
  final int? id;
  final String seatingNumber; // رقم الجلوس
  final int subjectId;
  final int assessmentItemId;
  final int term; // 1 or 2
  final double? month1Score;
  final double? month2Score;
  final double? month3Score;
  final String? passFailStatus; // "اجتاز" / "لم يجتز" للمواد العملية

  GradeRecord({
    this.id,
    required this.seatingNumber,
    required this.subjectId,
    required this.assessmentItemId,
    required this.term,
    this.month1Score,
    this.month2Score,
    this.month3Score,
    this.passFailStatus,
  });

  /// Calculate average score keeping exact fractions with max 2 decimal places.
  /// Standard items: (m1 + m2 + m3) / 3
  /// Month Exam items: (m1 [15] + m2 [15]) / 2 = 15 (month 3 has no exam)
  double? calculateAverage({bool isMonthExam = false}) {
    if (isMonthExam) {
      if (month1Score == null && month2Score == null) return null;
      final m1 = month1Score ?? 0.0;
      final m2 = month2Score ?? 0.0;
      final avg = (m1 + m2) / 2;
      return double.parse(avg.toStringAsFixed(2));
    } else {
      if (month1Score == null && month2Score == null && month3Score == null) return null;
      final m1 = month1Score ?? 0.0;
      final m2 = month2Score ?? 0.0;
      final m3 = month3Score ?? 0.0;
      final avg = (m1 + m2 + m3) / 3;
      return double.parse(avg.toStringAsFixed(2));
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'seating_number': seatingNumber,
      'subject_id': subjectId,
      'assessment_item_id': assessmentItemId,
      'term': term,
      'month_1_score': month1Score,
      'month_2_score': month2Score,
      'month_3_score': month3Score,
      'pass_fail_status': passFailStatus,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory GradeRecord.fromMap(Map<String, dynamic> map) {
    return GradeRecord(
      id: map['id'] as int?,
      seatingNumber: map['seating_number'] as String,
      subjectId: map['subject_id'] as int,
      assessmentItemId: map['assessment_item_id'] as int,
      term: map['term'] as int,
      month1Score: (map['month_1_score'] as num?)?.toDouble(),
      month2Score: (map['month_2_score'] as num?)?.toDouble(),
      month3Score: (map['month_3_score'] as num?)?.toDouble(),
      passFailStatus: map['pass_fail_status'] as String?,
    );
  }
}
