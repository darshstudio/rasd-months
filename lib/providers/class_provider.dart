import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../core/utils/error_translator.dart';
import '../models/school_class.dart';

class ClassProvider extends ChangeNotifier {
  List<SchoolClass> _classes = [];
  bool _isLoading = false;
  String? _error;

  List<SchoolClass> get classes => _classes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadClassesForGrade(String stage, String gradeLevel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance.yearDb;
      final maps = await db.query(
        'school_classes',
        where: 'grade_level = ?',
        whereArgs: [gradeLevel],
        orderBy: 'class_name ASC',
      );
      _classes = maps.map((m) => SchoolClass.fromMap(m)).toList();
    } catch (e) {
      _error = ErrorTranslator.translate(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addClass(String stage, String gradeLevel, String className) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      final id = await db.insert('school_classes', {
        'stage': stage,
        'grade_level': gradeLevel,
        'class_name': className,
      });

      if (id > 0) {
        await loadClassesForGrade(stage, gradeLevel);
        return true;
      }
      return false;
    } catch (e) {
      _error = ErrorTranslator.translate(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClass(SchoolClass schoolClass, String newName) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      await db.update(
        'school_classes',
        {'class_name': newName},
        where: 'id = ?',
        whereArgs: [schoolClass.id],
      );
      await loadClassesForGrade(schoolClass.stage, schoolClass.gradeLevel);
      return true;
    } catch (e) {
      _error = ErrorTranslator.translate(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClass(SchoolClass schoolClass) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      await db.delete(
        'school_classes',
        where: 'id = ?',
        whereArgs: [schoolClass.id],
      );
      await loadClassesForGrade(schoolClass.stage, schoolClass.gradeLevel);
      return true;
    } catch (e) {
      _error = ErrorTranslator.translate(e);
      notifyListeners();
      return false;
    }
  }
}
