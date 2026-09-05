import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../models/student.dart';

class ReportVariable {
  final String key;
  final String label;
  final String category;
  final String exampleValue;

  const ReportVariable({
    required this.key,
    required this.label,
    required this.category,
    required this.exampleValue,
  });
}
class TemplatePreset {
  final String id;
  final String title;
  final String reportTitle;
  final String headerNotes;
  final String footerNotes;
  final bool showTable;
  final bool showStudentCard;
  final bool showSignatures;

  const TemplatePreset({
    required this.id,
    required this.title,
    required this.reportTitle,
    required this.headerNotes,
    required this.footerNotes,
    required this.showTable,
    required this.showStudentCard,
    required this.showSignatures,
  });
}

class WysiwygTemplateHelper {
  static pw.Font? _arabicFont;

  /// Built-in Presets for 1-click template selection
  static const List<TemplatePreset> presets = [
    TemplatePreset(
      id: 'monthly_notice',
      title: 'إشعار درجات تفصيلي',
      reportTitle: 'إشعار درجات الشهور ومجموع التقييمات للطالب {{اسم_الطالب}}',
      headerNotes: 'نحيطكم علماً بأن الطالب {{اسم_الطالب}} المقيد بالفصل {{الفصل}} حقق في شهر 1: ({{درجة_شهر_1}}) وفي شهر 2: ({{درجة_شهر_2}}) وفي شهر 3: ({{درجة_شهر_3}}).',
      footerNotes: 'إشعار رسمي معتمد بتاريخ {{التاريخ}} - التقدير العام: {{التقدير_العام}}.',
      showTable: true,
      showStudentCard: true,
      showSignatures: true,
    ),
    TemplatePreset(
      id: 'excellence_cert',
      title: 'شهادة تفوق وتقدير',
      reportTitle: 'شهادة تفوق وتقدير في بنود تقييم ملف المادة',
      headerNotes: 'تتقدم إدارة المدرسة بخالص التهنئة للطالب المتميز {{اسم_الطالب}} المقيد بالفصل {{الفصل}} لحصوله على متوسط شهور قدره ({{متوسط_الشهور}}) بتقدير {{التقدير_العام}}.',
      footerNotes: 'مع أطيب تمنياتنا بدوام التوفيق والنجاح - حررت بتاريخ {{التاريخ}}.',
      showTable: false,
      showStudentCard: true,
      showSignatures: true,
    ),
    TemplatePreset(
      id: 'term_averages',
      title: 'كشف متوسطات الشهور',
      reportTitle: 'بيان مجموع ومتوسطات درجات الشهور الكلي',
      headerNotes: 'كشف تفصيلي يوضح متوسط درجات الشهور وبنود تقييم الملف الكلي لـ {{الترم}} للعام الدراسي {{العام_الدراسي}}.',
      footerNotes: 'مجموع متوسطات المواد: {{مجموع_المتوسطات}} - نسبة النجاح العامة: {{نسبة_المتوسط}}.',
      showTable: true,
      showStudentCard: true,
      showSignatures: true,
    ),
    TemplatePreset(
      id: 'parent_notice',
      title: 'متابعة ولي الأمر',
      reportTitle: 'إشعار متابعة درجات وانضباط الطالب {{اسم_الطالب}}',
      headerNotes: 'يرجى العلم بأن متوسط درجات تقييمات الطالب {{اسم_الطالب}} بلغ ({{متوسط_الشهور}}) بتقدير {{التقدير_العام}}.',
      footerNotes: 'توقيع ولي الأمر بالعلم: .................... - تاريخ الاطلاع: {{التاريخ}}.',
      showTable: true,
      showStudentCard: true,
      showSignatures: true,
    ),
  ];

  /// Load Arabic font for PDF documents
  static Future<pw.Font> _loadArabicFont() async {
    if (_arabicFont != null) return _arabicFont!;
    final fontData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf');
    _arabicFont = pw.Font.ttf(fontData);
    return _arabicFont!;
  }

