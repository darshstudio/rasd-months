import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/assessment_item.dart';
import '../models/grade_record.dart';
import '../models/student.dart';
import '../models/subject.dart';

class GradeProvider extends ChangeNotifier {
  List<Student> _students = [];
  Subject? _selectedSubject;
  List<AssessmentItem> _assessmentItems = [];
  Map<String, Map<int, GradeRecord>> _gradeRecordsMap = {}; // seatingNumber -> {assessmentItemId -> GradeRecord}

  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  Subject? get selectedSubject => _selectedSubject;
  List<AssessmentItem> get assessmentItems => _assessmentItems;
  Map<String, Map<int, GradeRecord>> get gradeRecordsMap => _gradeRecordsMap;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGradeData({
    required String gradeLevel,
    required String className,
    required Subject subject,
    required int term,
  }) async {
    _isLoading = true;
    _selectedSubject = subject;
    _error = null;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance.yearDb;

      // 1. Fetch Students (Full Stage if 'الكل' or specific Class)
      List<Map<String, dynamic>> studentMaps;
      if (className == 'الكل' || className.isEmpty) {
        studentMaps = await db.query(
          'students',
          where: 'stage = ?',
          whereArgs: [gradeLevel],
          orderBy: 'seating_number ASC',
        );
      } else {
        studentMaps = await db.query(
          'students',
          where: 'stage = ? AND class_name = ?',
          whereArgs: [gradeLevel, className],
          orderBy: 'seating_number ASC',
        );
      }
      _students = studentMaps.map((m) => Student.fromMap(m)).toList();

      // 2. Fetch Assessment Items for Subject
      final itemMaps = await db.query(
        'assessment_items',
        where: 'subject_id = ?',
        whereArgs: [subject.id],
      );
      _assessmentItems = itemMaps.map((m) => AssessmentItem.fromMap(m)).toList();

      // 3. Fetch Existing Grade Records
      final gradeMaps = await db.query(
        'grade_records',
        where: 'subject_id = ? AND term = ?',
        whereArgs: [subject.id, term],
      );

      _gradeRecordsMap = {};
      for (final gMap in gradeMaps) {
        final record = GradeRecord.fromMap(gMap);
        _gradeRecordsMap.putIfAbsent(record.seatingNumber, () => {})[record.assessmentItemId] = record;
      }
    } catch (e) {
      _error = "فشل تحميل بيانات الرصد: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get or create transient GradeRecord for UI grid display
  GradeRecord getRecord(String seatingNumber, int assessmentItemId, int term, int subjectId) {
    final studentMap = _gradeRecordsMap[seatingNumber];
    if (studentMap != null && studentMap.containsKey(assessmentItemId)) {
      return studentMap[assessmentItemId]!;
    }
    return GradeRecord(
      seatingNumber: seatingNumber,
      subjectId: subjectId,
      assessmentItemId: assessmentItemId,
      term: term,
    );
  }

  /// Update single score cell and persist immediately to SQLite
  Future<void> updateScore({
    required String seatingNumber,
    required int assessmentItemId,
    required int subjectId,
    required int term,
    double? month1Score,
    double? month2Score,
    double? month3Score,
    String? passFailStatus,
    bool notify = true,
  }) async {
    final db = DatabaseHelper.instance.yearDb;

    final existingRecord = getRecord(seatingNumber, assessmentItemId, term, subjectId);
    final updatedRecord = GradeRecord(
      id: existingRecord.id,
      seatingNumber: seatingNumber,
      subjectId: subjectId,
      assessmentItemId: assessmentItemId,
      term: term,
      month1Score: month1Score,
      month2Score: month2Score,
      month3Score: month3Score,
      passFailStatus: passFailStatus ?? existingRecord.passFailStatus,
    );

    // 1. Instantly update memory cache
    _gradeRecordsMap.putIfAbsent(seatingNumber, () => {})[assessmentItemId] = updatedRecord;
    if (notify) notifyListeners();

    // 2. Direct fast database write without extra SELECT queries
    if (existingRecord.id != null) {
      final mapToUpdate = updatedRecord.toMap();
      mapToUpdate.remove('id');
      await db.update(
        'grade_records',
        mapToUpdate,
        where: 'id = ?',
        whereArgs: [existingRecord.id],
      );
    } else {
      final mapToInsert = updatedRecord.toMap();
      mapToInsert.remove('id');
      final insertedId = await db.insert(
        'grade_records',
        mapToInsert,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final finalRecord = GradeRecord(
        id: insertedId,
        seatingNumber: seatingNumber,
        subjectId: subjectId,
        assessmentItemId: assessmentItemId,
        term: term,
        month1Score: updatedRecord.month1Score,
        month2Score: updatedRecord.month2Score,
        month3Score: updatedRecord.month3Score,
        passFailStatus: updatedRecord.passFailStatus,
      );
      _gradeRecordsMap.putIfAbsent(seatingNumber, () => {})[assessmentItemId] = finalRecord;
    }
  }

  /// Batch update grades from Excel import for target month
  Future<int> batchSaveGradeRecords(List<GradeRecord> records, {required int targetMonth}) async {
    if (records.isEmpty) return 0;
    final db = DatabaseHelper.instance.yearDb;
    int count = 0;

    final subjectId = records.first.subjectId;
    final term = records.first.term;

    // Fetch all existing records for subject/term in 1 single bulk query
    final existingMaps = await db.query(
      'grade_records',
      where: 'subject_id = ? AND term = ?',
      whereArgs: [subjectId, term],
    );

    final Map<String, GradeRecord> existingCache = {};
    for (final m in existingMaps) {
      final r = GradeRecord.fromMap(m);
      existingCache['${r.seatingNumber}_${r.assessmentItemId}'] = r;
    }

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final rec in records) {
        final key = '${rec.seatingNumber}_${rec.assessmentItemId}';
        final existingRec = existingCache[key];

        if (existingRec != null && existingRec.id != null) {
          double? m1 = targetMonth == 1 ? rec.month1Score : existingRec.month1Score;
          double? m2 = targetMonth == 2 ? rec.month2Score : existingRec.month2Score;
          double? m3 = targetMonth == 3 ? rec.month3Score : existingRec.month3Score;

          final updateMap = {
            'seating_number': rec.seatingNumber,
            'subject_id': rec.subjectId,
            'assessment_item_id': rec.assessmentItemId,
            'term': rec.term,
            'month_1_score': m1,
            'month_2_score': m2,
            'month_3_score': m3,
            'pass_fail_status': rec.passFailStatus ?? existingRec.passFailStatus,
          };

          batch.update(
            'grade_records',
            updateMap,
            where: 'id = ?',
            whereArgs: [existingRec.id],
          );

          _gradeRecordsMap.putIfAbsent(rec.seatingNumber, () => {})[rec.assessmentItemId] = GradeRecord(
            id: existingRec.id,
            seatingNumber: rec.seatingNumber,
            subjectId: rec.subjectId,
            assessmentItemId: rec.assessmentItemId,
            term: rec.term,
            month1Score: m1,
            month2Score: m2,
            month3Score: m3,
            passFailStatus: updateMap['pass_fail_status'] as String?,
          );
        } else {
          final mapToInsert = rec.toMap();
          mapToInsert.remove('id');
          batch.insert(
            'grade_records',
            mapToInsert,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          _gradeRecordsMap.putIfAbsent(rec.seatingNumber, () => {})[rec.assessmentItemId] = rec;
        }
        count++;
      }
      await batch.commit(noResult: true);
    });

    notifyListeners();
    return count;
  }
}
