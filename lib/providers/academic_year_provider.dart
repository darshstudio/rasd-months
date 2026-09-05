import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../core/utils/error_translator.dart';
import '../models/academic_year.dart';

class AcademicYearProvider extends ChangeNotifier {
  List<AcademicYear> _years = [];
  AcademicYear? _selectedYear;
  bool _isLoading = false;
  String? _error;

  List<AcademicYear> get years => _years;
  AcademicYear? get selectedYear => _selectedYear;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadAcademicYears() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _years = await DatabaseHelper.instance.getAllAcademicYears();
      if (_years.isNotEmpty) {
        final active = _years.firstWhere(
          (y) => y.isActive,
          orElse: () => _years.first,
        );
        await selectYear(active);
      }
    } catch (e) {
      _error = ErrorTranslator.translate(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createYear(String name, {bool isLanguageSchool = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newYear = await DatabaseHelper.instance.createAcademicYear(
        name,
        isLanguageSchool: isLanguageSchool,
      );
      await loadAcademicYears();
      await selectYear(newYear);
      return true;
    } catch (e) {
      _error = ErrorTranslator.translate(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectYear(AcademicYear year) async {
    try {
      await DatabaseHelper.instance.switchAcademicYear(year);
      _selectedYear = year;
      notifyListeners();
    } catch (e) {
      _error = ErrorTranslator.translate(e);
      notifyListeners();
    }
  }
}
