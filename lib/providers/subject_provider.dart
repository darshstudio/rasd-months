import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/assessment_item.dart';
import '../models/subject.dart';

class SubjectProvider extends ChangeNotifier {
  List<Subject> _subjects = [];
  final Map<int, List<AssessmentItem>> _assessmentItems = {};
  bool _isLoading = false;
  String? _error;

  List<Subject> get subjects => _subjects;
  Map<int, List<AssessmentItem>> get assessmentItems => _assessmentItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSubjectsForGrade(String gradeLevel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance.yearDb;
      final subjectMaps = await db.query(
        'subjects',
        where: 'grade_level = ?',
        whereArgs: [gradeLevel],
        orderBy: 'id ASC',
      );
      _subjects = subjectMaps.map((m) => Subject.fromMap(m)).toList();

      _assessmentItems.clear();
      for (final sub in _subjects) {
        if (sub.id != null) {
          final itemMaps = await db.query(
            'assessment_items',
            where: 'subject_id = ?',
            whereArgs: [sub.id],
            orderBy: 'id ASC',
          );
          _assessmentItems[sub.id!] = itemMaps.map((m) => AssessmentItem.fromMap(m)).toList();
        }
      }
    } catch (e) {
      _error = "فشل تحميل المواد الدراسية: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAssessmentItemMaxScore(AssessmentItem item, double newMaxScore) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      await db.update(
        'assessment_items',
        {'max_score': newMaxScore},
        where: 'id = ?',
        whereArgs: [item.id],
      );
      
      final sub = _subjects.firstWhere((s) => s.id == item.subjectId);
      await loadSubjectsForGrade(sub.gradeLevel);
      return true;
    } catch (e) {
      _error = "فشل تعديل النهاية العظمى للبند: $e";
      notifyListeners();
      return false;
    }
  }
}
