import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/excel_grade_helper.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../models/assessment_item.dart';
import '../../../models/student.dart';
import '../../../models/subject.dart';
import '../../../providers/class_provider.dart';
import '../../../providers/grade_provider.dart';
import '../../../providers/subject_provider.dart';

class GradeEntryView extends StatefulWidget {
  final String gradeLevel;
  final int selectedTerm;

  const GradeEntryView({
    super.key,
    required this.gradeLevel,
    required this.selectedTerm,
  });

  @override
  State<GradeEntryView> createState() => _GradeEntryViewState();
}

class _GradeEntryViewState extends State<GradeEntryView> {
  Subject? _selectedSubject;
  String? _selectedClass = 'الكل';
  int _selectedMonth = 1; // 1, 2, or 3
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() async {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);

    await classProvider.loadClassesForGrade(widget.gradeLevel, widget.gradeLevel);
    await subjectProvider.loadSubjectsForGrade(widget.gradeLevel);

    _selectedClass = 'الكل';

    if (subjectProvider.subjects.isNotEmpty) {
      _selectedSubject = subjectProvider.subjects.first;
    }

    _refreshGrid();
  }

  void _refreshGrid() {
    _clearFocusNodes();
    if (_selectedSubject != null && _selectedClass != null) {
      final gradeProvider = Provider.of<GradeProvider>(context, listen: false);
      gradeProvider.loadGradeData(
        gradeLevel: widget.gradeLevel,
        className: _selectedClass!,
        subject: _selectedSubject!,
        term: widget.selectedTerm,
      );
    }
  }

  FocusNode _getFocusNode(int rowIndex, int colIndex) {
    final key = '$rowIndex-$colIndex';
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
    }
    return _focusNodes[key]!;
  }

  void _clearFocusNodes() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }

  @override
  void dispose() {
    _clearFocusNodes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = Provider.of<ClassProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final gradeProvider = Provider.of<GradeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.neutralBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Selectors Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "شاشة رصد الدرجات السريعة - ${widget.gradeLevel}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "الفصل الدراسي ${widget.selectedTerm == 1 ? 'الأول' : 'الثاني'} | التنقل بأسهم الكيبورد وعرض متوسط الترم الكلي (الـ 3 شهور معا).",
                    style: const TextStyle(fontSize: 13, color: AppColors.secondaryDark),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: (_selectedSubject == null || _selectedClass == null)
                        ? null
                        : () => _exportExcel(context, gradeProvider.students, gradeProvider.assessmentItems),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("تصدير كشف Excel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryAccent,
                      side: const BorderSide(color: AppColors.secondaryAccent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: (_selectedSubject == null || _selectedClass == null)
                        ? null
                        : () => _importExcel(context, gradeProvider.assessmentItems),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text("استيراد درجات Excel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Bar: Subject, Class, Month
          Card(
            color: AppColors.lightSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Subject dropdown
                  const Text('المادة: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  AppDropdown<Subject>(
                    value: _selectedSubject,
                    items: subjectProvider.subjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSubject = val);
                        _refreshGrid();
                      }
                    },
                  ),
                  const SizedBox(width: 20),

                  // Class dropdown
                  const Text('الفصل: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  AppDropdown<String>(
                    value: _selectedClass,
                    items: [
                      const DropdownMenuItem(value: 'الكل', child: Text('الكل (المرحلة كاملة)')),
                      ...classProvider.classes.map((c) => DropdownMenuItem(value: c.className, child: Text('فصل ${c.className}'))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedClass = val);
                        _refreshGrid();
                      }
                    },
                  ),
                  const SizedBox(width: 20),

                  // Month dropdown
                  const Text('عرض / رصد الشهر: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  AppDropdown<int>(
                    value: _selectedMonth,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('شهر 1')),
                      DropdownMenuItem(value: 2, child: Text('شهر 2')),
                      DropdownMenuItem(value: 3, child: Text('شهر 3')),
                      DropdownMenuItem(value: 4, child: Text('متوسط الترم (الـ 3 شهور معاً)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMonth = val);
                        _refreshGrid();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main Grade Entry Table
          Expanded(
            child: Card(
              color: AppColors.lightSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide.none,
              ),
              child: gradeProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : gradeProvider.students.isEmpty
                      ? const Center(
                          child: Text(
                            "لا يوجد طلاب مسجلون في هذا الفصل لرصد درجاتهم",
                            style: TextStyle(color: AppColors.secondaryDark, fontSize: 15),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildGradeDataTable(context, gradeProvider),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDataTable(BuildContext context, GradeProvider gradeProvider) {
    if (_selectedSubject == null) {
      return const Center(
        child: Text(
          "يرجى اختيار مادة لعرض درجاتها",
          style: TextStyle(color: AppColors.secondaryDark, fontSize: 15),
        ),
      );
    }
    final subject = _selectedSubject!;
    final subjectId = subject.id ?? 0;
    final items = gradeProvider.assessmentItems;

    if (subject.isPassFail) {
      // Pass/Fail subject data table
      return DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.neutralBackground),
        columns: const [
          DataColumn(label: Text('رقم الجلوس', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('النتيجة (اجتاز / لم يجتز)', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: gradeProvider.students.map((student) {
          final dummyItemId = items.isNotEmpty ? (items.first.id ?? 1) : 1;
          final record = gradeProvider.getRecord(student.seatingNumber, dummyItemId, widget.selectedTerm, subjectId);
          final currentStatus = record.passFailStatus ?? 'اجتاز';

          return DataRow(
            cells: [
              DataCell(Text(student.seatingNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(student.name)),
              DataCell(
                AppDropdown<String>(
                  height: 38,
                  value: currentStatus,
                  items: const [
                    DropdownMenuItem(value: 'اجتاز', child: Text('اجتاز', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 'لم يجتز', child: Text('لم يجتز', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      gradeProvider.updateScore(
                        seatingNumber: student.seatingNumber,
                        assessmentItemId: dummyItemId,
                        subjectId: subject.id!,
                        term: widget.selectedTerm,
                        passFailStatus: val,
                      );
                    }
                  },
                ),
              ),
            ],
          );
        }).toList(),
      );
    }

    // Standard scored subject data table
    final visibleItems = items.where((i) {
      if (_selectedMonth == 3 && !i.existsInMonth3) return false;
      return true;
    }).toList();

    final students = gradeProvider.students;
    final bool isAvgMode = _selectedMonth == 4;

    return DataTable(
      headingRowColor: WidgetStateProperty.all(AppColors.neutralBackground),
      columns: [
        const DataColumn(label: Text('رقم الجلوس', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold))),
        ...visibleItems.map(
          (item) => DataColumn(
            label: Text(
              isAvgMode
                  ? '${item.itemName} (متوسط)'
                  : '${item.itemName} (${item.maxScore.toInt()})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataColumn(
          label: Text(
            isAvgMode ? 'مجموع متوسطات البنود (المادة)' : 'مجموع درجات الشهر',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
          ),
        ),
      ],
      rows: List.generate(students.length, (rIndex) {
        final student = students[rIndex];
        double currentMonthSum = 0.0;
        double fullTermAvgSum = 0.0;

        final cells = <DataCell>[
          DataCell(Text(student.seatingNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(student.name)),
        ];

        final subId = subject.id ?? 0;

        if (isAvgMode) {
          // Display per-item averages (Read-only average for each item)
          for (int cIndex = 0; cIndex < visibleItems.length; cIndex++) {
            final item = visibleItems[cIndex];
            final itemId = item.id ?? 0;
            final record = gradeProvider.getRecord(student.seatingNumber, itemId, widget.selectedTerm, subId);
            final isMonthExam = item.itemName.contains('اختبار');
            final itemAvg = record.calculateAverage(isMonthExam: isMonthExam);

            if (itemAvg != null) {
              fullTermAvgSum += itemAvg;
            }

            cells.add(
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neutralBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.mutedBorder),
                  ),
                  child: Text(
                    itemAvg != null ? itemAvg.toStringAsFixed(2) : '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
              ),
            );
          }

          // Total sum of item averages for this student
          cells.add(
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  fullTermAvgSum > 0 ? fullTermAvgSum.toStringAsFixed(2) : '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          );
        } else {
          // Month score input fields (Months 1, 2, or 3)
          for (int cIndex = 0; cIndex < visibleItems.length; cIndex++) {
            final item = visibleItems[cIndex];
            final itemId = item.id ?? 0;
            final record = gradeProvider.getRecord(student.seatingNumber, itemId, widget.selectedTerm, subId);
            double? currentScore;
            if (_selectedMonth == 1) currentScore = record.month1Score;
            if (_selectedMonth == 2) currentScore = record.month2Score;
            if (_selectedMonth == 3) currentScore = record.month3Score;

            if (currentScore != null) {
              currentMonthSum += currentScore;
            }

            cells.add(
              DataCell(
                _ScoreInputField(
                  focusNode: _getFocusNode(rIndex, cIndex),
                  initialValue: currentScore,
                  maxScore: item.maxScore,
                  onMoveUp: () {
                    if (rIndex > 0) {
                      _getFocusNode(rIndex - 1, cIndex).requestFocus();
                    }
                  },
                  onMoveDown: () {
                    if (rIndex + 1 < students.length) {
                      _getFocusNode(rIndex + 1, cIndex).requestFocus();
                    }
                  },
                  onMoveLeft: () {
                    if (cIndex + 1 < visibleItems.length) {
                      _getFocusNode(rIndex, cIndex + 1).requestFocus();
                    } else if (rIndex + 1 < students.length) {
                      _getFocusNode(rIndex + 1, 0).requestFocus();
                    }
                  },
                  onMoveRight: () {
                    if (cIndex > 0) {
                      _getFocusNode(rIndex, cIndex - 1).requestFocus();
                    } else if (rIndex > 0) {
                      _getFocusNode(rIndex - 1, visibleItems.length - 1).requestFocus();
                    }
                  },
                  onSubmitted: (newVal) {
                    double? m1 = record.month1Score;
                    double? m2 = record.month2Score;
                    double? m3 = record.month3Score;

                    if (_selectedMonth == 1) m1 = newVal;
                    if (_selectedMonth == 2) m2 = newVal;
                    if (_selectedMonth == 3) m3 = newVal;

                    gradeProvider.updateScore(
                      seatingNumber: student.seatingNumber,
                      assessmentItemId: itemId,
                      subjectId: subId,
                      term: widget.selectedTerm,
                      month1Score: m1,
                      month2Score: m2,
                      month3Score: m3,
                    );
                  },
                ),
              ),
            );
          }

          // Total score sum for the selected month
          cells.add(
            DataCell(
              Text(
                currentMonthSum > 0 ? currentMonthSum.toStringAsFixed(2) : '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          );
        }

        return DataRow(cells: cells);
      }),
    );
  }

  Future<void> _exportExcel(BuildContext context, List<Student> students, List<AssessmentItem> items) async {
    final path = await ExcelGradeHelper.exportGradeSheet(
      subject: _selectedSubject!,
      gradeLevel: widget.gradeLevel,
      className: _selectedClass!,
      term: widget.selectedTerm,
      month: _selectedMonth,
      students: students,
      assessmentItems: items,
    );

    if (path != null && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('تم تصدير كشف الدرجات بنجاح: $path'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _importExcel(BuildContext context, List<AssessmentItem> items) async {
    final fileResult = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (fileResult.isEmpty || fileResult.first.path == null) return;
    final filePath = fileResult.first.path!;

    if (!mounted) return;
    final parseResult = await ExcelGradeHelper.parseGradeExcel(
      filePath: filePath,
      subject: _selectedSubject!,
      term: widget.selectedTerm,
      month: _selectedMonth,
      assessmentItems: items,
    );

    if (!mounted) return;

    showDialog(
      context: this.context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.preview, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Text('معاينة استيراد درجات ${_selectedSubject!.name} (شهر $_selectedMonth)'),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 480,
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
                      const Text("تنبيهات وأخطاء في الشيت المستورد:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 4),
                      ...parseResult.warnings.take(4).map((w) => Text("• $w", style: const TextStyle(fontSize: 12, color: Colors.red))),
                      if (parseResult.warnings.length > 4)
                        Text("...وغيرها من الأخطاء الإضافية (${parseResult.warnings.length - 4})", style: const TextStyle(fontSize: 11, color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
                        DataColumn(label: Text('الدرجات المستوردة')),
                        DataColumn(label: Text('الحالة')),
                      ],
                      rows: parseResult.previewRows.map((previewRow) {
                        final hasError = previewRow.hasError;
                        return DataRow(
                          color: WidgetStateProperty.all(hasError ? Colors.red.shade50 : null),
                          cells: [
                            DataCell(Text(previewRow.seatingNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(previewRow.studentName)),
                            DataCell(Text(previewRow.scores.values.map((v) => v?.toString() ?? '-').join(' | '))),
                            DataCell(
                              hasError
                                  ? const Text('يوجد خطأ في الدرجة', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                                  : const Text('سليم', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ),
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
            onPressed: parseResult.gradeRecords.isEmpty
                ? null
                : () async {
                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(this.context);
                    final gradeProvider = Provider.of<GradeProvider>(ctx, listen: false);
                    final updatedCount = await gradeProvider.batchSaveGradeRecords(
                      parseResult.gradeRecords,
                      targetMonth: _selectedMonth,
                    );
                    if (mounted) {
                      nav.pop();
                      _refreshGrid();
                      messenger.showSnackBar(
                        SnackBar(content: Text('تم استيراد وحفظ $updatedCount سجل درجات بنجاح!'), backgroundColor: Colors.green),
                      );
                    }
                  },
            child: const Text('تأكيد الاستيراد واستبدال الدرجات'),
          ),
        ],
      ),
    );
  }
}

class _ScoreInputField extends StatefulWidget {
  final FocusNode focusNode;
  final double? initialValue;
  final double maxScore;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final ValueChanged<double?> onSubmitted;

  const _ScoreInputField({
    required this.focusNode,
    required this.initialValue,
    required this.maxScore,
    this.onMoveUp,
    this.onMoveDown,
    this.onMoveLeft,
    this.onMoveRight,
    required this.onSubmitted,
  });

  @override
  State<_ScoreInputField> createState() => _ScoreInputFieldState();
}

class _ScoreInputFieldState extends State<_ScoreInputField> {
  late TextEditingController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue != null ? widget.initialValue!.toString() : '',
    );
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.text.isNotEmpty) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ScoreInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
    if (oldWidget.initialValue != widget.initialValue && !widget.focusNode.hasFocus) {
      _controller.text = widget.initialValue != null ? widget.initialValue!.toString() : '';
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSave(String val) {
    if (val.trim().isEmpty) {
      setState(() => _isError = false);
      widget.onSubmitted(null);
      return;
    }

    final parsed = double.tryParse(val.trim());
    if (parsed == null || parsed < 0 || parsed > widget.maxScore) {
      setState(() => _isError = true);
    } else {
      setState(() => _isError = false);
      widget.onSubmitted(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 36,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              widget.onMoveDown?.call();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              widget.onMoveUp?.call();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.tab) {
              widget.onMoveLeft?.call();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              widget.onMoveRight?.call();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          focusNode: widget.focusNode,
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _isError ? Colors.red : AppColors.primaryDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _isError ? Colors.red.shade50 : AppColors.neutralBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _isError ? Colors.red : AppColors.mutedBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _isError ? Colors.red : AppColors.secondaryAccent, width: 2),
            ),
          ),
          onChanged: _validateAndSave,
        ),
      ),
    );
  }
}
