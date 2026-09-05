import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final IconData? prefixIcon;
  final double height;
  final double? width;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.prefixIcon,
    this.height = 48.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        height: height,
        width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.mutedBorder, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: width != null,
          hint: hint != null
              ? Text(
                  hint!,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    color: AppColors.secondaryDark,
                  ),
                )
              : null,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.secondaryDark,
            size: 22,
          ),
          dropdownColor: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          elevation: 3,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    ),
  );
}
}
