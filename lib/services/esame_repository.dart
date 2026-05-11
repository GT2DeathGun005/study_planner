import 'package:sqflite/sqflite.dart';
import '../models/esame.dart';
import 'database_helper.dart';

/// Repository per le operazioni CRUD sulla tabella `esami`.
class EsameRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Recupera tutti gli esami, ordinati per data crescente.
  Future<List<Esame>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('esami', orderBy: 'data ASC');
    return maps.map((map) => Esame.fromMap(map)).toList();
  }

  /// Recupera un esame per ID.
  Future<Esame?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('esami', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Esame.fromMap(maps.first);
  }

  /// Recupera gli esami associati a un corso specifico.
  Future<List<Esame>> getByCorsoId(String corsoId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('esami',
        where: 'corso_id = ?', whereArgs: [corsoId], orderBy: 'data ASC');
    return maps.map((map) => Esame.fromMap(map)).toList();
  }

  /// Inserisce un nuovo esame.
  Future<void> insert(Esame esame) async {
    final db = await _dbHelper.database;
    await db.insert('esami', esame.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Aggiorna un esame esistente.
  Future<void> update(Esame esame) async {
    final db = await _dbHelper.database;
    await db.update('esami', esame.toMap(),
        where: 'id = ?', whereArgs: [esame.id]);
  }

  /// Elimina un esame per ID.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('esami', where: 'id = ?', whereArgs: [id]);
  }

  /// Recupera esami programmati futuri, ordinati per data.
  Future<List<Esame>> getUpcoming() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query('esami',
        where: "data >= ? AND stato = 'programmato'",
        whereArgs: [now],
        orderBy: 'data ASC');
    return maps.map((map) => Esame.fromMap(map)).toList();
  }

  /// Recupera esami in un intervallo di date.
  Future<List<Esame>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final maps = await db.query('esami',
        where: 'data >= ? AND data <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'data ASC');
    return maps.map((map) => Esame.fromMap(map)).toList();
  }

  /// Recupera esami completati con voto (superati).
  Future<List<Esame>> getSuperati() async {
    final db = await _dbHelper.database;
    final maps = await db.query('esami',
        where: "stato = 'completato' AND voto IS NOT NULL AND voto >= 18",
        orderBy: 'data DESC');
    return maps.map((map) => Esame.fromMap(map)).toList();
  }
}
