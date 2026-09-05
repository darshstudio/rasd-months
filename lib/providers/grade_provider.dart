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

    // Synchronously update memory cache for instant UI response
    _gradeRecordsMap.putIfAbsent(seatingNumber, () => {})[assessmentItemId] = updatedRecord;
    notifyListeners();

    // Query DB by unique composite key to get existing id if present
    final existingMaps = await db.query(
      'grade_records',
      where: 'seating_number = ? AND subject_id = ? AND assessment_item_id = ? AND term = ?',
      whereArgs: [seatingNumber, subjectId, assessmentItemId, term],
    );

    if (existingMaps.isNotEmpty) {
      final existingId = existingMaps.first['id'] as int;
      await db.update(
        'grade_records',
        updatedRecord.toMap(),
        where: 'id = ?',
        whereArgs: [existingId],
      );
    } else {
      final insertedId = await db.insert(
        'grade_records',
        updatedRecord.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _gradeRecordsMap.putIfAbsent(seatingNumber, () => {})[assessmentItemId] = GradeRecord(
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
    }
  }

  /// Batch update grades from Excel import for target month
  Future<int> batchSaveGradeRecords(List<GradeRecord> records, {required int targetMonth}) async {
    final db = DatabaseHelper.instance.yearDb;
    int count = 0;

    await db.transaction((txn) async {
      for (final rec in records) {
        final existing = await txn.query(
          'grade_records',
          where: 'seating_number = ? AND subject_id = ? AND assessment_item_id = ? AND term = ?',
          whereArgs: [rec.seatingNumber, rec.subjectId, rec.assessmentItemId, rec.term],
        );

        final mapToSave = rec.toMap();
        mapToSave.remove('id');

        if (existing.isNotEmpty) {
          final id = existing.first['id'] as int;
          final existingRec = GradeRecord.fromMap(existing.first);
          
          double? m1 = targetMonth == 1 ? rec.month1Score : existingRec.month1Score;
          double? m2 = targetMonth == 2 ? rec.month2Score : existingRec.month2Score;
          double? m3 = targetMonth == 3 ? rec.month3Score : existingRec.month3Score;

          final updatedRec = GradeRecord(
            id: id,
            seatingNumber: rec.seatingNumber,
            subjectId: rec.subjectId,
            assessmentItemId: rec.assessmentItemId,
            term: rec.term,
            month1Score: m1,
            month2Score: m2,
            month3Score: m3,
            passFailStatus: rec.passFailStatus ?? existingRec.passFailStatus,
          );

          final updateMap = updatedRec.toMap();
          updateMap.remove('id');

          await txn.update(
            'grade_records',
            updateMap,
            where: 'id = ?',
            whereArgs: [id],
          );
          _gradeRecordsMap.putIfAbsent(rec.seatingNumber, () => {})[rec.assessmentItemId] = updatedRec;
        } else {
          final insertedId = await txn.insert(
            'grade_records',
            mapToSave,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          _gradeRecordsMap.putIfAbsent(rec.seatingNumber, () => {})[rec.assessmentItemId] = GradeRecord(
            id: insertedId,
            seatingNumber: rec.seatingNumber,
            subjectId: rec.subjectId,
            assessmentItemId: rec.assessmentItemId,
            term: rec.term,
            month1Score: rec.month1Score,
            month2Score: rec.month2Score,
            month3Score: rec.month3Score,
            passFailStatus: rec.passFailStatus,
          );
        }
        count++;
      }
    });

    notifyListeners();
    return count;
  }
}
