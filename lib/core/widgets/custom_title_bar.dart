import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class CustomTitleBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showWindowControls;
  final Color? backgroundColor;

  const CustomTitleBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showWindowControls = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _checkMaximized();
    }
  }

  Future<void> _checkMaximized() async {
    final max = await windowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = max);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final leadingWidget = widget.leading;
    final actionWidgets = widget.actions;

    final titleBarContent = Container(
      height: 44,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.neutralBackground,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            const SizedBox(width: 12),
            if (leadingWidget != null) ...[
              leadingWidget,
              const SizedBox(width: 4),
            ],
            Image.asset(
              'assets/images/app_icon.png',
              width: 22,
              height: 22,
              errorBuilder: (ctx, err, stack) => const Icon(
                Icons.assessment_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Center(
                child: Text(
                  widget.title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...?actionWidgets,

            // Window Controls (Strictly LTR: Minimize -> Maximize -> Close at FAR RIGHT EDGE)
            if (isDesktop && widget.showWindowControls) ...[
              const SizedBox(width: 8),
              _StandardWindowButton(
                icon: Icons.remove_rounded,
                onPressed: () => windowManager.minimize(),
                tooltip: "تصغير",
              ),
              _StandardWindowButton(
                icon: _isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
                iconSize: 13,
                onPressed: () async {
                  if (_isMaximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                  _checkMaximized();
                },
                tooltip: _isMaximized ? "استعادة" : "تكبير",
              ),
              _StandardWindowButton(
                icon: Icons.close_rounded,
                isClose: true,
                onPressed: () => windowManager.close(),
                tooltip: "إغلاق",
              ),
            ],
          ],
        ),
      ),
    );

    if (isDesktop) {
      return DragToMoveArea(
        child: titleBarContent,
      );
    }

    return titleBarContent;
  }
}

class _StandardWindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;
  final double iconSize;

  const _StandardWindowButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
    this.iconSize = 17,
  });

  @override
  State<_StandardWindowButton> createState() => _StandardWindowButtonState();
}

class _StandardWindowButtonState extends State<_StandardWindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.transparent;
    Color fg = AppColors.textPrimary;

    if (_isHovered) {
      bg = widget.isClose
          ? AppColors.errorRed
          : AppColors.secondaryText.withValues(alpha: 0.12);
      fg = widget.isClose ? AppColors.white : AppColors.textPrimary;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: widget.iconSize, color: fg),
          ),
        ),
      ),
    );
  }
}


