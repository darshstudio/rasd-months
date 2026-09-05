import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/assessment_item.dart';
import '../../../models/subject.dart';
import '../../../providers/subject_provider.dart';

class SubjectSettingsView extends StatefulWidget {
  final String gradeLevel;

  const SubjectSettingsView({super.key, required this.gradeLevel});

  @override
  State<SubjectSettingsView> createState() => _SubjectSettingsViewState();
}

class _SubjectSettingsViewState extends State<SubjectSettingsView> {
  final _maxScoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubjectProvider>(context, listen: false).loadSubjectsForGrade(widget.gradeLevel);
    });
  }

  @override
  void dispose() {
    _maxScoreController.dispose();
    super.dispose();
  }

  void _showEditMaxScoreDialog(BuildContext context, Subject sub, AssessmentItem item) {
    _maxScoreController.text = item.maxScore.toStringAsFixed(item.maxScore.truncateToDouble() == item.maxScore ? 0 : 1);
    final prov = Provider.of<SubjectProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تعديل النهاية العظمى: ${item.itemName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("المادة: ${sub.name}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("النهاية العظمى الجديدة للبند:", style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _maxScoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: "مثال: 15.0",
                suffixText: "درجة",
                prefixIcon: Icon(Icons.score_outlined),
              ),
              autofocus: true,
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
              final newScore = double.tryParse(_maxScoreController.text.trim());
              if (newScore != null && newScore > 0) {
                Navigator.pop(ctx);
                await prov.updateAssessmentItemMaxScore(item, newScore);
              }
            },
            child: const Text("حفظ النهاية العظمى"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      color: AppColors.neutralBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "إعدادات المواد والبنود التقييمية - ${widget.gradeLevel}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "تصفح المواد التقييمية المعتمدة رسمياً، وتخصيص النهاية العظمى لبنود التقييم حسب النشرات التوجيهية.",
            style: TextStyle(fontSize: 13, color: AppColors.secondaryDark),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<SubjectProvider>(
              builder: (context, subProv, child) {
                if (subProv.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (subProv.subjects.isEmpty) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: const Center(
                      child: Text("جاري تحميل وإعداد المواد التقييمية..."),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: subProv.subjects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final sub = subProv.subjects[index];
                    final items = subProv.assessmentItems[sub.id] ?? [];

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondaryDark.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.book_rounded, color: AppColors.primaryDark, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                sub.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sub.isPassFail
                                      ? AppColors.warningOrange.withValues(alpha: 0.15)
                                      : AppColors.successGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sub.isPassFail ? "تقييم: اجتاز / لم يجتز" : "تقييم بالدرجات",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: sub.isPassFail ? AppColors.warningOrange : AppColors.successGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!sub.isPassFail && items.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: AppColors.mutedBorder),
                            const SizedBox(height: 12),
                            const Text(
                              "بنود التقييم المعتمدة والنهايات العظمى لكل شهر:",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: items.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.mutedBorder, width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.itemName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                          Text(
                                            "العظمى: ${item.maxScore.toStringAsFixed(item.maxScore.truncateToDouble() == item.maxScore ? 0 : 1)} درجة",
                                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryDark),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      InkWell(
                                        onTap: () => _showEditMaxScoreDialog(context, sub, item),
                                        borderRadius: BorderRadius.circular(4),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.edit_note_rounded, color: AppColors.secondaryDark, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
