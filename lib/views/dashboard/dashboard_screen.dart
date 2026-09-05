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

                      // Two Main Stage Cards: Primary & Preparatory (Responsive Layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 750;
                          final primaryCard = _buildStageCard(
                            stageTitle: "الحلقة الابتدائية",
                            subtitle: "تضم الصفوف من الأول إلى السادس الابتدائي",
                            icon: Icons.child_care_rounded,
                            grades: _primaryGrades,
                          );
                          final prepCard = _buildStageCard(
                            stageTitle: "الحلقة الإعدادية",
                            subtitle: "تضم الصفين الأول والثاني الإعدادي فقط",
                            icon: Icons.school_rounded,
                            grades: _prepGrades,
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                primaryCard,
                                const SizedBox(height: 24),
                                prepCard,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: primaryCard),
                              const SizedBox(width: 24),
                              Expanded(child: prepCard),
                            ],
                          );
                        },
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

  /// Build Term Tabs Header (eCoursie Filter Pill style)
  Widget _buildTermTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.filterPillBackground,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.mutedBorder),
      ),
      padding: const EdgeInsets.all(5),
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

  /// Build Stage Card (eCoursie Course Card style with soft floating shadow & rounded action buttons)
  Widget _buildStageCard({
    required String stageTitle,
    required String subtitle,
    required IconData icon,
    required List<String> grades,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [AppColors.cardShadow],
        border: Border.all(color: AppColors.mutedBorder.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardLavender,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 26),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grades.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.mutedBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.class_outlined,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          grade,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded, // Left arrow for RTL
                          color: Colors.white,
                          size: 13,
                        ),
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
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.secondaryDark,
          ),
        ),
      ),
    );
  }
}

