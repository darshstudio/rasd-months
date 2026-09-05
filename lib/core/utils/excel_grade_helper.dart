import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/assessment_item.dart';
import '../../models/grade_record.dart';
import '../../models/student.dart';
import '../../models/subject.dart';
import '../database/database_helper.dart';

class ExcelGradeRowPreview {
  final String seatingNumber;
  final String studentName;
  final Map<int, double?> scores; // assessmentItemId -> score
  final Map<int, String?> cellErrors; // assessmentItemId -> error message if score invalid
  final bool hasError;

  ExcelGradeRowPreview({
    required this.seatingNumber,
    required this.studentName,
    required this.scores,
    required this.cellErrors,
    required this.hasError,
  });
}

class ExcelGradeParseResult {
  final List<GradeRecord> gradeRecords;
  final List<ExcelGradeRowPreview> previewRows;
  final List<String> warnings;
  final bool isValid;

  ExcelGradeParseResult({
    required this.gradeRecords,
    required this.previewRows,
    required this.warnings,
    required this.isValid,
  });
}

class ExcelGradeHelper {
  /// Export blank or populated Excel grade sheet for a specific Subject, Class, Term and Month
  static Future<String?> exportGradeSheet({
    required Subject subject,
    required String gradeLevel,
    required String className,
    required int term,
    required int month,
    required List<Student> students,
    required List<AssessmentItem> assessmentItems,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = month == 4 ? 'متوسط_${subject.name}_الترم' : 'درجات_${subject.name}_شهر$month';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    // Header row
    final List<CellValue> headers = [
      TextCellValue('رقم الجلوس'),
      TextCellValue('اسم الطالب'),
    ];

    if (subject.isPassFail) {
      headers.add(TextCellValue('النتيجة (اجتاز / لم يجتز)'));
    } else {
      for (final item in assessmentItems) {
        if (month == 3 && !item.existsInMonth3) continue;
        final label = month == 4 ? '${item.itemName} (متوسط)' : '${item.itemName} (${item.maxScore.toInt()})';
        headers.add(TextCellValue(label));
      }
    }

    sheet.appendRow(headers);

    final db = DatabaseHelper.instance.yearDb;

    // Append student rows
    for (final student in students) {
      final List<CellValue> row = [
        TextCellValue(student.seatingNumber),
        TextCellValue(student.name),
      ];

      if (subject.isPassFail) {
        row.add(TextCellValue('اجتاز'));
      } else {
        for (final item in assessmentItems) {
          if (month == 3 && !item.existsInMonth3) continue;

          final recMaps = await db.query(
            'grade_records',
            where: 'seating_number = ? AND subject_id = ? AND assessment_item_id = ? AND term = ?',
            whereArgs: [student.seatingNumber, subject.id, item.id, term],
          );

          if (recMaps.isNotEmpty) {
            final rec = GradeRecord.fromMap(recMaps.first);
            if (month == 4) {
              final isMonthExam = item.itemName.contains('اختبار');
              final avg = rec.calculateAverage(isMonthExam: isMonthExam);
              row.add(TextCellValue(avg != null ? avg.toStringAsFixed(2) : '-'));
            } else if (month == 1) {
              row.add(TextCellValue(rec.month1Score != null ? rec.month1Score!.toString() : ''));
            } else if (month == 2) {
              row.add(TextCellValue(rec.month2Score != null ? rec.month2Score!.toString() : ''));
            } else if (month == 3) {
              row.add(TextCellValue(rec.month3Score != null ? rec.month3Score!.toString() : ''));
            }
          } else {
            row.add(TextCellValue(''));
          }
        }
      }
      sheet.appendRow(row);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final fileName = month == 4
        ? 'كشف_متوسطات_${subject.name}_فصل_${className}_الترم_$term.xlsx'
        : 'كشف_درجات_${subject.name}_فصل_${className}_شهر_$month.xlsx';

    final saveUri = await FilePicker.saveFile(
      dialogTitle: 'حفظ كشف درجات Excel',
      fileName: fileName,
      bytes: Uint8List.fromList(fileBytes),
    );

    if (saveUri != null) {
      return saveUri.toFilePath();
    }
    return null;
  }

  /// Parse imported Excel grade sheet and return GradeRecords + validation warnings
  static Future<ExcelGradeParseResult> parseGradeExcel({
    required String filePath,
    required Subject subject,
    required int term,
    required int month,
    required List<AssessmentItem> assessmentItems,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final List<GradeRecord> gradeRecords = [];
    final List<ExcelGradeRowPreview> previewRows = [];
    final List<String> warnings = [];

    final sheetName = excel.tables.keys.first;
    final table = excel.tables[sheetName];

    if (table == null || table.rows.isEmpty) {
      return ExcelGradeParseResult(
        gradeRecords: [],
        previewRows: [],
        warnings: ['ملف Excel فارغ ولا يحتوي على بيانات!'],
        isValid: false,
      );
    }

    // Map column indices to seatingNumber, studentName, and assessmentItemId
    int seatingIdx = -1;
    int nameIdx = -1;
    final Map<int, AssessmentItem> colToItem = {};

    final firstRow = table.rows.first;
    for (int i = 0; i < firstRow.length; i++) {
      final val = firstRow[i]?.value?.toString().trim() ?? '';
      if (val.contains('جلوس')) {
        seatingIdx = i;
      } else if (val.contains('اسم')) {
        nameIdx = i;
      } else {
        for (final item in assessmentItems) {
          if (val.contains(item.itemName)) {
            colToItem[i] = item;
            break;
          }
        }
      }
    }

    if (seatingIdx == -1) {
      return ExcelGradeParseResult(
        gradeRecords: [],
        previewRows: [],
        warnings: ['عمود "رقم الجلوس" غير موجود في ملف Excel!'],
        isValid: false,
      );
    }

    for (int r = 1; r < table.rows.length; r++) {
      final row = table.rows[r];
      if (row.isEmpty) continue;

      final seating = row.length > seatingIdx ? row[seatingIdx]?.value?.toString().trim() ?? '' : '';
      final name = (nameIdx != -1 && row.length > nameIdx) ? row[nameIdx]?.value?.toString().trim() ?? '' : '';

      if (seating.isEmpty) continue; // Skip empty rows

      final Map<int, double?> itemScores = {};
      final Map<int, String?> itemErrors = {};
      bool rowHasError = false;

      colToItem.forEach((colIdx, item) {
        if (row.length > colIdx) {
          final cellVal = row[colIdx]?.value?.toString().trim();
          if (cellVal != null && cellVal.isNotEmpty) {
            final parsedNum = double.tryParse(cellVal);
            if (parsedNum == null) {
              itemErrors[item.id!] = 'قيمة غير صالحة';
              rowHasError = true;
              warnings.add('سطر ${r + 1}: الدرجة "$cellVal" غير رقمية لبند ${item.itemName} للطالب $seating');
            } else if (parsedNum < 0 || parsedNum > item.maxScore) {
              itemErrors[item.id!] = 'تجاوز النهاية العظمى (${item.maxScore.toInt()})';
              rowHasError = true;
              warnings.add('سطر ${r + 1}: الدرجة ($parsedNum) تتجاوز العظمى (${item.maxScore.toInt()}) لبند ${item.itemName} للطالب $seating');
            } else {
              itemScores[item.id!] = parsedNum;
            }
          }
        }
      });

      previewRows.add(ExcelGradeRowPreview(
        seatingNumber: seating,
        studentName: name,
        scores: itemScores,
        cellErrors: itemErrors,
        hasError: rowHasError,
      ));

      // Construct GradeRecord for valid item scores
      itemScores.forEach((itemId, score) {
        gradeRecords.add(GradeRecord(
          seatingNumber: seating,
          subjectId: subject.id!,
          assessmentItemId: itemId,
          term: term,
          month1Score: month == 1 ? score : null,
          month2Score: month == 2 ? score : null,
          month3Score: month == 3 ? score : null,
        ));
      });
    }

    return ExcelGradeParseResult(
      gradeRecords: gradeRecords,
      previewRows: previewRows,
      warnings: warnings,
      isValid: warnings.isEmpty && previewRows.isNotEmpty,
    );
  }
}
