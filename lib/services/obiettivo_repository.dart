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

  /// Recupera gli obiettivi associati a un esame.
  Future<List<Obiettivo>> getByEsameId(String esameId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('obiettivi',
        where: 'esame_id = ?',
        whereArgs: [esameId],
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

  /// Aggiorna solo il tempo effettivo di un obiettivo (usato dal Pomodoro).
  Future<void> updateTempoEffettivo(String id, int minuti) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE obiettivi SET tempo_effettivo = tempo_effettivo + ? WHERE id = ?',
      [minuti, id],
    );
  }

  /// Segna un obiettivo come completato/non completato.
  Future<void> toggleCompletato(String id, bool completato) async {
    final db = await _dbHelper.database;
    await db.update('obiettivi', {'completato': completato ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Recupera tutti gli obiettivi con scadenza entro i prossimi N giorni.
  Future<List<Obiettivo>> getScadenzeImminenti({int giorni = 7}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final limit =
        DateTime.now().add(Duration(days: giorni)).toIso8601String();
    final maps = await db.query('obiettivi',
        where: 'data_scadenza >= ? AND data_scadenza <= ? AND completato = 0',
        whereArgs: [now, limit],
        orderBy: 'data_scadenza ASC');
    return maps.map((map) => Obiettivo.fromMap(map)).toList();
  }
}
