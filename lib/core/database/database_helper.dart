import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/academic_year.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Database? _masterDb;
  Database? _yearDb;
  AcademicYear? _currentAcademicYear;

  AcademicYear? get currentAcademicYear => _currentAcademicYear;
  Database get yearDb {
    if (_yearDb == null) {
      throw Exception("لم يتم اختيار أو فتح عام دراسي حتى الآن!");
    }
    return _yearDb!;
  }

  /// Initialize SQLite FFI for Desktop (Windows / Linux)
  static void initFfi() {
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Get Directory for Database files
  Future<String> get _dbDirectoryPath async {
    final docsDir = await getApplicationDocumentsDirectory();
    final appDir = Directory(p.join(docsDir.path, 'RasdAppData'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir.path;
  }

  /// Get Master DB connection
  Future<Database> get masterDb async {
    if (_masterDb != null) return _masterDb!;
    _masterDb = await _initMasterDb();
    return _masterDb!;
  }

  Future<Database> _initMasterDb() async {
    final dirPath = await _dbDirectoryPath;
    final path = p.join(dirPath, 'rasd_master.db');
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onOpen: (db) async {
          await db.execute('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE academic_years (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              db_file_name TEXT NOT NULL,
              is_language_school INTEGER DEFAULT 0,
              is_active INTEGER DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  /// List all Academic Years
  Future<List<AcademicYear>> getAllAcademicYears() async {
    final db = await masterDb;
    final maps = await db.query('academic_years', orderBy: 'id DESC');
    return maps.map((m) => AcademicYear.fromMap(m)).toList();
  }

  /// Create a new Academic Year & initialize its separate database file
  Future<AcademicYear> createAcademicYear(String name, {bool isLanguageSchool = false}) async {
    final db = await masterDb;
    final safeName = name.replaceAll('/', '_').replaceAll('\\', '_').trim();
    final dbFileName = 'rasd_year_$safeName.db';

    // Insert into master
    final id = await db.insert('academic_years', {
      'name': name,
      'db_file_name': dbFileName,
      'is_language_school': isLanguageSchool ? 1 : 0,
      'is_active': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    final newYear = AcademicYear(
      id: id,
      name: name,
      dbFileName: dbFileName,
      isLanguageSchool: isLanguageSchool,
      isActive: false,
    );

    // Initialize year database
    await _switchAcademicYear(newYear);
    return newYear;
  }

  /// Switch active Academic Year
  Future<void> switchAcademicYear(AcademicYear year) async {
    final db = await masterDb;
    await db.update('academic_years', {'is_active': 0});
    await db.update(
      'academic_years',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [year.id],
    );
    await _switchAcademicYear(year);
  }

  Future<void> _switchAcademicYear(AcademicYear year) async {
    if (_yearDb != null) {
      await _yearDb!.close();
      _yearDb = null;
    }

    final dirPath = await _dbDirectoryPath;
    final path = p.join(dirPath, year.dbFileName);

    _yearDb = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createYearDbSchema,
        onOpen: (db) async {
          await db.execute('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS grade_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              seating_number TEXT NOT NULL,
              subject_id INTEGER NOT NULL,
              assessment_item_id INTEGER NOT NULL,
              term INTEGER NOT NULL CHECK(term IN (1, 2)),
              month_1_score REAL,
              month_2_score REAL,
              month_3_score REAL,
              pass_fail_status TEXT,
              FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
              FOREIGN KEY (assessment_item_id) REFERENCES assessment_items(id) ON DELETE CASCADE,
              UNIQUE(seating_number, subject_id, assessment_item_id, term)
            )
          ''');

          // Create performance indexes if missing
          await db.execute('CREATE INDEX IF NOT EXISTS idx_students_stage_class ON students(stage, class_name, seating_number);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_subjects_grade ON subjects(grade_level);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_assessment_items_sub ON assessment_items(subject_id);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_records_sub_term ON grade_records(subject_id, term);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_records_seating_sub_term ON grade_records(seating_number, subject_id, term);');
        },
      ),
    );

    _currentAcademicYear = year;
    await _seedDefaultSubjectsAndItems(_yearDb!, year.isLanguageSchool);
  }

  /// Create tables schema for Academic Year database
  Future<void> _createYearDbSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE school_classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stage TEXT NOT NULL,
        grade_level TEXT NOT NULL,
        class_name TEXT NOT NULL,
        UNIQUE(grade_level, class_name)
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seating_number TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        stage TEXT NOT NULL,
        class_name TEXT NOT NULL,
        gender TEXT NOT NULL,
        class_id INTEGER,
        FOREIGN KEY (class_id) REFERENCES school_classes(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        stage TEXT NOT NULL,
        grade_level TEXT NOT NULL,
        assessment_type TEXT NOT NULL DEFAULT 'grades',
        UNIQUE(grade_level, name)
      )
    ''');

    await db.execute('''
      CREATE TABLE assessment_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        max_score REAL NOT NULL,
        exists_in_month_3 INTEGER DEFAULT 1,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE grade_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seating_number TEXT NOT NULL,
        subject_id INTEGER NOT NULL,
        assessment_item_id INTEGER NOT NULL,
        term INTEGER NOT NULL CHECK(term IN (1, 2)),
        month_1_score REAL,
        month_2_score REAL,
        month_3_score REAL,
        pass_fail_status TEXT,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
        FOREIGN KEY (assessment_item_id) REFERENCES assessment_items(id) ON DELETE CASCADE,
        UNIQUE(seating_number, subject_id, assessment_item_id, term)
      )
    ''');

    // Create Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_students_stage_class ON students(stage, class_name, seating_number);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subjects_grade ON subjects(grade_level);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_assessment_items_sub ON assessment_items(subject_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_records_sub_term ON grade_records(subject_id, term);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_grade_records_seating_sub_term ON grade_records(seating_number, subject_id, term);');
  }

  /// Helper to get first int value from query
  static int? _firstIntValue(List<Map<String, Object?>> list) {
    if (list.isNotEmpty && list.first.isNotEmpty) {
      final val = list.first.values.first;
      if (val is int) return val;
      if (val is num) return val.toInt();
    }
    return null;
  }

  /// Pre-populate and sync subjects and default assessment items according to instructions
  Future<void> _seedDefaultSubjectsAndItems(Database db, bool isLanguageSchool) async {
    // Primary Stage Grades (1 to 6)
    final primaryGradesLower = ['الصف الأول الابتدائي', 'الصف الثاني الابتدائي', 'الصف الثالث الابتدائي'];
    final primaryGradesUpper = ['الصف الرابع الابتدائي', 'الصف الخامس الابتدائي', 'الصف السادس الابتدائي'];
    
    // Preparatory Stage Grades (1 & 2 ONLY)
    final prepGrades = ['الصف الأول الإعدادي', 'الصف الثاني الإعدادي'];

    final Map<String, List<Map<String, String>>> gradeSubjectMap = {};

    // 1. Lower Primary Subjects (1-3)
    for (final grade in primaryGradesLower) {
      gradeSubjectMap[grade] = [
        {'name': 'اللغة العربية', 'type': 'grades'},
        {'name': 'اللغة الإنجليزية', 'type': 'grades'},
        {'name': 'الرياضيات', 'type': 'grades'},
        {'name': 'التربية الدينية', 'type': 'grades'},
        if (isLanguageSchool) {'name': 'اللغة الإنجليزية الإضافية', 'type': 'grades'}, // لمدارس اللغات فقط
        {'name': 'التربية البدنية والصحية', 'type': 'pass_fail'},
        {'name': 'أنشطة التوكاتسو', 'type': 'pass_fail'},
      ];
    }

    // 2. Upper Primary Subjects (4-6)
    for (final grade in primaryGradesUpper) {
      gradeSubjectMap[grade] = [
        {'name': 'اللغة العربية', 'type': 'grades'},
        {'name': 'اللغة الإنجليزية', 'type': 'grades'},
        {'name': 'الرياضيات', 'type': 'grades'},
        {'name': 'العلوم', 'type': 'grades'},
        {'name': 'الدراسات الاجتماعية', 'type': 'grades'},
        {'name': 'التربية الدينية', 'type': 'grades'},
        {'name': 'تكنولوجيا المعلومات والاتصالات', 'type': 'grades'},
        if (isLanguageSchool) {'name': 'اللغة الإنجليزية الإضافية', 'type': 'grades'}, // لمدارس اللغات فقط
        {'name': 'التربية الفنية', 'type': 'pass_fail'},
        {'name': 'التربية البدنية والصحية', 'type': 'pass_fail'},
        {'name': 'التربية الموسيقية', 'type': 'pass_fail'},
        {'name': 'مجالات', 'type': 'pass_fail'},
      ];
    }

    // 3. Preparatory Subjects (Grades 1 & 2 ONLY)
    for (final grade in prepGrades) {
      gradeSubjectMap[grade] = [
        {'name': 'اللغة العربية', 'type': 'grades'},
        {'name': 'الرياضيات', 'type': 'grades'},
        {'name': 'اللغة الإنجليزية', 'type': 'grades'},
        {'name': 'العلوم', 'type': 'grades'},
        {'name': 'الدراسات الاجتماعية', 'type': 'grades'},
        {'name': 'تربية دينية', 'type': 'grades'},
        {'name': 'الكمبيوتر', 'type': 'grades'},
        {'name': 'التربية الفنية', 'type': 'grades'},
        {'name': 'التربية البدنية', 'type': 'grades'},
        {'name': 'التربية الموسيقية', 'type': 'grades'},
        {'name': 'أنشطة اختيارية 1', 'type': 'grades'},
        {'name': 'أنشطة اختيارية 2', 'type': 'grades'},
        {'name': 'المستوى الرفيع 1', 'type': 'grades'},
        {'name': 'المستوى الرفيع 2', 'type': 'grades'},
      ];
    }

    for (final entry in gradeSubjectMap.entries) {
      final gradeLevel = entry.key;
      final expectedSubjects = entry.value;
      final stage = gradeLevel.contains('إعدادي') ? 'الحلقة الإعدادية' : 'الحلقة الابتدائية';
      final allowedNames = expectedSubjects.map((s) => s['name']!).toSet();

      // Delete outdated subjects not in expected list for this grade
      final existingSubs = await db.query(
        'subjects',
        where: 'grade_level = ?',
        whereArgs: [gradeLevel],
      );

      for (final existing in existingSubs) {
        final existingName = existing['name'] as String;
        final existingId = existing['id'] as int;
        if (!allowedNames.contains(existingName)) {
          await db.delete('subjects', where: 'id = ?', whereArgs: [existingId]);
        }
      }

      // Upsert expected subjects
      for (final s in expectedSubjects) {
        final subName = s['name']!;
        final subType = s['type']!;

        final match = await db.query(
          'subjects',
          where: 'grade_level = ? AND name = ?',
          whereArgs: [gradeLevel, subName],
        );

        int subId;
        if (match.isEmpty) {
          subId = await db.insert('subjects', {
            'name': subName,
            'stage': stage,
            'grade_level': gradeLevel,
            'assessment_type': subType,
          });
        } else {
          final existingSub = match.first;
          subId = existingSub['id'] as int;
          if (existingSub['assessment_type'] != subType) {
            await db.update('subjects', {'assessment_type': subType}, where: 'id = ?', whereArgs: [subId]);
          }
        }

        if (subType == 'grades') {
          final isPrep = stage == 'الحلقة الإعدادية' || gradeLevel.contains('إعدادي');
          final itemsCount = _firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM assessment_items WHERE subject_id = ?', [subId]));
          if (itemsCount == null || itemsCount == 0 || (isPrep && itemsCount != 4) || (!isPrep && itemsCount != 5)) {
            await db.delete('assessment_items', where: 'subject_id = ?', whereArgs: [subId]);
            if (isPrep) {
              await _insertPrepItems(db, subId);
            } else {
              await _insertPrimaryItems(db, subId);
            }
          }
        }
      }
    }
  }

  /// Assessment Items for Primary Stage (5+5+10+15+5 = 40)
  Future<void> _insertPrimaryItems(Database db, int subjectId) async {
    final items = [
      {'name': 'واجب منزلي', 'max': 5.0, 'm3': 1},
      {'name': 'كراسة الحصة', 'max': 5.0, 'm3': 1},
      {'name': 'تقييم أسبوعي', 'max': 10.0, 'm3': 1},
      {'name': 'اختبارات الشهور', 'max': 15.0, 'm3': 0},
      {'name': 'مواظبة وسلوك', 'max': 5.0, 'm3': 1},
    ];

    for (final item in items) {
      await db.insert('assessment_items', {
        'subject_id': subjectId,
        'item_name': item['name'],
        'max_score': item['max'],
        'exists_in_month_3': item['m3'],
      });
    }
  }

  /// Assessment Items for Preparatory Stage (20+10+10+15)
  Future<void> _insertPrepItems(Database db, int subjectId) async {
    final items = [
      {'name': 'تقييمات أسبوعية', 'max': 20.0, 'm3': 1},
      {'name': 'واجبات منزلية', 'max': 10.0, 'm3': 1},
      {'name': 'السلوك والمواظبة', 'max': 10.0, 'm3': 1},
      {'name': 'اختبارات الشهور', 'max': 15.0, 'm3': 0},
    ];

    for (final item in items) {
      await db.insert('assessment_items', {
        'subject_id': subjectId,
        'item_name': item['name'],
        'max_score': item['max'],
        'exists_in_month_3': item['m3'],
      });
    }
  }
}
