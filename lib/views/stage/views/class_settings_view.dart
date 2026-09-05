import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/school_class.dart';
import '../../../providers/class_provider.dart';

class ClassSettingsView extends StatefulWidget {
  final String gradeLevel;

  const ClassSettingsView({super.key, required this.gradeLevel});

  @override
  State<ClassSettingsView> createState() => _ClassSettingsViewState();
}

class _ClassSettingsViewState extends State<ClassSettingsView> {
  final _classNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stage = widget.gradeLevel.contains('إعدادي') ? 'الحلقة الإعدادية' : 'الحلقة الابتدائية';
      Provider.of<ClassProvider>(context, listen: false).loadClassesForGrade(stage, widget.gradeLevel);
    });
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  void _showAddClassDialog(BuildContext context) {
    _classNameController.clear();
    final prov = Provider.of<ClassProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("إضافة فصل جديد"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("اسم الفصل لـ (${widget.gradeLevel}):", style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: _classNameController,
              decoration: const InputDecoration(
                hintText: "مثال: 5/1 أو 5A",
                prefixIcon: Icon(Icons.meeting_room_outlined),
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
              final name = _classNameController.text.trim();
              if (name.isNotEmpty) {
                final stage = widget.gradeLevel.contains('إعدادي') ? 'الحلقة الإعدادية' : 'الحلقة الابتدائية';
                Navigator.pop(ctx);
                final success = await prov.addClass(stage, widget.gradeLevel, name);
                if (!success && mounted && prov.error != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(prov.error!), backgroundColor: AppColors.errorRed),
                  );
                }
              }
            },
            child: const Text("حفظ الفصل"),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(BuildContext context, SchoolClass sc) {
    _classNameController.text = sc.className;
    final prov = Provider.of<ClassProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تعديل اسم الفصل"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("اسم الفصل الجديد:", style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: _classNameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.edit_outlined),
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
              final name = _classNameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await prov.updateClass(sc, name);
              }
            },
            child: const Text("حفظ التعديل"),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "إعدادات الفصول - ${widget.gradeLevel}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "إضافة وتعديل أسماء الفصول المقررة للعمل بها بالكنترول وشاشات الرصد.",
                      style: TextStyle(fontSize: 13, color: AppColors.secondaryDark),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddClassDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("إضافة فصل جديد"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<ClassProvider>(
              builder: (context, classProv, child) {
                if (classProv.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (classProv.classes.isEmpty) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.meeting_room_outlined, size: 48, color: AppColors.mutedBorder),
                        const SizedBox(height: 12),
                        Text(
                          "لا يوجد فصول مسجلة لـ (${widget.gradeLevel}) حتى الآن.",
                          style: const TextStyle(fontSize: 14, color: AppColors.secondaryDark),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddClassDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("إضافة الفصل الأول"),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 100,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: classProv.classes.length,
                  itemBuilder: (context, index) {
                    final sc = classProv.classes[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryDark.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.meeting_room_rounded, color: AppColors.primaryDark, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sc.className,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Text(
                                  sc.gradeLevel,
                                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.secondaryDark, size: 18),
                            onSelected: (val) async {
                              if (val == 'edit') {
                                _showEditClassDialog(context, sc);
                              } else if (val == 'delete') {
                                await classProv.deleteClass(sc);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryDark),
                                    SizedBox(width: 8),
                                    Text('تعديل'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.errorRed),
                                    SizedBox(width: 8),
                                    Text('حذف', style: TextStyle(color: AppColors.errorRed)),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
