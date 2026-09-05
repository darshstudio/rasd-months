import 'package:flutter_test/flutter_test.dart';
import 'package:rasd_months/models/grade_record.dart';

void main() {
  group('Grade Calculation Engine Tests', () {
    test('Standard item average (Month 1 + Month 2 + Month 3) / 3 with 2 decimal places no rounding', () {
      final record = GradeRecord(
        seatingNumber: '1001',
        subjectId: 1,
        assessmentItemId: 1, // e.g. واجب منزلي (5)
        term: 1,
        month1Score: 4.0,
        month2Score: 4.0,
        month3Score: 5.0,
      );

      final avg = record.calculateAverage(isMonthExam: false);
      expect(avg, equals(4.33)); // (4 + 4 + 5)/3 = 4.33333... -> 4.33
    });

    test('Month Exam average (Month 1 [15] + Month 2 [15]) / 2 = 15 max', () {
      final record = GradeRecord(
        seatingNumber: '1001',
        subjectId: 1,
        assessmentItemId: 5, // الاختبار الشهري (15)
        term: 1,
        month1Score: 14.0,
        month2Score: 15.0,
        month3Score: null, // No exam in month 3
      );

      final avg = record.calculateAverage(isMonthExam: true);
      expect(avg, equals(14.5)); // (14 + 15) / 2 = 14.5
    });

    test('Null scores return null if all months empty', () {
      final record = GradeRecord(
        seatingNumber: '1002',
        subjectId: 1,
        assessmentItemId: 1,
        term: 1,
      );

      expect(record.calculateAverage(isMonthExam: false), isNull);
      expect(record.calculateAverage(isMonthExam: true), isNull);
    });
  });
}
