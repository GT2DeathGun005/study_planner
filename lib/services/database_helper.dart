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
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // Tabella obiettivi (v4: semplificata)
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

    // Tabella attività (v4: nuova)
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


  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {

      await db.execute(
          "ALTER TABLE corsi ADD COLUMN tipo_laurea TEXT DEFAULT 'triennale'");
      await db.execute(
          'ALTER TABLE corsi ADD COLUMN anno INTEGER DEFAULT 1');


      await db.execute(
          'ALTER TABLE esami ADD COLUMN peso_percentuale INTEGER DEFAULT 100');


      await db.execute(
          "UPDATE esami SET stato = 'programmato' WHERE stato = 'annullato'");
    }
    if (oldVersion < 3) {
      // Rinomina stato 'completato' -> 'terminato' nella tabella corsi
      await db.execute(
          "UPDATE corsi SET stato = 'terminato' WHERE stato = 'completato'");
    }
    if (oldVersion < 4) {
      // Aggiungere colonna stato alla tabella obiettivi
      await db.execute(
          "ALTER TABLE obiettivi ADD COLUMN stato TEXT DEFAULT 'prefissato'");

      // Migrare obiettivi completati -> stato raggiunto
      await db.execute(
          "UPDATE obiettivi SET stato = 'raggiunto' WHERE completato = 1");

      // Creare tabella attività
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
    if (oldVersion < 5) {
      await db.execute(
          "ALTER TABLE corsi ADD COLUMN lode INTEGER DEFAULT 0");
    }
  }


  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
