import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/pdf_report_helper.dart';
import '../../../models/assessment_item.dart';
import '../../../models/grade_record.dart';
import '../../../models/student.dart';
import '../../../models/subject.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/class_provider.dart';
import '../../../providers/student_provider.dart';

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

  // Report Builder controllers
  final _schoolNameCtrl = TextEditingController(text: "");
  final _reportTitleCtrl = TextEditingController(text: "تقرير متابعة وانضباط درجات ملف المادة");
  final _reportNotesCtrl = TextEditingController(text: "تم بحمد الله رصد جميع بنود التقييم واحتساب متوسط الشهور دون أي جبر للكسور ووفق التعليمات والتوجيهات المعتمدة.");
  final _managerNameCtrl = TextEditingController(text: "مسؤول المادة");
  final _principalNameCtrl = TextEditingController(text: "مدير المدرسة");

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
    final subMaps = await db.query(
      'subjects',
      where: 'grade_level = ?',
      whereArgs: [widget.gradeLevel],
      orderBy: 'id ASC',
    );
    final subjects = subMaps.map((m) => Subject.fromMap(m)).toList();
    final List<Map<String, dynamic>> results = [];

    for (final sub in subjects) {
      final recMaps = await db.query(
        'grade_records',
        where: 'seating_number = ? AND subject_id = ? AND term = ?',
        whereArgs: [student.seatingNumber, sub.id, _selectedTerm],
      );

      final itemMaps = await db.query(
        'assessment_items',
        where: 'subject_id = ?',
        whereArgs: [sub.id],
        orderBy: 'id ASC',
      );
      final items = itemMaps.map((m) => AssessmentItem.fromMap(m)).toList();

      final List<String> itemScores = [];
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

  @override
  void dispose() {
    _tabController.dispose();
    _schoolNameCtrl.dispose();
    _reportTitleCtrl.dispose();
    _reportNotesCtrl.dispose();
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
          // View Title & Navigation Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "الشهادات والتقارير المجمعة - ${widget.gradeLevel}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "استخراج وتصدير كشوف الرصد المجمعة لـ Excel و PDF وطباعة إشعارات درجات الطلاب تفصيلياً بضغطة زر.",
                    style: const TextStyle(fontSize: 13, color: AppColors.secondaryDark),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppColors.secondaryDark,
                  labelColor: AppColors.primaryDark,
                  unselectedLabelColor: AppColors.secondaryDark,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.table_chart_outlined, size: 18), text: "كشوف الرصد المجمعة"),
                    Tab(icon: Icon(Icons.assignment_ind_outlined, size: 18), text: "إشعارات درجات الطلاب"),
                    Tab(icon: Icon(Icons.edit_document, size: 18), text: "محرر التقارير التفاعلي"),
                  ],
                ),
              ),
            ],
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
        // Controls bar
        Card(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Text('تصفية الفصل: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: _selectedClass,
                  underline: const SizedBox(),
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
                DropdownButton<int>(
                  value: _selectedTerm,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('الفصل الدراسي الأول')),
                    DropdownMenuItem(value: 2, child: Text('الفصل الدراسي الثاني')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTerm = val);
                  },
                ),
                const Spacer(),
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
                    foregroundColor: AppColors.secondaryDark,
                    side: const BorderSide(color: AppColors.secondaryDark),
                  ),
                ),
                const SizedBox(width: 8),
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
        const SizedBox(height: 16),

        // Live Compiled Grade Sheet Preview Table
        Expanded(
          child: Card(
            color: AppColors.lightSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: studentProv.students.isEmpty
                ? const Center(
                    child: Text("لا يوجد طلاب مسجلون لعرض كشوف الرصد المجمعة"),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: DataTable(
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
                                icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.secondaryDark, size: 20),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
                DropdownButton<int>(
                  value: _certSelectedMonth,
                  underline: const SizedBox(),
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
                  DropdownButton<Student>(
                    value: _selectedStudent ?? studentProv.students.first,
                    underline: const SizedBox(),
                    items: studentProv.students
                        .map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.seatingNumber})')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStudent = val);
                    },
                  ),
                const Spacer(),
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
        const SizedBox(height: 16),

        // Visual Grade Card Mockup Canvas
        Expanded(
          child: Center(
            child: SingleChildScrollView(
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
        ),
      ],
    );
  }

  /// Tab 3: Interactive WYSIWYG Report Builder & Multi-page Pagination
  Widget _buildReportEditorTab(BuildContext context, String academicYearName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Form Controls (300px)
        SizedBox(
          width: 320,
          child: Card(
            color: AppColors.lightSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("محرر التقارير التفاعلي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reportTitleCtrl,
                      decoration: const InputDecoration(labelText: "عنوان التقرير الرسمي"),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reportNotesCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: "ملاحظات وتوجيهات التقرير"),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _managerNameCtrl,
                      decoration: const InputDecoration(labelText: "صفة المسؤول الأول"),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _principalNameCtrl,
                      decoration: const InputDecoration(labelText: "صفة اعتماد المعتمد"),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final pdfBytes = await PdfReportHelper.buildCompiledGradePdf(
                            gradeLevel: widget.gradeLevel,
                            className: _selectedClass,
                            term: _selectedTerm,
                            schoolName: "مدرسة الرصد",
                            academicYearName: academicYearName,
                          );
                          await PdfReportHelper.printOrSavePdf(pdfBytes, 'تقرير_${widget.gradeLevel}');
                        },
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text("تصدير وطباعة التقرير PDF"),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Live Paginated Document Preview
        Expanded(
          child: Card(
            color: AppColors.lightSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _reportTitleCtrl.text,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                      Text("العام الدراسي: $academicYearName", style: const TextStyle(fontSize: 12, color: AppColors.secondaryDark)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.mutedBorder),
                  const SizedBox(height: 16),
                  Text(_reportNotesCtrl.text, style: const TextStyle(fontSize: 13, height: 1.5)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("${_managerNameCtrl.text}\n.......................", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("${_principalNameCtrl.text}\n.......................", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
