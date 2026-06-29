import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/fee_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tuition.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_name TEXT NOT NULL,
        whatsapp_number TEXT NOT NULL,
        subject TEXT NOT NULL,
        monthly_fee REAL NOT NULL,
        admission_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE fee_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount REAL NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        paid_date TEXT,
        notes TEXT,
        FOREIGN KEY (student_id) REFERENCES students(id),
        UNIQUE(student_id, month, year)
      )
    ''');
  }

  // ─── Students ───────────────────────────────────────────────────────────────

  Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final maps = await db.query('students', where: 'is_active = 1', orderBy: 'name ASC');
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<List<Student>> getDemoStudents() async {
    final db = await database;
    final cutoff = DateTime.now().subtract(const Duration(days: 3)).toIso8601String();
    final maps = await db.query(
      'students',
      where: 'is_active = 1 AND admission_date > ?',
      whereArgs: [cutoff],
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    await db.update('students', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
    return 1;
  }

  // ─── Fee Records ─────────────────────────────────────────────────────────────

  Future<int> upsertFeeRecord(FeeRecord record) async {
    final db = await database;
    final existing = await db.query(
      'fee_records',
      where: 'student_id = ? AND month = ? AND year = ?',
      whereArgs: [record.studentId, record.month, record.year],
    );
    if (existing.isEmpty) {
      return await db.insert('fee_records', record.toMap());
    } else {
      await db.update(
        'fee_records',
        record.toMap(),
        where: 'student_id = ? AND month = ? AND year = ?',
        whereArgs: [record.studentId, record.month, record.year],
      );
      return existing.first['id'] as int;
    }
  }

  Future<List<FeeRecord>> getFeeRecordsForMonth(int month, int year) async {
    final db = await database;
    final maps = await db.query(
      'fee_records',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return maps.map((m) => FeeRecord.fromMap(m)).toList();
  }

  Future<List<FeeRecord>> getFeeRecordsForStudent(int studentId) async {
    final db = await database;
    final maps = await db.query(
      'fee_records',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'year DESC, month DESC',
    );
    return maps.map((m) => FeeRecord.fromMap(m)).toList();
  }

  Future<FeeRecord?> getFeeRecord(int studentId, int month, int year) async {
    final db = await database;
    final maps = await db.query(
      'fee_records',
      where: 'student_id = ? AND month = ? AND year = ?',
      whereArgs: [studentId, month, year],
    );
    if (maps.isEmpty) return null;
    return FeeRecord.fromMap(maps.first);
  }

  Future<Map<String, int>> getDashboardStats() async {
    final db = await database;
    final now = DateTime.now();

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE is_active = 1',
    );
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    final cutoff = now.subtract(const Duration(days: 3)).toIso8601String();
    final demoResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE is_active = 1 AND admission_date > ?',
      [cutoff],
    );
    final demo = Sqflite.firstIntValue(demoResult) ?? 0;

    final unpaidResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM fee_records
      WHERE month = ? AND year = ? AND is_paid = 0
    ''', [now.month, now.year]);
    final unpaid = Sqflite.firstIntValue(unpaidResult) ?? 0;

    return {'total': total, 'demo': demo, 'unpaid': unpaid};
  }
}
