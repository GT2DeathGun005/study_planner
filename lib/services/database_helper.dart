import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton per la gestione del database SQLite.
///
/// Si occupa dell'apertura della connessione, della creazione delle tabelle
/// e delle migrazioni future tramite versioning.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  /// Restituisce l'istanza del database, inizializzandola se necessario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inizializza il database SQLite.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'study_planner.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea le tabelle al primo avvio dell'app.
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
        voto_previsto INTEGER,
        voto_ottenuto INTEGER,
        materiali TEXT DEFAULT '',
        created_at TEXT NOT NULL
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
        note TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (corso_id) REFERENCES corsi (id) ON DELETE CASCADE
      )
    ''');

    // Tabella obiettivi/task
    await db.execute('''
      CREATE TABLE obiettivi (
        id TEXT PRIMARY KEY,
        titolo TEXT NOT NULL,
        descrizione TEXT DEFAULT '',
        corso_id TEXT,
        esame_id TEXT,
        priorita TEXT DEFAULT 'media',
        tempo_stimato INTEGER DEFAULT 0,
        tempo_effettivo INTEGER DEFAULT 0,
        completato INTEGER DEFAULT 0,
        data_pianificata TEXT,
        data_scadenza TEXT,
        note TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (corso_id) REFERENCES corsi (id) ON DELETE SET NULL,
        FOREIGN KEY (esame_id) REFERENCES esami (id) ON DELETE SET NULL
      )
    ''');
  }

  /// Gestisce le migrazioni tra versioni del database.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Riservato per migrazioni future.
  }

  /// Chiude la connessione al database.
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