  /// Available variables for template editor
  static const List<ReportVariable> availableVariables = [
    // Student Metadata
    ReportVariable(key: '{{اسم_الطالب}}', label: 'اسم الطالب', category: 'بيانات الطالب', exampleValue: 'عمر أحمد نور الدين'),
    ReportVariable(key: '{{رقم_الجلوس}}', label: 'رقم الجلوس', category: 'بيانات الطالب', exampleValue: '219'),
    ReportVariable(key: '{{الصف}}', label: 'الصف الدراسي', category: 'بيانات الطالب', exampleValue: 'الصف الأول الإعدادي'),
    ReportVariable(key: '{{الفصل}}', label: 'الفصل', category: 'بيانات الطالب', exampleValue: '1/2'),

    // School Metadata
    ReportVariable(key: '{{المدرسة}}', label: 'اسم المدرسة', category: 'بيانات التقرير', exampleValue: 'مدرسة الرصد الإعدادية'),
    ReportVariable(key: '{{العام_الدراسي}}', label: 'العام الدراسي', category: 'بيانات التقرير', exampleValue: '2025/2026'),
    ReportVariable(key: '{{الترم}}', label: 'الفصل الدراسي', category: 'بيانات التقرير', exampleValue: 'الفصل الدراسي الأول'),
    ReportVariable(key: '{{التاريخ}}', label: 'تاريخ اليوم', category: 'بيانات التقرير', exampleValue: '2026-09-05'),

    // Month Scores Variables
    ReportVariable(key: '{{درجة_شهر_1}}', label: 'درجة شهر 1', category: 'درجات الشهور', exampleValue: '48.50'),
    ReportVariable(key: '{{درجة_شهر_2}}', label: 'درجة شهر 2', category: 'درجات الشهور', exampleValue: '49.00'),
    ReportVariable(key: '{{درجة_شهر_3}}', label: 'درجة شهر 3', category: 'درجات الشهور', exampleValue: '50.00'),

    // Month Averages Variables
    ReportVariable(key: '{{متوسط_الشهور}}', label: 'متوسط الشهور', category: 'متوسطات الشهور', exampleValue: '49.17'),
    ReportVariable(key: '{{مجموع_المتوسطات}}', label: 'مجموع المتوسطات', category: 'متوسطات الشهور', exampleValue: '245.85'),
    ReportVariable(key: '{{التقدير_العام}}', label: 'التقدير العام', category: 'متوسطات الشهور', exampleValue: 'ممتاز'),
    ReportVariable(key: '{{نسبة_المتوسط}}', label: 'نسبة المتوسط %', category: 'متوسطات الشهور', exampleValue: '98.3%'),
  ];

  /// Replace all {{variable}} tags with values
  static String parseTemplateText({
    required String template,
    required Student? student,
    required String gradeLevel,
    required String schoolName,
    required String academicYearName,
    required int term,
    double month1Sum = 48.50,
    double month2Sum = 49.00,
    double month3Sum = 50.00,
    double termAvgSum = 49.17,
    double totalAvgSum = 245.85,
  }) {
    if (template.isEmpty) return '';

    final termText = term == 1 ? "الفصل الدراسي الأول" : "الفصل الدراسي الثاني";
    final todayStr = DateTime.now().toString().split(' ').first;

    // Estimate rating label from average
    String rating = 'ممتاز';
    final percentage = totalAvgSum > 0 ? (totalAvgSum / 250.0) * 100 : 98.3;
    if (percentage >= 85) {
      rating = 'ممتاز';
    } else if (percentage >= 75) {
      rating = 'جيد جداً';
    } else if (percentage >= 65) {
      rating = 'جيد';
    } else if (percentage >= 50) {
      rating = 'مقبول';
    } else {
      rating = 'دون المستوى';
    }

    String result = template;
    result = result.replaceAll('{{اسم_الطالب}}', student?.name ?? 'عمر أحمد نور الدين');
    result = result.replaceAll('{{رقم_الجلوس}}', student?.seatingNumber ?? '219');
    result = result.replaceAll('{{الصف}}', gradeLevel);
    result = result.replaceAll('{{الفصل}}', student?.className ?? '1');
    result = result.replaceAll('{{المدرسة}}', schoolName.trim().isEmpty ? 'مدرسة الرصد' : schoolName.trim());
    result = result.replaceAll('{{العام_الدراسي}}', academicYearName);
    result = result.replaceAll('{{الترم}}', termText);
    result = result.replaceAll('{{التاريخ}}', todayStr);

    result = result.replaceAll('{{درجة_شهر_1}}', month1Sum > 0 ? month1Sum.toStringAsFixed(2) : '48.50');
    result = result.replaceAll('{{درجة_شهر_2}}', month2Sum > 0 ? month2Sum.toStringAsFixed(2) : '49.00');
    result = result.replaceAll('{{درجة_شهر_3}}', month3Sum > 0 ? month3Sum.toStringAsFixed(2) : '50.00');

    result = result.replaceAll('{{متوسط_الشهور}}', termAvgSum > 0 ? termAvgSum.toStringAsFixed(2) : '49.17');
    result = result.replaceAll('{{مجموع_المتوسطات}}', totalAvgSum > 0 ? totalAvgSum.toStringAsFixed(2) : '245.85');
    result = result.replaceAll('{{التقدير_العام}}', rating);
    result = result.replaceAll('{{نسبة_المتوسط}}', '${percentage.toStringAsFixed(1)}%');

    return result;
  }

