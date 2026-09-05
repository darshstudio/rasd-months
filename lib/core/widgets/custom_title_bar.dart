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
      padding: const EdgeInsets.only(right: 16, left: 4),
      child: Row(
        children: [
          ?leadingWidget,
          const SizedBox(width: 4),
          const Icon(
            Icons.assessment_rounded,
            color: AppColors.primaryDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            widget.title,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.primaryDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ...?actionWidgets,
          if (isDesktop && widget.showWindowControls) ...[
            const SizedBox(width: 4),
            _MD3WindowButton(
              icon: Icons.remove_rounded,
              onPressed: () => windowManager.minimize(),
              tooltip: "تصغير",
            ),
            _MD3WindowButton(
              icon: _isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
              iconSize: 14,
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
            _MD3WindowButton(
              icon: Icons.close_rounded,
              isClose: true,
              onPressed: () => windowManager.close(),
              tooltip: "إغلاق",
            ),
          ],
        ],
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

class _MD3WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;
  final double iconSize;

  const _MD3WindowButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
    this.iconSize = 18,
  });

  @override
  State<_MD3WindowButton> createState() => _MD3WindowButtonState();
}

class _MD3WindowButtonState extends State<_MD3WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.transparent;
    Color fg = AppColors.primaryDark;

    if (_isHovered) {
      bg = widget.isClose
          ? AppColors.errorRed
          : AppColors.secondaryDark.withValues(alpha: 0.12);
      fg = widget.isClose ? AppColors.white : AppColors.primaryDark;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: IconButton(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: widget.iconSize, color: fg),
          style: IconButton.styleFrom(
            backgroundColor: bg,
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
          ),
        ),
      ),
    );
  }
}
