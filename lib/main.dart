import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'core/database/database_helper.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/custom_title_bar.dart';
import 'providers/academic_year_provider.dart';
import 'providers/class_provider.dart';
import 'providers/subject_provider.dart';
import 'providers/student_provider.dart';
import 'providers/grade_provider.dart';
import 'views/dashboard/dashboard_screen.dart';
import 'views/year_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initFfi();

  // Production Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      debugPrint("Captured Release Error: ${details.exceptionAsString()}");
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint("Captured Release Async Error: $error");
    return true;
  };

  // User-friendly Arabic Error UI in Release Mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      return Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                SizedBox(height: 12),
                Text(
                  "حدث تنبيه غير متوقع في هذه الشاشة",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                ),
                SizedBox(height: 6),
                Text(
                  "يرجى إعادة الانتقال للشاشة لتنشيط البيانات بشكل سليم.",
                  style: TextStyle(fontSize: 13, color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ErrorWidget(details.exception);
  };

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1024, 700),
      center: true,
      backgroundColor: AppColors.neutralBackground,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'تطبيق رصد الشهري - درجات الملف',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const RasdApp());
}

class RasdApp extends StatelessWidget {
  const RasdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AcademicYearProvider()..loadAcademicYears(),
        ),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => GradeProvider()),
      ],
      child: MaterialApp(
        title: 'برنامج رصد الشهري - درجات الملف',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar', 'EG'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'EG'),
        ],
        home: const AppRootShell(),
      ),
    );
  }
}

class AppRootShell extends StatefulWidget {
  const AppRootShell({super.key});

  @override
  State<AppRootShell> createState() => _AppRootShellState();
}

class _AppRootShellState extends State<AppRootShell> {
  bool _hasSelectedYear = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AcademicYearProvider>(
      builder: (context, yearProv, child) {
        if (yearProv.isLoading) {
          return const Scaffold(
            body: Column(
              children: [
                CustomTitleBar(title: "تطبيق رصد الشهري - درجات الملف"),
                Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          );
        }

        if (!_hasSelectedYear || yearProv.selectedYear == null) {
          return YearSelectionScreen(
            onYearSelected: () {
              setState(() {
                _hasSelectedYear = true;
              });
            },
          );
        }

        // Active year selected: Render DashboardScreen
        return DashboardScreen(
          academicYearName: yearProv.selectedYear!.name,
          onChangeYear: () {
            setState(() {
              _hasSelectedYear = false;
            });
          },
        );
      },
    );
  }
}