  /// Export Custom WYSIWYG Template as PDF (100% RTL compliant)
  static Future<Uint8List> buildCustomTemplatePdf({
    required String titleText,
    required String headerNoteText,
    required String footerNoteText,
    required String managerTitle,
    required String principalTitle,
    required String schoolName,
    required String academicYearName,
    required String gradeLevel,
    required int term,
    required int selectedMonth,
    required Student? sampleStudent,
    required List<Map<String, dynamic>> rowsData,
    required PdfColor primaryThemeColor,
    required bool showTable,
    required bool showStudentInfoBox,
    required bool showSignatures,
  }) async {
    final font = await _loadArabicFont();
    final doc = pw.Document();

    final parsedTitle = parseTemplateText(
      template: titleText,
      student: sampleStudent,
      gradeLevel: gradeLevel,
      schoolName: schoolName,
      academicYearName: academicYearName,
      term: term,
    );

    final parsedHeaderNote = parseTemplateText(
      template: headerNoteText,
      student: sampleStudent,
      gradeLevel: gradeLevel,
      schoolName: schoolName,
      academicYearName: academicYearName,
      term: term,
    );

    final parsedFooterNote = parseTemplateText(
      template: footerNoteText,
      student: sampleStudent,
      gradeLevel: gradeLevel,
      schoolName: schoolName,
      academicYearName: academicYearName,
      term: term,
    );

    final termText = term == 1 ? "الفصل الدراسي الأول" : "الفصل الدراسي الثاني";
    final monthText = selectedMonth == 4 ? "متوسط الترم الكلي" : "درجات شهر ($selectedMonth)";

    final List<String> itemHeaders = [
      'واجب منزلي (5)',
      'كراسة الحصة (5)',
      'تقييم أسبوعي (10)',
      'اختبار الشهور (15)',
      'مواظبة وسلوك (5)',
    ];

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
              border: pw.Border.all(color: primaryThemeColor, width: 3),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header (RTL: Right = Ministry/School, Left = Year/Term)
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
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryThemeColor, font: font),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),

                // Card Title
                if (parsedTitle.isNotEmpty)
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: primaryThemeColor,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        parsedTitle,
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 15, fontWeight: pw.FontWeight.bold, font: font),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 14),

                // Header Note
                if (parsedHeaderNote.isNotEmpty) ...[
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(parsedHeaderNote, style: pw.TextStyle(fontSize: 10, font: font)),
                  ),
                  pw.SizedBox(height: 14),
                ],

                // Student Info Box
                if (showStudentInfoBox && sampleStudent != null) ...[
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
                        pw.Text("الفصل: ${sampleStudent.className}", style: pw.TextStyle(fontSize: 10, font: font)),
                        pw.Text("الصف: $gradeLevel", style: pw.TextStyle(fontSize: 10, font: font)),
                        pw.Text("رقم الجلوس: ${sampleStudent.seatingNumber}", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: font)),
                        pw.Text("اسم الطالب: ${sampleStudent.name}", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryThemeColor, font: font)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 14),
                ],

                // Grade Table
                if (showTable && rowsData.isNotEmpty) ...[
                  pw.TableHelper.fromTextArray(
                    tableDirection: pw.TextDirection.rtl,
                    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                    headerDecoration: pw.BoxDecoration(color: primaryThemeColor),
                    headerHeight: 24,
                    cellHeight: 22,
                    cellAlignment: pw.Alignment.center,
                    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: font),
                    cellStyle: pw.TextStyle(fontSize: 9, font: font),
                    headers: [
                      'المادة الدراسية',
                      ...itemHeaders,
                      selectedMonth == 4 ? 'مجموع المتوسطات' : 'المجموع الكلي',
                    ],
                    data: rowsData.map((row) {
                      final List<String> scores = List<String>.from(row['scores']);
                      return [
                        row['subjectName'].toString(),
                        ...scores,
                        row['total'].toString(),
                      ];
                    }).toList(),
                  ),
                  pw.SizedBox(height: 14),
                ],

                // Footer Note
                if (parsedFooterNote.isNotEmpty) ...[
                  pw.Text(parsedFooterNote, style: pw.TextStyle(fontSize: 10, font: font, color: PdfColors.grey800)),
                  pw.SizedBox(height: 14),
                ],

                pw.Spacer(),

                // Signatures Footer
                if (showSignatures)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Text("$principalTitle: ....................", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: font)),
                      pw.Text("$managerTitle: ....................", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: font)),
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

  /// Print directly using printing package
  static Future<void> printTemplatePdf(Uint8List pdfBytes, String jobTitle) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: jobTitle,
    );
  }
}
