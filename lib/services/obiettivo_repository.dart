import 'package:sqflite/sqflite.dart';
import '../models/obiettivo.dart';
import 'database_helper.dart';

/// Repository per le operazioni CRUD sulla tabella `obiettivi`.
class ObiettivoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Recupera tutti gli obiettivi, ordinati per data di creazione decrescente.
  Future<List<Obiettivo>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('obiettivi', orderBy: 'created_at DESC');
    return maps.map((map) => Obiettivo.fromMap(map)).toList();
  }

  /// Recupera un obiettivo per ID.
  Future<Obiettivo?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps =
        await db.query('obiettivi', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Obiettivo.fromMap(maps.first);
  }

  /// Recupera gli obiettivi associati a un corso.
  Future<List<Obiettivo>> getByCorsoId(String corsoId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('obiettivi',
        where: 'corso_id = ?',
        whereArgs: [corsoId],
        orderBy: 'created_at DESC');
    return maps.map((map) => Obiettivo.fromMap(map)).toList();
  }

  /// Recupera gli obiettivi pianificati per una data specifica.
  Future<List<Obiettivo>> getByDate(DateTime date) async {
    final db = await _dbHelper.database;
    // Confronta solo la data (senza ora)
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await db.query('obiettivi',
        where: "data_pianificata LIKE ?",
        whereArgs: ['$dateStr%'],
        orderBy: 'priorita ASC');
    return maps.map((map) => Obiettivo.fromMap(map)).toList();
  }

  /// Inserisce un nuovo obiettivo.
  Future<void> insert(Obiettivo obiettivo) async {
    final db = await _dbHelper.database;
    await db.insert('obiettivi', obiettivo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Aggiorna un obiettivo esistente.
  Future<void> update(Obiettivo obiettivo) async {
    final db = await _dbHelper.database;
    await db.update('obiettivi', obiettivo.toMap(),
        where: 'id = ?', whereArgs: [obiettivo.id]);
  }

  /// Elimina un obiettivo per ID.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('obiettivi', where: 'id = ?', whereArgs: [id]);
  }

  /// Aggiorna lo stato di un obiettivo.
  Future<void> updateStato(String id, String stato) async {
    final db = await _dbHelper.database;
    await db.update('obiettivi', {'stato': stato},
        where: 'id = ?', whereArgs: [id]);
  }
}
