import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_title_bar.dart';
import '../stage/stage_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String academicYearName;
  final VoidCallback onChangeYear;

  const DashboardScreen({
    super.key,
    required this.academicYearName,
    required this.onChangeYear,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTerm = 1; // 1: الترم الأول, 2: الترم الثاني

  final List<String> _primaryGrades = const [
    'الصف الأول الابتدائي',
    'الصف الثاني الابتدائي',
    'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي',
    'الصف الخامس الابتدائي',
    'الصف السادس الابتدائي',
  ];

  final List<String> _prepGrades = const [
    'الصف الأول الإعدادي',
    'الصف الثاني الإعدادي',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      body: Column(
        children: [
          CustomTitleBar(
            title: "العام الدراسي: ${widget.academicYearName}",
            actions: [
              OutlinedButton.icon(
                onPressed: widget.onChangeYear,
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text("تغيير العام الدراسي"),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.lightSurface,
                  side: const BorderSide(color: AppColors.mutedBorder, width: 1),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Term Selection Tabs Header (Pure white seamless)
                      _buildTermTabs(),
                      const SizedBox(height: 28),

                      // Two Main Stage Cards: Primary & Preparatory (Seamless pure white)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card 1: الحلقة الابتدائية (Primary Stage)
                          Expanded(
                            child: _buildStageCard(
                              stageTitle: "الحلقة الابتدائية",
                              subtitle: "تضم الصفوف من الأول إلى السادس الابتدائي",
                              icon: Icons.child_care_rounded,
                              grades: _primaryGrades,
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Card 2: الحلقة الإعدادية (Preparatory Stage - Grades 1 & 2 ONLY)
                          Expanded(
                            child: _buildStageCard(
                              stageTitle: "الحلقة الإعدادية",
                              subtitle: "تضم الصفين الأول والثاني الإعدادي فقط",
                              icon: Icons.school_rounded,
                              grades: _prepGrades,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Term Tabs Header (Seamless pure white without borders or shadows)
  Widget _buildTermTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _TermTabButton(
              title: "الفصل الدراسي الأول",
              isSelected: _selectedTerm == 1,
              onTap: () => setState(() => _selectedTerm = 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TermTabButton(
              title: "الفصل الدراسي الثاني",
              isSelected: _selectedTerm == 2,
              onTap: () => setState(() => _selectedTerm = 2),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Stage Card (Seamless pure white without borders or shadows)
  Widget _buildStageCard({
    required String stageTitle,
    required String subtitle,
    required IconData icon,
    required List<String> grades,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stageTitle,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grades.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final grade = grades[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => StageScreen(
                        stageName: stageTitle,
                        gradeLevel: grade,
                        selectedTerm: _selectedTerm,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryDark.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.class_outlined,
                        color: AppColors.secondaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          grade,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.secondaryDark,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TermTabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TermTabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.secondaryDark.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
