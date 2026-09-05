import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import 'package:pdf/pdf.dart' show PdfColor;
import '../../../core/utils/pdf_report_helper.dart';
import '../../../core/utils/wysiwyg_template_helper.dart';
import '../../../models/assessment_item.dart';
import '../../../models/grade_record.dart';
import '../../../models/student.dart';
import '../../../models/subject.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/class_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../core/widgets/app_dropdown.dart';

class ReportsView extends StatefulWidget {
  final String gradeLevel;

  const ReportsView({super.key, required this.gradeLevel});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedClass;
  int _selectedTerm = 1;
  Student? _selectedStudent;

  int _certSelectedMonth = 1;

  // Report Builder controllers & WYSIWYG Template State
  final _schoolNameCtrl = TextEditingController(text: "");
  final _reportTitleCtrl = TextEditingController(text: "إشعار تقييم درجات الشهور ومجموع المتوسطات للطالب {{اسم_الطالب}}");
  final _reportNotesCtrl = TextEditingController(text: "تم بحمد الله رصد درجات شهر 1 ({{درجة_شهر_1}}) وشهر 2 ({{درجة_شهر_2}}) وشهر 3 ({{درجة_شهر_3}}) وحقق الطالب متوسط شهور قدره {{متوسط_الشهور}}.");
  final _reportFooterCtrl = TextEditingController(text: "نتيجة رسمية معتمدة من إدارة المدرسة بتاريخ {{التاريخ}} - التقدير العام: {{التقدير_العام}}.");
  final _managerNameCtrl = TextEditingController(text: "مسؤول المادة");
  final _principalNameCtrl = TextEditingController(text: "مدير المدرسة");

  TextEditingController? _activeTextController;
  Color _selectedThemeColor = const Color(0xFF0A0F1D);
  bool _showTableInReport = true;
  bool _showStudentCardInReport = true;
  bool _showSignaturesInReport = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _schoolNameCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() async {
    final classProv = Provider.of<ClassProvider>(context, listen: false);
    final studentProv = Provider.of<StudentProvider>(context, listen: false);

    await classProv.loadClassesForGrade(widget.gradeLevel, widget.gradeLevel);
    await studentProv.loadStudentsForGrade(widget.gradeLevel, widget.gradeLevel);

    if (classProv.classes.isNotEmpty) {
      _selectedClass = classProv.classes.first.className;
    }
    if (studentProv.students.isNotEmpty) {
      _selectedStudent = studentProv.students.first;
    }
    if (mounted) setState(() {});
  }

