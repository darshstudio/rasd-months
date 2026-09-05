class AssessmentItem {
  final int? id;
  final int subjectId;
  final String itemName; // e.g. "واجب منزلي", "كراسة الحصة", "التقييمات الأسبوعية", "المواظبة والسلوك", "الاختبار الشهري"
  final double maxScore; // النهاية العظمى للبند
  final bool existsInMonth3; // الاختبار الشهري غير موجود في شهر 3

  AssessmentItem({
    this.id,
    required this.subjectId,
    required this.itemName,
    required this.maxScore,
    this.existsInMonth3 = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'item_name': itemName,
      'max_score': maxScore,
      'exists_in_month_3': existsInMonth3 ? 1 : 0,
    };
  }

  factory AssessmentItem.fromMap(Map<String, dynamic> map) {
    return AssessmentItem(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      itemName: map['item_name'] as String,
      maxScore: (map['max_score'] as num).toDouble(),
      existsInMonth3: (map['exists_in_month_3'] as int?) != 0,
    );
  }
}
