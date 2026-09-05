import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/student.dart';

class ExcelStudentHelper {
  /// Export blank Excel template for entering student data
  static Future<String?> exportStudentTemplate(String gradeLevel) async {
    final excel = Excel.createExcel();
    final sheet = excel['قالب_تسجيل_الطلاب'];
    excel.delete('Sheet1');

    // Header row
    sheet.appendRow([
      TextCellValue('رقم الجلوس'),
      TextCellValue('اسم الطالب'),
      TextCellValue('المرحلة (الصف)'),
      TextCellValue('الفصل'),
      TextCellValue('الجنس'),
    ]);

    // Sample example row
    sheet.appendRow([
      TextCellValue('1001'),
      TextCellValue('أحمد محمد علي'),
      TextCellValue(gradeLevel),
      TextCellValue('5/1'),
      TextCellValue('ولد'),
    ]);

    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final saveUri = await FilePicker.saveFile(
      dialogTitle: 'حفظ قالب Excel لتسجيل الطلاب',
      fileName: 'قالب_الطلاب_$gradeLevel.xlsx',
      bytes: Uint8List.fromList(fileBytes),
    );

    if (saveUri != null) {
      return saveUri.toFilePath();
    }
    return null;
  }

  /// Parse imported Excel file and return student records + validation warnings
  static Future<ExcelParseResult> parseStudentExcel(String filePath, String defaultGradeLevel) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final List<Student> parsedStudents = [];
    final List<String> warnings = [];

    final sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName];

    if (table == null || table.rows.isEmpty) {
      return ExcelParseResult(
        students: [],
        warnings: ['ملف Excel فارغ ولا يحتوي على أي بيانات!'],
        isValid: false,
      );
    }

    // Identify column indices from header
    int seatingIdx = 0;
    int nameIdx = 1;
    int stageIdx = 2;
    int classIdx = 3;
    int genderIdx = 4;

    final firstRow = table.rows.first;
    for (int i = 0; i < firstRow.length; i++) {
      final val = firstRow[i]?.value?.toString().trim() ?? '';
      if (val.contains('جلوس')) seatingIdx = i;
      if (val.contains('اسم')) nameIdx = i;
      if (val.contains('مرحلة') || val.contains('صف')) stageIdx = i;
      if (val.contains('فصل')) classIdx = i;
      if (val.contains('جنس')) genderIdx = i;
    }

    final Set<String> seatingNumbers = {};

    for (int r = 1; r < table.rows.length; r++) {
      final row = table.rows[r];
      if (row.isEmpty) continue;

      final seating = row.length > seatingIdx ? row[seatingIdx]?.value?.toString().trim() ?? '' : '';
      final name = row.length > nameIdx ? row[nameIdx]?.value?.toString().trim() ?? '' : '';
      final stage = row.length > stageIdx ? row[stageIdx]?.value?.toString().trim() ?? defaultGradeLevel : defaultGradeLevel;
      final className = row.length > classIdx ? row[classIdx]?.value?.toString().trim() ?? '1' : '1';
      final gender = row.length > genderIdx ? row[genderIdx]?.value?.toString().trim() ?? 'ولد' : 'ولد';

      if (seating.isEmpty && name.isEmpty) continue; // Skip completely empty rows

      if (seating.isEmpty) {
        warnings.add('سطر ${r + 1}: رقم الجلوس مفقود للطالب "$name"');
        continue;
      }

      if (name.isEmpty) {
        warnings.add('سطر ${r + 1}: اسم الطالب مفقود لرقم الجلوس "$seating"');
        continue;
      }

      if (seatingNumbers.contains(seating)) {
        warnings.add('سطر ${r + 1}: تكرار رقم الجلوس "$seating" داخل الملف!');
      } else {
        seatingNumbers.add(seating);
      }

      parsedStudents.add(
        Student(
          seatingNumber: seating,
          name: name,
          stage: stage.isEmpty ? defaultGradeLevel : stage,
          className: className.isEmpty ? '1' : className,
          gender: (gender == 'بنت' || gender == 'أنثى' || gender == 'انثى') ? 'بنت' : 'ولد',
        ),
      );
    }

    return ExcelParseResult(
      students: parsedStudents,
      warnings: warnings,
      isValid: warnings.isEmpty && parsedStudents.isNotEmpty,
    );
  }
}

class ExcelParseResult {
  final List<Student> students;
  final List<String> warnings;
  final bool isValid;

  ExcelParseResult({
    required this.students,
    required this.warnings,
    required this.isValid,
  });
}
