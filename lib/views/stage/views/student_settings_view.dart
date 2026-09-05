import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/excel_student_helper.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../models/student.dart';
import '../../../providers/class_provider.dart';
import '../../../providers/student_provider.dart';

class StudentSettingsView extends StatefulWidget {
  final String gradeLevel;

  const StudentSettingsView({super.key, required this.gradeLevel});

  @override
  State<StudentSettingsView> createState() => _StudentSettingsViewState();
}

class _StudentSettingsViewState extends State<StudentSettingsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedClass = 'الكل';
  final Set<int> _selectedStudentIds = {};

  static const List<String> _allGradeLevels = [
    'الصف الأول الابتدائي',
    'الصف الثاني الابتدائي',
    'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي',
    'الصف الخامس الابتدائي',
    'الصف السادس الابتدائي',
    'الصف الأول الإعدادي',
    'الصف الثاني الإعدادي',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didUpdateWidget(covariant StudentSettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gradeLevel != widget.gradeLevel) {
      setState(() => _selectedStudentIds.clear());
      _loadData();
    }
  }

  void _loadData() {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    classProvider.loadClassesForGrade(widget.gradeLevel, widget.gradeLevel);
    studentProvider.loadStudentsForGrade(widget.gradeLevel, widget.gradeLevel, className: _selectedClass);
  }

  String _getNextGradeLevel(String currentGrade) {
    final idx = _allGradeLevels.indexOf(currentGrade);
    if (idx != -1 && idx + 1 < _allGradeLevels.length) {
      return _allGradeLevels[idx + 1];
    }
    return currentGrade;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);

    final List<Student> filteredStudents = studentProvider.students.where((student) {
      final matchesSearch = _searchQuery.isEmpty ||
          student.seatingNumber.contains(_searchQuery) ||
          student.name.contains(_searchQuery);
      return matchesSearch;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.neutralBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "إدارة وسجلات الطلاب - ${widget.gradeLevel}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "تسجيل الطلاب يدوياً، تحديد طلاب للتعديل أو النقل الجماعي للفصل التالي، واستيراد شيتات Excel.",
                    style: TextStyle(fontSize: 13, color: AppColors.secondaryDark),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _exportTemplate(context),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("تصدير قالب Excel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryAccent,
                      side: const BorderSide(color: AppColors.secondaryAccent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _importExcel(context),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text("استيراد شيت Excel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddStudentDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("إضافة طالب جديد"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search bar & Class Filter
          Row(
            children: [
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: "بحث برقم الجلوس أو اسم الطالب...",
                    prefixIcon: const Icon(Icons.search, color: AppColors.secondaryDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.mutedBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Class filter dropdown
              AppDropdown<String>(
                value: _selectedClass,
                items: [
                  const DropdownMenuItem(value: 'الكل', child: Text('جميع الفصول')),
                  ...classProvider.classes.map(
                    (c) => DropdownMenuItem(value: c.className, child: Text('فصل ${c.className}')),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedClass = val;
                      _selectedStudentIds.clear();
                    });
                    studentProvider.loadStudentsForGrade(widget.gradeLevel, widget.gradeLevel, className: val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Batch Action Toolbar Banner
          if (_selectedStudentIds.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_box_outlined, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    "تم تحديد ${_selectedStudentIds.length} طالب",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showBatchMoveDialog(context),
                    icon: const Icon(Icons.drive_file_move_outlined, size: 16),
                    label: const Text("نقل / تعديل الفصل والصف الجماعي"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showBatchGenderDialog(context),
                    icon: const Icon(Icons.wc, size: 16),
                    label: const Text("تعديل الجنس (ولد/بنت)"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primaryDark),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _confirmBatchDelete(context),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    label: const Text("حذف المحددين"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: "إلغاء التحديد",
                    icon: const Icon(Icons.close, color: AppColors.secondaryDark),
                    onPressed: () => setState(() => _selectedStudentIds.clear()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Students Table View
          Expanded(
            child: Card(
              color: AppColors.lightSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide.none,
              ),
              child: studentProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStudents.isEmpty
                      ? const Center(
                          child: Text(
                            "لا يوجد طلاب مسجلون في هذا التصفية",
                            style: TextStyle(color: AppColors.secondaryDark, fontSize: 15),
                          ),
                        )
                      : SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppColors.neutralBackground),
                              showCheckboxColumn: true,
                              onSelectAll: (val) {
                                setState(() {
                                  if (val == true) {
                                    for (final s in filteredStudents) {
                                      if (s.id != null) _selectedStudentIds.add(s.id!);
                                    }
                                  } else {
                                    for (final s in filteredStudents) {
                                      if (s.id != null) _selectedStudentIds.remove(s.id);
                                    }
                                  }
                                });
                              },
                              columns: const [
                                DataColumn(label: Text('رقم الجلوس', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الفصل', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الجنس', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredStudents.map((student) {
                                final isSelected = student.id != null && _selectedStudentIds.contains(student.id);

                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (val) {
                                    if (student.id == null) return;
                                    setState(() {
                                      if (val == true) {
                                        _selectedStudentIds.add(student.id!);
                                      } else {
                                        _selectedStudentIds.remove(student.id);
                                      }
                                    });
                                  },
                                  cells: [
                                    DataCell(Text(student.seatingNumber, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(student.name)),
                                    DataCell(Text('فصل ${student.className}')),
                                    DataCell(Text(student.gender)),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.secondaryAccent, size: 20),
                                            tooltip: 'تعديل',
                                            onPressed: () => _showEditStudentDialog(context, student),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                            tooltip: 'حذف',
                                            onPressed: () => _confirmDeleteStudent(context, student),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBatchMoveDialog(BuildContext context) {
    String targetStage = _getNextGradeLevel(widget.gradeLevel);
    String targetClassName = '1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.drive_file_move_outlined, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text('نقل / تعديل فصل واجتماعي لـ (${_selectedStudentIds.length} طالب)'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "حدد الصف والفصل المستهدف لنقل أو تعديل الطلاب المحددين جماعياً:",
                style: TextStyle(fontSize: 13, color: AppColors.secondaryDark),
              ),
              const SizedBox(height: 16),
              const Text('الصف الدراسي المستهدف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              AppDropdown<String>(
                value: targetStage,
                items: _allGradeLevels.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => targetStage = val);
                },
              ),
              const SizedBox(height: 14),
              const Text('رقم/اسم الفصل المستهدف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: TextEditingController(text: targetClassName),
                onChanged: (val) => targetClassName = val.trim(),
                decoration: const InputDecoration(
                  hintText: "مثال: 1 أو 2 أو 5/1",
                  prefixIcon: Icon(Icons.class_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('تأكيد النقل والجماعي'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(this.context);
                final studentProvider = Provider.of<StudentProvider>(this.context, listen: false);

                final success = await studentProvider.batchUpdateStudentsClass(
                  studentIds: _selectedStudentIds.toList(),
                  targetStage: targetStage,
                  targetClassName: targetClassName.isEmpty ? '1' : targetClassName,
                  currentGradeLevel: widget.gradeLevel,
                );

                if (mounted) {
                  if (success) {
                    setState(() => _selectedStudentIds.clear());
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('تم نقل وتعديل فصل الطلاب إلى ($targetStage - فصل $targetClassName) بنجاح!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchGenderDialog(BuildContext context) {
    String selectedGender = 'ولد';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.wc, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text('تعديل الجنس الجماعي لـ (${_selectedStudentIds.length} طالب)'),
            ],
          ),
          content: Row(
            children: [
              const Text('اختر الجنس الجديد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              AppDropdown<String>(
                value: selectedGender,
                items: const [
                  DropdownMenuItem(value: 'ولد', child: Text('ولد')),
                  DropdownMenuItem(value: 'بنت', child: Text('بنت')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedGender = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(this.context);
                final studentProvider = Provider.of<StudentProvider>(this.context, listen: false);

                final success = await studentProvider.batchUpdateStudentsGender(
                  studentIds: _selectedStudentIds.toList(),
                  gender: selectedGender,
                  currentGradeLevel: widget.gradeLevel,
                );

                if (mounted) {
                  if (success) {
                    setState(() => _selectedStudentIds.clear());
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('تم تغيير الجنس لجميع الطلاب المحددين إلى ($selectedGender) بنجاح!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ التعديل'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBatchDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف الجماعي'),
        content: Text('هل أنت متأكد من حذف (${_selectedStudentIds.length}) طالب من السجلات نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(this.context);
              final studentProvider = Provider.of<StudentProvider>(this.context, listen: false);

              final success = await studentProvider.batchDeleteStudents(
                studentIds: _selectedStudentIds.toList(),
                currentGradeLevel: widget.gradeLevel,
              );

              if (mounted) {
                if (success) {
                  setState(() => _selectedStudentIds.clear());
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الطلاب المحددين بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف المحددين'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTemplate(BuildContext context) async {
    final path = await ExcelStudentHelper.exportStudentTemplate(widget.gradeLevel);
    if (path != null && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('تم حفظ القالب بنجاح: $path'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _importExcel(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result.isEmpty || result.first.path == null) return;
    final filePath = result.first.path!;

    if (!mounted) return;
    final parseResult = await ExcelStudentHelper.parseStudentExcel(filePath, widget.gradeLevel);

    if (!mounted) return;

    showDialog(
      context: this.context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.preview, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Text('معاينة استيراد الطلاب (${parseResult.students.length} طالب)'),
          ],
        ),
        content: SizedBox(
          width: 650,
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (parseResult.warnings.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ملاحظات وأخطاء في الشيت:",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 4),
                      ...parseResult.warnings.map(
                        (w) => Text("• $w", style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                "الطلاب الذين سيتم استيرادهم / تحديثهم حسب رقم الجلوس:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 40,
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 40,
                      columns: const [
                        DataColumn(label: Text('رقم الجلوس')),
                        DataColumn(label: Text('اسم الطالب')),
                        DataColumn(label: Text('الصف')),
                        DataColumn(label: Text('الفصل')),
                        DataColumn(label: Text('الجنس')),
                      ],
                      rows: parseResult.students.map((s) {
                        final hasWarning = parseResult.warnings.any((w) => w.contains(s.seatingNumber));
                        return DataRow(
                          color: WidgetStateProperty.all(hasWarning ? Colors.red.shade50 : null),
                          cells: [
                            DataCell(Text(s.seatingNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(s.name)),
                            DataCell(Text(s.stage)),
                            DataCell(Text(s.className)),
                            DataCell(Text(s.gender)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
            onPressed: parseResult.students.isEmpty
                ? null
                : () async {
                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(this.context);
                    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
                    final imported = await studentProvider.importStudentsBatch(parseResult.students, widget.gradeLevel);
                    if (mounted) {
                      nav.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('تم استيراد / تحديث $imported طالب بنجاح!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
            child: const Text('تأكيد الاستيراد والحفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final seatingCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    String selectedClass = classProvider.classes.isNotEmpty ? classProvider.classes.first.className : '1';
    String selectedGender = 'ولد';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة طالب جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: seatingCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم الجلوس'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الطالب رباعي'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('الفصل: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    AppDropdown<String>(
                      value: selectedClass,
                      items: classProvider.classes
                          .map((c) => DropdownMenuItem(value: c.className, child: Text('فصل ${c.className}')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedClass = val);
                      },
                    ),
                    const Spacer(),
                    const Text('الجنس: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    AppDropdown<String>(
                      value: selectedGender,
                      items: const [
                        DropdownMenuItem(value: 'ولد', child: Text('ولد')),
                        DropdownMenuItem(value: 'بنت', child: Text('بنت')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedGender = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final seating = seatingCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (seating.isEmpty || name.isEmpty) return;

                final newStudent = Student(
                  seatingNumber: seating,
                  name: name,
                  stage: widget.gradeLevel,
                  className: selectedClass,
                  gender: selectedGender,
                );

                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(this.context);
                final success = await studentProvider.addStudent(newStudent);
                if (mounted) {
                  if (success) {
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('تمت إضافة الطالب بنجاح'), backgroundColor: Colors.green),
                    );
                  } else if (studentProvider.error != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(studentProvider.error!), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStudentDialog(BuildContext context, Student student) {
    final seatingCtrl = TextEditingController(text: student.seatingNumber);
    final nameCtrl = TextEditingController(text: student.name);
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    String selectedClass = student.className;
    String selectedGender = (student.gender == 'ذكر' || student.gender == 'ولد') ? 'ولد' : 'بنت';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل بيانات الطالب'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: seatingCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم الجلوس'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الطالب'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('الفصل: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    AppDropdown<String>(
                      value: selectedClass,
                      items: classProvider.classes
                          .map((c) => DropdownMenuItem(value: c.className, child: Text('فصل ${c.className}')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedClass = val);
                      },
                    ),
                    const Spacer(),
                    const Text('الجنس: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    AppDropdown<String>(
                      value: selectedGender,
                      items: const [
                        DropdownMenuItem(value: 'ولد', child: Text('ولد')),
                        DropdownMenuItem(value: 'بنت', child: Text('بنت')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedGender = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final seating = seatingCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (seating.isEmpty || name.isEmpty) return;

                final updatedStudent = Student(
                  id: student.id,
                  seatingNumber: seating,
                  name: name,
                  stage: widget.gradeLevel,
                  className: selectedClass,
                  gender: selectedGender,
                );

                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(this.context);
                final studentProvider = Provider.of<StudentProvider>(context, listen: false);
                final success = await studentProvider.updateStudent(updatedStudent);
                if (mounted) {
                  if (success) {
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('تم تعديل بيانات الطالب بنجاح'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStudent(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الطالب "${student.name}" (رقم الجلوس: ${student.seatingNumber})؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(this.context);
              final studentProvider = Provider.of<StudentProvider>(context, listen: false);
              final success = await studentProvider.deleteStudent(student);
              if (mounted) {
                nav.pop();
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم حذف الطالب بنجاح'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
