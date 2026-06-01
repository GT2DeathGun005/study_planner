import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();


  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }


  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'study_planner.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }


  Future<void> _onCreate(Database db, int version) async {
    // Tabella corsi
    await db.execute('''
      CREATE TABLE corsi (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        docente TEXT NOT NULL,
        semestre INTEGER NOT NULL,
        cfu INTEGER NOT NULL,
        descrizione TEXT DEFAULT '',
        stato TEXT DEFAULT 'da_iniziare',
        tipo_laurea TEXT DEFAULT 'triennale',
        anno INTEGER DEFAULT 1,
        voto_previsto INTEGER,
        materiali TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        lode INTEGER DEFAULT 0
      )
    ''');

    // Tabella esami
    await db.execute('''
      CREATE TABLE esami (
        id TEXT PRIMARY KEY,
        titolo TEXT NOT NULL,
        corso_id TEXT NOT NULL,
        data TEXT NOT NULL,
        tipologia TEXT DEFAULT 'scritto',
        priorita TEXT DEFAULT 'media',
        stato TEXT DEFAULT 'programmato',
        voto INTEGER,
        peso_percentuale INTEGER DEFAULT 100,
        note TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (corso_id) REFERENCES corsi (id) ON DELETE CASCADE
      )
    ''');

    // Tabella obiettivi
    await db.execute('''
      CREATE TABLE obiettivi (
        id TEXT PRIMARY KEY,
        titolo TEXT NOT NULL,
        descrizione TEXT DEFAULT '',
        corso_id TEXT,
        priorita TEXT DEFAULT 'media',
        stato TEXT DEFAULT 'prefissato',
        data_pianificata TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (corso_id) REFERENCES corsi (id) ON DELETE SET NULL
      )
    ''');

    // Tabella attività
    await db.execute('''
      CREATE TABLE attivita (
        id TEXT PRIMARY KEY,
        obiettivo_id TEXT NOT NULL,
        titolo TEXT NOT NULL,
        descrizione TEXT DEFAULT '',
        priorita TEXT DEFAULT 'media',
        pomodoro_totali INTEGER DEFAULT 1,
        pomodoro_completati INTEGER DEFAULT 0,
        pomodoro_datterino INTEGER DEFAULT 0,
        pomodoro_san_marzano INTEGER DEFAULT 0,
        pomodoro_cuore_di_bue INTEGER DEFAULT 0,
        completata INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (obiettivo_id) REFERENCES obiettivi (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
