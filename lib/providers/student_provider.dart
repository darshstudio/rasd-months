import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/student.dart';

class StudentProvider extends ChangeNotifier {
  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedClassFilter;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedClassFilter => _selectedClassFilter;

  Future<void> loadStudentsForGrade(String stage, String gradeLevel, {String? className}) async {
    _isLoading = true;
    _error = null;
    _selectedClassFilter = className;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance.yearDb;
      List<Map<String, dynamic>> maps;

      if (className != null && className.isNotEmpty && className != 'الكل') {
        maps = await db.query(
          'students',
          where: 'stage = ? AND class_name = ?',
          whereArgs: [gradeLevel, className],
          orderBy: 'seating_number ASC',
        );
      } else {
        maps = await db.query(
          'students',
          where: 'stage = ?',
          whereArgs: [gradeLevel],
          orderBy: 'seating_number ASC',
        );
      }

      _students = maps.map((m) => Student.fromMap(m)).toList();
    } catch (e) {
      _error = "فشل تحميل بيانات الطلاب: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Student?> findStudentBySeatingNumber(String seatingNumber) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      final maps = await db.query(
        'students',
        where: 'seating_number = ?',
        whereArgs: [seatingNumber],
      );
      if (maps.isNotEmpty) {
        return Student.fromMap(maps.first);
      }
    } catch (e) {
      _error = "خطأ أثناء البحث عن الطالب: $e";
    }
    return null;
  }

  Future<bool> addStudent(Student student) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      await db.insert('students', student.toMap());
      await loadStudentsForGrade(student.stage, student.stage, className: _selectedClassFilter);
      return true;
    } catch (e) {
      _error = "رقم الجلوس (${student.seatingNumber}) مسجل بالفعل لطالب آخر!";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudent(Student student) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      await db.update(
        'students',
        student.toMap(),
        where: 'id = ?',
        whereArgs: [student.id],
      );
      await loadStudentsForGrade(student.stage, student.stage, className: _selectedClassFilter);
      return true;
    } catch (e) {
      _error = "فشل تعديل بيانات الطالب: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(Student student) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      await db.delete(
        'students',
        where: 'id = ?',
        whereArgs: [student.id],
      );
      await loadStudentsForGrade(student.stage, student.stage, className: _selectedClassFilter);
      return true;
    } catch (e) {
      _error = "فشل حذف الطالب: $e";
      notifyListeners();
      return false;
    }
  }

  /// Batch import students from Excel parser
  Future<int> importStudentsBatch(List<Student> newStudents, String gradeLevel) async {
    int importedCount = 0;
    final db = DatabaseHelper.instance.yearDb;

    await db.transaction((txn) async {
      for (final s in newStudents) {
        final existing = await txn.query(
          'students',
          where: 'seating_number = ?',
          whereArgs: [s.seatingNumber],
        );

        if (existing.isNotEmpty) {
          await txn.update(
            'students',
            s.toMap(),
            where: 'seating_number = ?',
            whereArgs: [s.seatingNumber],
          );
        } else {
          await txn.insert('students', s.toMap());
        }
        importedCount++;
      }
    });

    await loadStudentsForGrade(gradeLevel, gradeLevel, className: _selectedClassFilter);
    return importedCount;
  }

  /// Batch update students stage and class name (e.g. transfer/move to next class)
  Future<bool> batchUpdateStudentsClass({
    required List<int> studentIds,
    required String targetStage,
    required String targetClassName,
    required String currentGradeLevel,
  }) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      await db.transaction((txn) async {
        for (final id in studentIds) {
          await txn.update(
            'students',
            {
              'stage': targetStage,
              'class_name': targetClassName,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });
      await loadStudentsForGrade(currentGradeLevel, currentGradeLevel, className: _selectedClassFilter);
      return true;
    } catch (e) {
      _error = "فشل نقل/تحديث فصل الطلاب: $e";
      notifyListeners();
      return false;
    }
  }

  /// Batch update gender for selected students
  Future<bool> batchUpdateStudentsGender({
    required List<int> studentIds,
    required String gender,
    required String currentGradeLevel,
  }) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      await db.transaction((txn) async {
        for (final id in studentIds) {
          await txn.update(
            'students',
            {'gender': gender},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });
      await loadStudentsForGrade(currentGradeLevel, currentGradeLevel, className: _selectedClassFilter);
      return true;
    } catch (e) {
      _error = "فشل تعديل جنس الطلاب: $e";
      notifyListeners();
      return false;
    }
  }

  /// Batch delete selected students
  Future<bool> batchDeleteStudents({
    required List<int> studentIds,
    required String currentGradeLevel,
  }) async {
    try {
      final db = DatabaseHelper.instance.yearDb;
      await db.transaction((txn) async {
        for (final id in studentIds) {
          await txn.delete(
            'students',
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });
      await loadStudentsForGrade(currentGradeLevel, currentGradeLevel, className: _selectedClassFilter);
      return true;
    } catch (e) {
      _error = "فشل حذف الطلاب المحددين: $e";
      notifyListeners();
      return false;
    }
  }
}
