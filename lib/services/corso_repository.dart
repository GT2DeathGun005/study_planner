import 'package:sqflite/sqflite.dart';
import '../models/corso.dart';
import 'database_helper.dart';

/// Repository per le operazioni CRUD sulla tabella `corsi`.
class CorsoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Recupera tutti i corsi, ordinati per data di creazione decrescente.
  Future<List<Corso>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('corsi', orderBy: 'created_at DESC');
    return maps.map((map) => Corso.fromMap(map)).toList();
  }

  /// Recupera un corso per ID.
  Future<Corso?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('corsi', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Corso.fromMap(maps.first);
  }

  /// Inserisce un nuovo corso.
  Future<void> insert(Corso corso) async {
    final db = await _dbHelper.database;
    await db.insert('corsi', corso.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Aggiorna un corso esistente.
  Future<void> update(Corso corso) async {
    final db = await _dbHelper.database;
    await db.update('corsi', corso.toMap(),
        where: 'id = ?', whereArgs: [corso.id]);
  }

  /// Elimina un corso per ID.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('corsi', where: 'id = ?', whereArgs: [id]);
  }

  /// Filtra i corsi per stato.
  Future<List<Corso>> getByStato(String stato) async {
    final db = await _dbHelper.database;
    final maps = await db.query('corsi',
        where: 'stato = ?', whereArgs: [stato], orderBy: 'nome ASC');
    return maps.map((map) => Corso.fromMap(map)).toList();
  }

  /// Cerca corsi per nome (ricerca parziale, case-insensitive).
  Future<List<Corso>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query('corsi',
        where: 'nome LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'nome ASC');
    return maps.map((map) => Corso.fromMap(map)).toList();
  }
}