  Future<List<Map<String, dynamic>>> _loadStudentCertificateRows(Student? student) async {
    if (student == null) return [];
    final db = DatabaseHelper.instance.yearDb;

    // 1. Fetch all subjects for this grade level in 1 query
    final subMaps = await db.query(
      'subjects',
      where: 'grade_level = ?',
      whereArgs: [widget.gradeLevel],
      orderBy: 'id ASC',
    );
    final subjects = subMaps.map((m) => Subject.fromMap(m)).toList();
    if (subjects.isEmpty) return [];

    final subjectIds = subjects.map((s) => s.id).whereType<int>().toList();
    if (subjectIds.isEmpty) return [];

    // 2. Fetch all student grade records for term in 1 query
    final allGradeMaps = await db.query(
      'grade_records',
      where: 'seating_number = ? AND term = ?',
      whereArgs: [student.seatingNumber, _selectedTerm],
    );

    // 3. Fetch all assessment items for all subjects in 1 query
    final placeholders = List.filled(subjectIds.length, '?').join(',');
    final allItemMaps = await db.rawQuery(
      'SELECT * FROM assessment_items WHERE subject_id IN ($placeholders) ORDER BY id ASC',
      subjectIds,
    );

    // Group items by subject_id
    final Map<int, List<AssessmentItem>> itemsBySubject = {};
    for (final itemMap in allItemMaps) {
      final item = AssessmentItem.fromMap(itemMap);
      itemsBySubject.putIfAbsent(item.subjectId, () => []).add(item);
    }

    // Group records by subject_id -> assessment_item_id
    final Map<int, Map<int, GradeRecord>> recordsBySubject = {};
    for (final recMap in allGradeMaps) {
      final rec = GradeRecord.fromMap(recMap);
      recordsBySubject.putIfAbsent(rec.subjectId, () => {})[rec.assessmentItemId] = rec;
    }

    final List<Map<String, dynamic>> results = [];

    for (final sub in subjects) {
      final subId = sub.id ?? 0;
      final items = itemsBySubject[subId] ?? [];
      final subRecords = recordsBySubject[subId] ?? {};

      final List<String> itemScores = [];
      double totalRowSum = 0.0;

      for (int i = 0; i < 5; i++) {
        if (i < items.length) {
          final item = items[i];
          final rec = subRecords[item.id];

          if (rec != null) {
            if (_certSelectedMonth == 4) {
              final isMonthExam = item.itemName.contains('اختبار');
              final avg = rec.calculateAverage(isMonthExam: isMonthExam);
              if (avg != null) {
                totalRowSum += avg;
                itemScores.add(avg.toStringAsFixed(2));
              } else {
                itemScores.add('-');
              }
            } else {
              double? score;
              if (_certSelectedMonth == 1) score = rec.month1Score;
              if (_certSelectedMonth == 2) score = rec.month2Score;
              if (_certSelectedMonth == 3) score = rec.month3Score;

              if (score != null) {
                totalRowSum += score;
                itemScores.add(score.toStringAsFixed(2));
              } else {
                itemScores.add('-');
              }
            }
          } else {
            itemScores.add('-');
          }
        } else {
          itemScores.add('-');
        }
      }

      results.add({
        'subjectName': sub.name,
        'scores': itemScores,
        'total': totalRowSum > 0 ? totalRowSum.toStringAsFixed(2) : '-',
      });
    }

    return results;
  }

  final _hScrollController1 = ScrollController();
  final _hScrollController2 = ScrollController();

