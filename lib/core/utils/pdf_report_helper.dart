import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database/database_helper.dart';
import '../../models/student.dart';
import '../../models/subject.dart';
import '../../models/grade_record.dart';
import '../../models/assessment_item.dart';

class PdfReportHelper {
  static pw.Font? _arabicFont;

  /// Load Arabic font for PDF documents
  static Future<pw.Font> _loadArabicFont() async {
    if (_arabicFont != null) return _arabicFont!;
    final fontData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf');
    _arabicFont = pw.Font.ttf(fontData);
    return _arabicFont!;
  }

  /// Export Compiled Grade Sheet as Excel (.xlsx)
  static Future<String?> exportCompiledExcel({
    required String gradeLevel,
    String? className,
    required int term,
  }) async {
    final db = DatabaseHelper.instance.yearDb;

    // Fetch subjects for this grade
    final subMaps = await db.query(
      'subjects',
      where: 'grade_level = ? AND assessment_type = ?',
      whereArgs: [gradeLevel, 'grades'],
      orderBy: 'id ASC',
    );
    final subjects = subMaps.map((m) => Subject.fromMap(m)).toList();

    // Fetch students
    List<Map<String, dynamic>> studentMaps;
    if (className != null && className.isNotEmpty && className != 'الكل') {
      studentMaps = await db.query(
        'students',
        where: 'stage = ? AND class_name = ?',
        whereArgs: [gradeLevel, className],
        orderBy: 'seating_number ASC',
      );
    } else {
      studentMaps = await db.query(
        'students',
        where: 'stage = ?',
        whereArgs: [gradeLevel],
        orderBy: 'seating_number ASC',
      );
    }
    final students = studentMaps.map((m) => Student.fromMap(m)).toList();

    // Create Excel
    final excel = Excel.createExcel();
    final sheetName = className != null && className != 'الكل' ? 'فصل $className' : 'المرحلة';
    final sheet = excel[sheetName];

    // Headers
    final headers = [
      TextCellValue('رقم الجلوس'),
      TextCellValue('اسم الطالب'),
      TextCellValue('الفصل'),
      ...subjects.map((s) => TextCellValue(s.name)),
      TextCellValue('متوسط المجموع الكلي'),
    ];
    sheet.appendRow(headers);

    // Rows
    for (final student in students) {
      final row = <CellValue>[
        TextCellValue(student.seatingNumber),
        TextCellValue(student.name),
        TextCellValue(student.className),
      ];

      double totalSum = 0.0;
      int activeSubjectCount = 0;

      for (final sub in subjects) {
        final recMaps = await db.query(
          'grade_records',
          where: 'seating_number = ? AND subject_id = ? AND term = ?',
          whereArgs: [student.seatingNumber, sub.id, term],
        );

        double subAvgSum = 0.0;

        for (final m in recMaps) {
          final rec = GradeRecord.fromMap(m);
          final isMonthExam = false; // standard item
          final avg = rec.calculateAverage(isMonthExam: isMonthExam);
          if (avg != null) {
            subAvgSum += avg;
          }
        }

        if (subAvgSum > 0) {
          row.add(DoubleCellValue(double.parse(subAvgSum.toStringAsFixed(2))));
          totalSum += subAvgSum;
          activeSubjectCount++;
        } else {
          row.add(TextCellValue('-'));
        }
      }

      if (activeSubjectCount > 0) {
        row.add(DoubleCellValue(double.parse(totalSum.toStringAsFixed(2))));
      } else {
        row.add(TextCellValue('-'));
      }

      sheet.appendRow(row);
    }

    final bytes = excel.save();
    if (bytes == null) return null;

    final defaultFileName = 'كشف_مجمع_${gradeLevel}_ترم$term.xlsx';
    final saveResult = await FilePicker.saveFile(
      dialogTitle: 'حفظ كشف الرصد المجمع',
      fileName: defaultFileName,
      bytes: Uint8List.fromList(bytes),
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    return saveResult?.path;
  }

  /// Generate Compiled Grade Sheet PDF Bytes (كشف الرصد المجمع لكافة المواد للمرحلة/الفصل)
  static Future<Uint8List> buildCompiledGradePdf({
    required String gradeLevel,
    String? className,
    required int term,
    required String schoolName,
    required String academicYearName,
  }) async {
    final font = await _loadArabicFont();
    final db = DatabaseHelper.instance.yearDb;

    final subMaps = await db.query(
      'subjects',
      where: 'grade_level = ? AND assessment_type = ?',
      whereArgs: [gradeLevel, 'grades'],
      orderBy: 'id ASC',
    );
    final subjects = subMaps.map((m) => Subject.fromMap(m)).toList();

    List<Map<String, dynamic>> studentMaps;
    if (className != null && className.isNotEmpty && className != 'الكل') {
      studentMaps = await db.query(
        'students',
        where: 'stage = ? AND class_name = ?',
        whereArgs: [gradeLevel, className],
        orderBy: 'seating_number ASC',
      );
    } else {
      studentMaps = await db.query(
        'students',
        where: 'stage = ?',
        whereArgs: [gradeLevel],
        orderBy: 'seating_number ASC',
      );
    }
    final students = studentMaps.map((m) => Student.fromMap(m)).toList();

    final doc = pw.Document();
    final termText = term == 1 ? "الفصل الدراسي الأول" : "الفصل الدراسي الثاني";
    final primaryColor = PdfColor.fromInt(0xFF153243);

    // Build data rows for compiled PDF
    final List<List<String>> tableData = [];

    for (final student in students) {
      final row = <String>[
        student.seatingNumber,
        student.name,
        student.className,
      ];

      double totalSum = 0.0;
      bool hasAnyGrade = false;

      for (final sub in subjects) {
        final recMaps = await db.query(
          'grade_records',
          where: 'seating_number = ? AND subject_id = ? AND term = ?',
          whereArgs: [student.seatingNumber, sub.id, term],
        );

        double subAvgSum = 0.0;

        for (final m in recMaps) {
          final rec = GradeRecord.fromMap(m);
          final avg = rec.calculateAverage(isMonthExam: false);
          if (avg != null) {
            subAvgSum += avg;
          }
        }

        if (subAvgSum > 0) {
          row.add(subAvgSum.toStringAsFixed(2));
          totalSum += subAvgSum;
          hasAnyGrade = true;
        } else {
          row.add('-');
        }
      }

      row.add(hasAnyGrade ? totalSum.toStringAsFixed(2) : '-');
      tableData.add(row);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
          italic: font,
          boldItalic: font,
          fontFallback: [font],
        ),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            // Header (RTL Page Layout: Right = School info, Left = Date/Class)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      className != null && className != 'الكل' ? "الفصل: $className" : "جميع الفصول",
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: font),
                    ),
                    pw.Text("تاريخ الاستخراج: ${DateTime.now().toString().split(' ').first}", style: pw.TextStyle(fontSize: 9, font: font)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      "كشف الرصد المجمع لمواد الملف الصفّي",
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor, font: font),
                    ),
                    pw.Text("$gradeLevel - $termText", style: pw.TextStyle(fontSize: 11, font: font)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      schoolName.isEmpty ? "المدرسة: ...................." : schoolName,
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor, font: font),
                    ),
                    pw.Text("العام الدراسي: $academicYearName", style: pw.TextStyle(fontSize: 10, font: font)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),

            // Grade Table
            pw.TableHelper.fromTextArray(
              tableDirection: pw.TextDirection.rtl,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerHeight: 25,
              cellHeight: 22,
              cellAlignment: pw.Alignment.center,
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font),
              cellStyle: pw.TextStyle(fontSize: 8, font: font),
              headers: [
                'رقم الجلوس',
                'اسم الطالب',
                'الفصل',
                ...subjects.map((s) => s.name),
                'المجموع الكلي',
              ],
              data: tableData,
            ),

            pw.SizedBox(height: 20),
            // Signatures Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text("يعتمد مدير المدرسة: ....................", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: font)),
                pw.Text("مُعِد الكشف: ....................", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: font)),
              ],
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// Generate Student Monthly Grade Card PDF Bytes (إشعار / كشف درجات الطالب الشهري مفصلاً)
  static Future<Uint8List> buildStudentCertificatePdf({
    required Student student,
    required String gradeLevel,
    required int term,
    required int month, // 1: شهر 1, 2: شهر 2, 3: شهر 3, 4: متوسط الترم الكلي
    required String schoolName,
    required String academicYearName,
  }) async {
    final font = await _loadArabicFont();
    final doc = pw.Document();
    final termText = term == 1 ? "الفصل الدراسي الأول" : "الفصل الدراسي الثاني";
    final monthText = month == 4 ? "متوسطات الفصل الدراسي الكلي" : "درجات شهر ($month)";
    final primaryColor = PdfColor.fromInt(0xFF153243);

    final db = DatabaseHelper.instance.yearDb;
    final subjectsMap = await db.query(
      'subjects',
      where: 'grade_level = ?',
      whereArgs: [gradeLevel],
      orderBy: 'id ASC',
    );
    final subjects = subjectsMap.map((m) => Subject.fromMap(m)).toList();

    final List<String> itemHeaders = [
      'واجب منزلي (5)',
      'كراسة الحصة (5)',
      'تقييم أسبوعي (10)',
      'اختبارات الشهور (15)',
      'مواظبة وسلوك (5)',
    ];

    // Build detailed item-by-item breakdown rows for the student from DB
    final List<List<String>> tableData = [];

    for (final sub in subjects) {
      final recMaps = await db.query(
        'grade_records',
        where: 'seating_number = ? AND subject_id = ? AND term = ?',
        whereArgs: [student.seatingNumber, sub.id, term],
      );

      final itemMaps = await db.query(
        'assessment_items',
        where: 'subject_id = ?',
        whereArgs: [sub.id],
        orderBy: 'id ASC',
      );
      final items = itemMaps.map((m) => AssessmentItem.fromMap(m)).toList();

      final List<String> rowValues = [sub.name];
      double totalRowSum = 0.0;

      for (int i = 0; i < 5; i++) {
        if (i < items.length) {
          final item = items[i];
          final recMap = recMaps.firstWhere(
            (r) => r['assessment_item_id'] == item.id,
            orElse: () => {},
          );

          if (recMap.isNotEmpty) {
            final rec = GradeRecord.fromMap(recMap);
            if (month == 4) {
              final isMonthExam = item.itemName.contains('اختبار');
              final avg = rec.calculateAverage(isMonthExam: isMonthExam);
              if (avg != null) {
                totalRowSum += avg;
                rowValues.add(avg.toStringAsFixed(2));
              } else {
                rowValues.add('-');
              }
            } else {
              double? score;
              if (month == 1) score = rec.month1Score;
              if (month == 2) score = rec.month2Score;
              if (month == 3) score = rec.month3Score;

              if (score != null) {
                totalRowSum += score;
                rowValues.add(score.toStringAsFixed(2));
              } else {
                rowValues.add('-');
              }
            }
          } else {
            rowValues.add('-');
          }
        } else {
          rowValues.add('-');
        }
      }

      rowValues.add(totalRowSum > 0 ? totalRowSum.toStringAsFixed(2) : '-');
      tableData.add(rowValues);
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
          italic: font,
          boldItalic: font,
          fontFallback: [font],
        ),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryColor, width: 3),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header (RTL Page Layout: Right = Ministry/School info, Left = Year/Term info)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("العام الدراسي: $academicYearName", style: pw.TextStyle(fontSize: 10, font: font)),
                        pw.Text("$termText - $monthText", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: font)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("جمهورية مصر العربية", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: font)),
                        pw.Text("وزارة التربية والتعليم", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: font)),
                        pw.Text(
                          schoolName.trim().isEmpty ? "المدرسة: ...................." : schoolName.trim(),
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor, font: font),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),

                // Card Title
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      "إشعار درجات تقييم الملف ($monthText)",
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold, font: font),
                    ),
                  ),
                ),
                pw.SizedBox(height: 14),

                // Student Info Box (RTL: Right = Student Name, Left = Class Name)
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("الفصل: ${student.className}", style: pw.TextStyle(fontSize: 10, font: font)),
                      pw.Text("الصف: $gradeLevel", style: pw.TextStyle(fontSize: 10, font: font)),
                      pw.Text("رقم الجلوس: ${student.seatingNumber}", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: font)),
                      pw.Text("اسم الطالب: ${student.name}", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor, font: font)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // Detailed Item Breakdown Table
                pw.Text(
                  "تفصيل درجات بنود تقييم الملف لكل مادة ($monthText):",
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor, font: font),
                ),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  tableDirection: pw.TextDirection.rtl,
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                  headerDecoration: pw.BoxDecoration(color: primaryColor),
                  headerHeight: 24,
                  cellHeight: 22,
                  cellAlignment: pw.Alignment.center,
                  headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font),
                  cellStyle: pw.TextStyle(fontSize: 9, font: font),
                  headers: [
                    'المادة الدراسية',
                    ...itemHeaders,
                    month == 4 ? 'مجموع المتوسطات' : 'المجموع الكلي',
                  ],
                  data: tableData,
                ),
                pw.Spacer(),

                // Signatures Footer (Teacher & Principal only, RTL layout)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text("يعتمد مدير المدرسة: ....................", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: font)),
                    pw.Text("معلم / معلمة المادة: ....................", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: font)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  /// Print or Save PDF
  static Future<void> printOrSavePdf(Uint8List pdfBytes, String jobTitle) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: jobTitle,
    );
  }
}
