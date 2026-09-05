import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/custom_title_bar.dart';
import '../providers/academic_year_provider.dart';

class YearSelectionScreen extends StatefulWidget {
  final VoidCallback onYearSelected;

  const YearSelectionScreen({
    super.key,
    required this.onYearSelected,
  });

  @override
  State<YearSelectionScreen> createState() => _YearSelectionScreenState();
}

class _YearSelectionScreenState extends State<YearSelectionScreen> {
  final _newYearController = TextEditingController();

  @override
  void dispose() {
    _newYearController.dispose();
    super.dispose();
  }

  void _showCreateYearDialog(BuildContext context) {
    bool isLanguageSchool = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text("إنشاء عام دراسي جديد"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "أدخل اسم العام الدراسي (سيتم إنشاء قاعدة بيانات منفصلة له):",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newYearController,
                decoration: const InputDecoration(
                  hintText: "مثال: 2025/2026",
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Material(
                color: AppColors.neutralBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.mutedBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: CheckboxListTile(
                  value: isLanguageSchool,
                  onChanged: (val) {
                    setDialogState(() => isLanguageSchool = val ?? false);
                  },
                  activeColor: AppColors.primaryDark,
                  title: const Text(
                    "مدرسة لغات (رسمية لغات / خاصة لغات)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                  ),
                  subtitle: const Text(
                    "تفعيل تجميع رصد مادة (اللغة الإنجليزية الإضافية) لصفوف المرحلة الابتدائية",
                    style: TextStyle(fontSize: 11, color: AppColors.secondaryDark),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _newYearController.text.trim();
                if (name.isNotEmpty) {
                  final nav = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(this.context);
                  final yearProv = Provider.of<AcademicYearProvider>(this.context, listen: false);
                  final success = await yearProv.createYear(name, isLanguageSchool: isLanguageSchool);
                  if (success) {
                    nav.pop();
                    _newYearController.clear();
                    if (mounted) widget.onYearSelected();
                  } else if (yearProv.error != null) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(yearProv.error!),
                        backgroundColor: AppColors.errorRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text("إنشاء وتفعيل"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      body: Column(
        children: [
          const CustomTitleBar(
            title: "تطبيق رصد درجات الملف - تحديد العام الدراسي",
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 580),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Consumer<AcademicYearProvider>(
                    builder: (context, yearProv, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset(
                            'assets/images/app_logo_full.png',
                            height: 90,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.school_rounded,
                              size: 64,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "مرحباً بك في برنامج رصد",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "اختر العام الدراسي الحالي أو قم بإنشاء عام دراسي جديد لبدء العمل",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (yearProv.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else ...[
                            if (yearProv.years.isEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.neutralBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.mutedBorder),
                                ),
                                child: const Text(
                                  "لا يوجد أعوام دراسية حتى الآن. اضغط على الزر أدناه لإنشاء عامك الدراسي الأول.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else ...[
                              const Text(
                                "الأعوام الدراسية المسجلة:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 240),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: yearProv.years.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final year = yearProv.years[index];
                                    final isSelected = yearProv.selectedYear?.id == year.id;

                                    return InkWell(
                                      onTap: () async {
                                        await yearProv.selectYear(year);
                                        widget.onYearSelected();
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.lightSurface
                                              : AppColors.lightSurface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primaryDark
                                                : AppColors.mutedBorder,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected ? [AppColors.cardShadow] : [],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_month_rounded,
                                              color: isSelected
                                                  ? AppColors.primaryDark
                                                  : AppColors.secondaryDark,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "العام الدراسي: ${year.name}",
                                                    style: TextStyle(
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    year.isLanguageSchool ? "نوع المدرسة: لغات" : "نوع المدرسة: عربي / عادية",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: year.isLanguageSchool ? AppColors.primaryDark : AppColors.secondaryDark,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: AppColors.primaryDark,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => _showCreateYearDialog(context),
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text(
                                  "إنشاء عام دراسي جديد",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