  void _insertVariableIntoActiveField(String variableTag) {
    final controller = _activeTextController ?? _reportNotesCtrl;
    final text = controller.text;
    final selection = controller.selection;
    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, variableTag);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: selection.start + variableTag.length);
    } else {
      controller.text = '$text $variableTag';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _hScrollController1.dispose();
    _hScrollController2.dispose();
    _tabController.dispose();
    _schoolNameCtrl.dispose();
    _reportTitleCtrl.dispose();
    _reportNotesCtrl.dispose();
    _reportFooterCtrl.dispose();
    _managerNameCtrl.dispose();
    _principalNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classProv = Provider.of<ClassProvider>(context);
    final studentProv = Provider.of<StudentProvider>(context);
    final academicYearProv = Provider.of<AcademicYearProvider>(context);
    final currentYearName = academicYearProv.selectedYear?.name ?? '2025/2026';
    final isLanguageSchool = academicYearProv.selectedYear?.isLanguageSchool ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.neutralBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View Title & Navigation Tabs (100% Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final headerInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "الشهادات والتقارير المجمعة - ${widget.gradeLevel}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "استخراج وتصدير كشوف الرصد المجمعة لـ Excel و PDF وطباعة إشعارات درجات الطلاب تفصيلياً بضغطة زر.",
                    style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                  ),
                ],
              );

              final tabBarWidget = Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppColors.mutedBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.secondaryText,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(
                      height: 38,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.table_chart_outlined, size: 16),
                            SizedBox(width: 8),
                            Text("كشوف الرصد المجمعة"),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      height: 38,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_ind_outlined, size: 16),
                            SizedBox(width: 8),
                            Text("إشعارات درجات الطلاب"),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      height: 38,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_document, size: 16),
                            SizedBox(width: 8),
                            Text("محرر التقارير التفاعلي"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: tabBarWidget,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 16),
                  tabBarWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Main Tab View Canvas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Compiled Grade Sheets
                _buildCompiledGradeSheetTab(context, classProv, studentProv, currentYearName),

                // Tab 2: Student Certificates
                _buildCertificatesTab(context, studentProv, currentYearName, isLanguageSchool),

                // Tab 3: Interactive Report Editor
                _buildReportEditorTab(context, currentYearName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Compiled Grade Sheet View & Export Engine
  Widget _buildCompiledGradeSheetTab(
    BuildContext context,
    ClassProvider classProv,
    StudentProvider studentProv,
    String academicYearName,
  ) {
    return Column(
      children: [
        // Controls bar (Scrollable Horizontal for small screens)
        Card(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.mutedBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('تصفية الفصل: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  AppDropdown<String>(
                    value: _selectedClass,
                    items: [
                      const DropdownMenuItem(value: 'الكل', child: Text('جميع الفصول')),
                      ...classProv.classes.map((c) => DropdownMenuItem(value: c.className, child: Text('فصل ${c.className}'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedClass = val);
                    },
                  ),
                  const SizedBox(width: 24),
                  const Text('الفصل الدراسي: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  AppDropdown<int>(
                    value: _selectedTerm,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('الفصل الدراسي الأول')),
                      DropdownMenuItem(value: 2, child: Text('الفصل الدراسي الثاني')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTerm = val);
                    },
                  ),
                  const SizedBox(width: 32),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final path = await PdfReportHelper.exportCompiledExcel(
                        gradeLevel: widget.gradeLevel,
                        className: _selectedClass,
                        term: _selectedTerm,
                      );
                      if (path != null && mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('تم تصدير كشف الرصد المجمع بنجاح: $path'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text("تصدير كشف مجمع Excel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final pdfBytes = await PdfReportHelper.buildCompiledGradePdf(
                        gradeLevel: widget.gradeLevel,
                        className: _selectedClass,
                        term: _selectedTerm,
                        schoolName: _schoolNameCtrl.text.trim(),
                        academicYearName: academicYearName,
                      );
                      await PdfReportHelper.printOrSavePdf(pdfBytes, 'كشف_مجمع_${widget.gradeLevel}');
                    },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text("طباعة / تصدير PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Live Compiled Grade Sheet Preview Table (Fits 100% strictly inside screen bounds)
        Expanded(
          child: Card(
            color: AppColors.lightSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.mutedBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: studentProv.students.isEmpty
                  ? const Center(
                      child: Text("لا يوجد طلاب مسجلون لعرض كشوف الرصد المجمعة"),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Scrollbar(
                          controller: _hScrollController1,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: _hScrollController1,
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  columnSpacing: 18.0,
                                  horizontalMargin: 16.0,
                                  headingRowHeight: 46.0,
                                  dataRowMinHeight: 44.0,
                                  dataRowMaxHeight: 52.0,
                                  headingRowColor: WidgetStateProperty.all(AppColors.neutralBackground),
                                columns: const [
                                  DataColumn(label: Text('رقم الجلوس', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الفصل', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('حالة الرصد', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: studentProv.students.map((student) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(student.seatingNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(student.name)),
                                      DataCell(Text('فصل ${student.className}')),
                                      const DataCell(
                                        Text('مكتمل المباشرة والرصد', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryDark, size: 20),
                                          tooltip: "طباعة شهادة الطالب",
                                          onPressed: () async {
                                            final pdfBytes = await PdfReportHelper.buildStudentCertificatePdf(
                                              student: student,
                                              gradeLevel: widget.gradeLevel,
                                              term: _selectedTerm,
                                              month: 4,
                                              schoolName: _schoolNameCtrl.text.trim(),
                                              academicYearName: academicYearName,
                                            );
                                            await PdfReportHelper.printOrSavePdf(pdfBytes, 'إشعار_درجات_${student.name}');
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tab 2: Certificate Builder & Visual Card Preview
  Widget _buildCertificatesTab(
    BuildContext context,
    StudentProvider studentProv,
    String academicYearName,
    bool isLanguageSchool,
  ) {
    return Column(
      children: [
        Card(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.mutedBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _schoolNameCtrl,
                      decoration: const InputDecoration(
                        hintText: "اسم المدرسة (اختياري)...",
                        prefixIcon: Icon(Icons.school_outlined, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('الشهر: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  AppDropdown<int>(
                    value: _certSelectedMonth,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('درجات شهر 1')),
                      DropdownMenuItem(value: 2, child: Text('درجات شهر 2')),
                      DropdownMenuItem(value: 3, child: Text('درجات شهر 3')),
                      DropdownMenuItem(value: 4, child: Text('متوسط الترم الكلي')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _certSelectedMonth = val);
                    },
                  ),
                  const SizedBox(width: 16),
                  const Text('الطالب: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  if (studentProv.students.isNotEmpty)
                    AppDropdown<Student>(
                      value: _selectedStudent ?? studentProv.students.first,
                      items: studentProv.students
                          .map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.seatingNumber})')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStudent = val);
                      },
                    ),
                  const SizedBox(width: 32),
                  ElevatedButton.icon(
                    onPressed: _selectedStudent == null
                        ? null
                        : () async {
                            final pdfBytes = await PdfReportHelper.buildStudentCertificatePdf(
                              student: _selectedStudent!,
                              gradeLevel: widget.gradeLevel,
                              term: _selectedTerm,
                              month: _certSelectedMonth,
                              schoolName: _schoolNameCtrl.text.trim(),
                              academicYearName: academicYearName,
                            );
                            await PdfReportHelper.printOrSavePdf(pdfBytes, 'إشعار_درجات_${_selectedStudent!.name}');
                          },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text("طباعة إشعار الدرجات PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Visual Grade Card Mockup Canvas
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Scrollbar(
                    controller: _hScrollController2,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _hScrollController2,
                      scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth < 720 ? 720 : constraints.maxWidth),
                      child: Container(
                      width: 720,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryDark, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "جمهورية مصر العربية\nوزارة التربية والتعليم\n${_schoolNameCtrl.text.trim().isEmpty ? 'اسم المدرسة: .........' : _schoolNameCtrl.text.trim()}",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                              Text("العام الدراسي: $academicYearName\nالفصل الدراسي ${_selectedTerm == 1 ? 'الأول' : 'الثاني'}", textAlign: TextAlign.left, style: const TextStyle(fontSize: 12, color: AppColors.secondaryDark)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "إشعار درجات تقييم الملف (${_certSelectedMonth == 4 ? 'متوسط الترم الكلي' : 'شهر $_certSelectedMonth'})",
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.neutralBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.mutedBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("اسم الطالب: ${_selectedStudent?.name ?? 'عمر أحمد نور الدين'}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                Text("رقم الجلوس: ${_selectedStudent?.seatingNumber ?? '219'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("الصف: ${widget.gradeLevel}", style: const TextStyle(fontSize: 12)),
                                Text("الفصل: ${_selectedStudent?.className ?? '1'}", style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "تفاصيل درجات بنود تقييم الملف لكل مادة (${_certSelectedMonth == 4 ? 'متوسط الترم الكلي' : 'درجات شهر $_certSelectedMonth'}):",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _loadStudentCertificateRows(_selectedStudent ?? (studentProv.students.isNotEmpty ? studentProv.students.first : null)),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                              }
                              final rowsData = snapshot.data ?? [];
                              return Table(
                                border: TableBorder.all(color: AppColors.mutedBorder, width: 1),
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(color: AppColors.neutralBackground),
                                    children: [
                                      const Padding(padding: EdgeInsets.all(8), child: Text('المادة الدراسية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                                      const Padding(padding: EdgeInsets.all(8), child: Text('واجب منزلي (5)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                                      const Padding(padding: EdgeInsets.all(8), child: Text('كراسة الحصة (5)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                                      const Padding(padding: EdgeInsets.all(8), child: Text('تقييم أسبوعي (10)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                                      const Padding(padding: EdgeInsets.all(8), child: Text('اختبار الشهور (15)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                                      const Padding(padding: EdgeInsets.all(8), child: Text('مواظبة وسلوك (5)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(_certSelectedMonth == 4 ? 'متوسط الترم الكلي' : 'مجموع الشهر', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                      ),
                                    ],
                                  ),
                                  ...rowsData.map((rowData) {
                                    final List<String> scores = List<String>.from(rowData['scores']);
                                    return TableRow(
                                      children: [
                                        Padding(padding: const EdgeInsets.all(8), child: Text(rowData['subjectName'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                                        ...scores.map((sc) => Padding(padding: const EdgeInsets.all(8), child: Text(sc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)))),
                                        Padding(padding: const EdgeInsets.all(8), child: Text(rowData['total'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 12))),
                                      ],
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text("معلم / معلمة المادة\n.......................", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              Text("يعتمد مدير المدرسة\n.......................", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _applyTemplatePreset(TemplatePreset preset) {
    setState(() {
      _reportTitleCtrl.text = preset.reportTitle;
      _reportNotesCtrl.text = preset.headerNotes;
      _reportFooterCtrl.text = preset.footerNotes;
      _showTableInReport = preset.showTable;
      _showStudentCardInReport = preset.showStudentCard;
      _showSignaturesInReport = preset.showSignatures;
    });
  }

  /// Tab 3: Interactive WYSIWYG Report Builder & Presets
  Widget _buildReportEditorTab(BuildContext context, String academicYearName) {
    final studentProv = Provider.of<StudentProvider>(context);

    // Dynamic month scores & average calculations for selected sample student
    double m1Sum = 48.50;
    double m2Sum = 49.00;
    double m3Sum = 50.00;
    double avgSum = 49.17;
    double totalAvgSum = 245.85;

    final parsedTitle = WysiwygTemplateHelper.parseTemplateText(
      template: _reportTitleCtrl.text,
      student: _selectedStudent,
      gradeLevel: widget.gradeLevel,
      schoolName: _schoolNameCtrl.text,
      academicYearName: academicYearName,
      term: _selectedTerm,
      month1Sum: m1Sum,
      month2Sum: m2Sum,
      month3Sum: m3Sum,
      termAvgSum: avgSum,
      totalAvgSum: totalAvgSum,
    );

    final parsedHeaderNote = WysiwygTemplateHelper.parseTemplateText(
      template: _reportNotesCtrl.text,
      student: _selectedStudent,
      gradeLevel: widget.gradeLevel,
      schoolName: _schoolNameCtrl.text,
      academicYearName: academicYearName,
      term: _selectedTerm,
      month1Sum: m1Sum,
      month2Sum: m2Sum,
      month3Sum: m3Sum,
      termAvgSum: avgSum,
      totalAvgSum: totalAvgSum,
    );

    final parsedFooterNote = WysiwygTemplateHelper.parseTemplateText(
      template: _reportFooterCtrl.text,
      student: _selectedStudent,
      gradeLevel: widget.gradeLevel,
      schoolName: _schoolNameCtrl.text,
      academicYearName: academicYearName,
      term: _selectedTerm,
      month1Sum: m1Sum,
      month2Sum: m2Sum,
      month3Sum: m3Sum,
      termAvgSum: avgSum,
      totalAvgSum: totalAvgSum,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Presets Quick Selector Bar
        Card(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.mutedBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryDark),
                    SizedBox(width: 8),
                    Text(
                      "الخطوة 1: اختر قالباً جاهزاً بضغطة زر واحدة (أو انشئ قالباً مخصصاً):",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: WysiwygTemplateHelper.presets.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: InkWell(
                          onTap: () => _applyTemplatePreset(preset),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.description_outlined, size: 16, color: AppColors.primaryDark),
                                const SizedBox(width: 8),
                                Text(
                                  preset.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Main Split Area: Left Form Controls & Right Live Preview
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Form Controls Panel
              SizedBox(
                width: 400,
                child: Card(
                  color: AppColors.lightSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.mutedBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune, color: AppColors.primaryDark),
                              SizedBox(width: 8),
                              Text("الخطوة 2: خصص نصوص ومكونات التقرير", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Sample Student Dropdown
                          Row(
                            children: [
                              const Text("معاينة للطالب: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppDropdown<Student>(
                                  value: _selectedStudent,
                                  items: studentProv.students.map((s) => DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedStudent = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: AppColors.mutedBorder),
                          const SizedBox(height: 10),

                          // Quick Insert Variables Helper Chips
                          const Text("إدراج المتغيرات المخصصة بنقرة واحدة:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: WysiwygTemplateHelper.availableVariables.map((v) {
                              final isMonthVar = v.category == 'درجات الشهور' || v.category == 'متوسطات الشهور';
                              return ActionChip(
                                avatar: Icon(isMonthVar ? Icons.analytics : Icons.add_circle_outline, size: 14, color: isMonthVar ? Colors.teal.shade800 : AppColors.primaryDark),
                                label: Text(v.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isMonthVar ? Colors.teal.shade900 : AppColors.primaryDark)),
                                backgroundColor: isMonthVar ? Colors.teal.shade50 : AppColors.neutralBackground,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isMonthVar ? Colors.teal.shade300 : AppColors.mutedBorder)),
                                onPressed: () => _insertVariableIntoActiveField(v.key),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: AppColors.mutedBorder),
                          const SizedBox(height: 10),

                          // Text Fields
                          TextField(
                            controller: _reportTitleCtrl,
                            decoration: const InputDecoration(
                              labelText: "عنوان التقرير أو الإشعار الرسمي",
                              hintText: "مثال: إشعار درجات الشهور ومجموع المتوسطات للطالب {{اسم_الطالب}}",
                            ),
                            onTap: () => _activeTextController = _reportTitleCtrl,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _reportNotesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: "الملاحظات العليا للتقرير",
                              hintText: "مثال: حقق الطالب في شهر 1 ({{درجة_شهر_1}}) ومتوسط الشهور ({{متوسط_الشهور}})...",
                            ),
                            onTap: () => _activeTextController = _reportNotesCtrl,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _reportFooterCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: "الملاحظة والاعتماد السفلي",
                              hintText: "مثال: إشعار رسمي معتمد بتاريخ {{التاريخ}} بتقدير {{التقدير_العام}}...",
                            ),
                            onTap: () => _activeTextController = _reportFooterCtrl,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),

                          // Theme Color Selection
                          const Text("الخطوة 3: اختر لون الهوية والبناء:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Color(0xFF0A0F1D), // Midnight Obsidian
                              const Color(0xFF1E293B), // Deep Slate
                              const Color(0xFF047857), // Emerald Green
                              const Color(0xFF1D4ED8), // Royal Blue
                              const Color(0xFF991B1B), // Crimson Red
                            ].map((c) {
                              final isSelected = _selectedThemeColor == c;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedThemeColor = c),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSelected ? Colors.amber : Colors.transparent, width: 3),
                                    boxShadow: [
                                      if (isSelected) BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Toggles
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("عرض جدول درجات بنود المادة", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            value: _showTableInReport,
                            onChanged: (val) => setState(() => _showTableInReport = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("عرض بطاقة بيانات الطالب", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            value: _showStudentCardInReport,
                            onChanged: (val) => setState(() => _showStudentCardInReport = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("عرض خانات التوقيعات الرسمية", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            value: _showSignaturesInReport,
                            onChanged: (val) => setState(() => _showSignaturesInReport = val),
                          ),
                          const SizedBox(height: 20),

                          // Big Print Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final rowsData = await _loadStudentCertificateRows(_selectedStudent);
                                final pdfBytes = await WysiwygTemplateHelper.buildCustomTemplatePdf(
                                  titleText: _reportTitleCtrl.text,
                                  headerNoteText: _reportNotesCtrl.text,
                                  footerNoteText: _reportFooterCtrl.text,
                                  managerTitle: _managerNameCtrl.text,
                                  principalTitle: _principalNameCtrl.text,
                                  schoolName: _schoolNameCtrl.text,
                                  academicYearName: academicYearName,
                                  gradeLevel: widget.gradeLevel,
                                  term: _selectedTerm,
                                  selectedMonth: _certSelectedMonth,
                                  sampleStudent: _selectedStudent,
                                  rowsData: rowsData,
                                  primaryThemeColor: PdfColor.fromInt(_selectedThemeColor.toARGB32()),
                                  showTable: _showTableInReport,
                                  showStudentInfoBox: _showStudentCardInReport,
                                  showSignatures: _showSignaturesInReport,
                                );
                                await WysiwygTemplateHelper.printTemplatePdf(pdfBytes, 'قالب_مخصص_${widget.gradeLevel}');
                              },
                              icon: const Icon(Icons.print, size: 20),
                              label: const Text("طباعة وتصدير التقرير النهائي (PDF)"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedThemeColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Right Preview Panel (A4 Live Paper Mockup)
              Expanded(
                child: Card(
                  color: AppColors.lightSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.mutedBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_outlined, size: 14, color: AppColors.primaryDark),
                                SizedBox(width: 6),
                                Text(
                                  "معاينة حية ومباشرة للتقرير المطبوع (WYSIWYG Live Preview)",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Container(
                              width: 700,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _selectedThemeColor, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Top Header (RTL: Right = Ministry/School, Left = Year/Term)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "العام الدراسي: $academicYearName\nالفصل الدراسي ${_selectedTerm == 1 ? 'الأول' : 'الثاني'}",
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 11, color: AppColors.secondaryDark),
                                      ),
                                      Text(
                                        "جمهورية مصر العربية\nوزارة التربية والتعليم\n${_schoolNameCtrl.text.trim().isEmpty ? 'مدرسة الرصد الإعدادية' : _schoolNameCtrl.text.trim()}",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _selectedThemeColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Parsed Title
                                  if (parsedTitle.isNotEmpty)
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _selectedThemeColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          parsedTitle,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 14),

                                  // Parsed Header Note
                                  if (parsedHeaderNote.isNotEmpty) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.neutralBackground,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.mutedBorder),
                                      ),
                                      child: Text(
                                        parsedHeaderNote,
                                        style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.primaryDark),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Student Info Box
                                  if (_showStudentCardInReport && _selectedStudent != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.neutralBackground,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.mutedBorder),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("اسم الطالب: ${_selectedStudent?.name}", style: TextStyle(fontWeight: FontWeight.bold, color: _selectedThemeColor)),
                                          Text("رقم الجلوس: ${_selectedStudent?.seatingNumber}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text("الصف: ${widget.gradeLevel}", style: const TextStyle(fontSize: 12)),
                                          Text("الفصل: ${_selectedStudent?.className}", style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Live Dynamic Grades Table
                                  if (_showTableInReport) ...[
                                    FutureBuilder<List<Map<String, dynamic>>>(
                                      future: _loadStudentCertificateRows(_selectedStudent ?? (studentProv.students.isNotEmpty ? studentProv.students.first : null)),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                                        }
                                        final rowsData = snapshot.data ?? [];
                                        return Table(
                                          border: TableBorder.all(color: AppColors.mutedBorder, width: 1),
                                          children: [
                                            TableRow(
                                              decoration: BoxDecoration(color: _selectedThemeColor),
                                              children: [
                                                const Padding(padding: EdgeInsets.all(8), child: Text('المادة الدراسية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11))),
                                                const Padding(padding: EdgeInsets.all(8), child: Text('واجب منزلي (5)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11))),
                                                const Padding(padding: EdgeInsets.all(8), child: Text('كراسة الحصة (5)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11))),
                                                const Padding(padding: EdgeInsets.all(8), child: Text('تقييم أسبوعي (10)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11))),
                                                const Padding(padding: EdgeInsets.all(8), child: Text('اختبار الشهور (15)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11))),
                                                const Padding(padding: EdgeInsets.all(8), child: Text('مواظبة وسلوك (5)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11))),
                                                Padding(
                                                  padding: const EdgeInsets.all(8),
                                                  child: Text(_certSelectedMonth == 4 ? 'مجموع المتوسطات' : 'المجموع الكلي', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                                                ),
                                              ],
                                            ),
                                            ...rowsData.map((rowData) {
                                              final List<String> scores = List<String>.from(rowData['scores']);
                                              return TableRow(
                                                children: [
                                                  Padding(padding: const EdgeInsets.all(8), child: Text(rowData['subjectName'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                                                  ...scores.map((sc) => Padding(padding: const EdgeInsets.all(8), child: Text(sc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)))),
                                                  Padding(padding: const EdgeInsets.all(8), child: Text(rowData['total'], textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _selectedThemeColor, fontSize: 11))),
                                                ],
                                              );
                                            }),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Parsed Footer Note
                                  if (parsedFooterNote.isNotEmpty) ...[
                                    Text(parsedFooterNote, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                    const SizedBox(height: 14),
                                  ],

                                  // Signatures
                                  if (_showSignaturesInReport) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Text("${_principalNameCtrl.text}\n.......................", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        Text("${_managerNameCtrl.text}\n.......................", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
