import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_title_bar.dart';
import 'views/class_settings_view.dart';
import 'views/subject_settings_view.dart';
import 'views/student_settings_view.dart';
import 'views/grade_entry_view.dart';
import 'views/reports_view.dart';

class StageScreen extends StatefulWidget {
  final String stageName; // "الحلقة الابتدائية" / "الحلقة الإعدادية"
  final String gradeLevel; // e.g. "الصف الخامس الابتدائي"
  final int selectedTerm; // 1 or 2

  const StageScreen({
    super.key,
    required this.stageName,
    required this.gradeLevel,
    required this.selectedTerm,
  });

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> {
  int _selectedSidebarIndex = 3; // Default to Grade Entry view

  final List<Map<String, dynamic>> _sidebarItems = const [
    {'title': 'إعدادات الفصول', 'icon': Icons.meeting_room_outlined},
    {'title': 'إعدادات المواد', 'icon': Icons.book_outlined},
    {'title': 'إعدادات الطلاب', 'icon': Icons.people_alt_outlined},
    {'title': 'شاشة الرصد', 'icon': Icons.table_chart_outlined},
    {'title': 'الشهادات والتقارير', 'icon': Icons.description_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final termName = widget.selectedTerm == 1 ? "الفصل الدراسي الأول" : "الفصل الدراسي الثاني";

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      body: Column(
        children: [
          CustomTitleBar(
              title: "${widget.gradeLevel} - $termName",
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark, size: 20),
                tooltip: "الرجوع للوحة الرئيسية",
                onPressed: () => Navigator.pop(context),
              ),
            ),
          Expanded(
            child: Row(
              children: [
                // Fixed Width Sidebar (240px) - Pure white seamless without border line
                Container(
                  width: 240,
                  color: AppColors.lightSurface,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        child: Row(
                          children: [
                            const Icon(Icons.school_rounded, color: AppColors.primaryDark, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.gradeLevel,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          itemCount: _sidebarItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final item = _sidebarItems[index];
                            final isSelected = _selectedSidebarIndex == index;

                            return InkWell(
                              onTap: () => setState(() => _selectedSidebarIndex = index),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.secondaryDark.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item['icon'] as IconData,
                                      size: 20,
                                      color: isSelected
                                          ? AppColors.secondaryDark
                                          : AppColors.primaryDark,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      item['title'] as String,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.secondaryDark
                                            : AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Main View Canvas for Selected Sidebar View - Pure white seamless
                Expanded(
                  child: _buildSelectedView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedSidebarIndex) {
      case 0:
        return ClassSettingsView(gradeLevel: widget.gradeLevel);
      case 1:
        return SubjectSettingsView(gradeLevel: widget.gradeLevel);
      case 2:
        return StudentSettingsView(gradeLevel: widget.gradeLevel);
      case 3:
        return GradeEntryView(
          gradeLevel: widget.gradeLevel,
          selectedTerm: widget.selectedTerm,
        );
      case 4:
        return ReportsView(gradeLevel: widget.gradeLevel);
      default:
        return GradeEntryView(
          gradeLevel: widget.gradeLevel,
          selectedTerm: widget.selectedTerm,
        );
    }
  }
}
