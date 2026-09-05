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
    this.height = 42.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.mutedBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: AppColors.lightSurface,
          focusColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: AppColors.primaryDark.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefixIcon != null) ...[
              Icon(
                prefixIcon,
                size: 18,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  items: items,
                  onChanged: onChanged,
                  isDense: true,
                  isExpanded: true,
                  focusColor: Colors.transparent,
                  hint: hint != null
                      ? Text(
                          hint!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        )
                      : null,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  dropdownColor: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 6,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return items.map<Widget>((DropdownMenuItem<T> item) {
                      return Align(
                        alignment: Alignment.centerRight,
                        widthFactor: 1.0,
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          child: item.child,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
