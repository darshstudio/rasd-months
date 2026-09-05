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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 820;
                final sidebarWidth = isCompact ? 68.0 : 240.0;

                return Row(
                  children: [
                    // Unified Administrative Sidebar (240px or 68px compact)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: sidebarWidth,
                      decoration: const BoxDecoration(
                        color: AppColors.neutralBackground,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            child: Row(
                              mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.school_rounded, color: AppColors.primaryDark, size: 20),
                                ),
                                if (!isCompact) ...[
                                  const SizedBox(width: 12),
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
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              itemCount: _sidebarItems.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final item = _sidebarItems[index];
                                final isSelected = _selectedSidebarIndex == index;

                                final navButton = InkWell(
                                  onTap: () => setState(() => _selectedSidebarIndex = index),
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.sidebarActiveBackground
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                                      children: [
                                        Icon(
                                          item['icon'] as IconData,
                                          size: 19,
                                          color: isSelected
                                              ? AppColors.sidebarActiveText
                                              : AppColors.sidebarInactiveText,
                                        ),
                                        if (!isCompact) ...[
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              item['title'] as String,
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontFamily,
                                                fontSize: 13,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.sidebarActiveText
                                                    : AppColors.sidebarInactiveText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );

                                if (isCompact) {
                                  return Tooltip(
                                    message: item['title'] as String,
                                    child: navButton,
                                  );
                                }
                                return navButton;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Main View Content Container (eCoursie Rounded White Card)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [AppColors.cardShadow],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildSelectedView(),
                      ),
                    ),
                  ],
                );
              },
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
