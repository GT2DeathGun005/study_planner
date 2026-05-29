import 'package:sqflite/sqflite.dart';
import '../models/attivita.dart';
import 'database_helper.dart';

/// Repository per le operazioni CRUD sulla tabella `attivita`.
class AttivitaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Recupera tutte le attività di un obiettivo.
  Future<List<Attivita>> getByObiettivoId(String obiettivoId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('attivita',
        where: 'obiettivo_id = ?',
        whereArgs: [obiettivoId],
        orderBy: 'created_at ASC');
    return maps.map((map) => Attivita.fromMap(map)).toList();
  }

  /// Recupera tutte le attività (per statistiche globali).
  Future<List<Attivita>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('attivita', orderBy: 'created_at ASC');
    return maps.map((map) => Attivita.fromMap(map)).toList();
  }

  /// Inserisce una nuova attività.
  Future<void> insert(Attivita attivita) async {
    final db = await _dbHelper.database;
    await db.insert('attivita', attivita.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Aggiorna un'attività esistente.
  Future<void> update(Attivita attivita) async {
    final db = await _dbHelper.database;
    await db.update('attivita', attivita.toMap(),
        where: 'id = ?', whereArgs: [attivita.id]);
  }

  /// Elimina un'attività per ID.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('attivita', where: 'id = ?', whereArgs: [id]);
  }

  /// Elimina tutte le attività di un obiettivo.
  Future<void> deleteByObiettivoId(String obiettivoId) async {
    final db = await _dbHelper.database;
    await db.delete('attivita',
        where: 'obiettivo_id = ?', whereArgs: [obiettivoId]);
  }

  /// Toggle completamento di un'attività.
  Future<void> toggleCompletata(String id, bool completata) async {
    final db = await _dbHelper.database;
    await db.update('attivita', {'completata': completata ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Incrementa il contatore pomodori completati e il contatore per tipo.
  Future<void> completaPomodoro(String id, String tipoPomodoro) async {
    final db = await _dbHelper.database;
    String colonnaTipo;
    switch (tipoPomodoro) {
      case 'datterino':
        colonnaTipo = 'pomodoro_datterino';
        break;
      case 'san_marzano':
        colonnaTipo = 'pomodoro_san_marzano';
        break;
      case 'cuore_di_bue':
        colonnaTipo = 'pomodoro_cuore_di_bue';
        break;
      default:
        colonnaTipo = 'pomodoro_datterino';
    }
    await db.rawUpdate(
      'UPDATE attivita SET pomodoro_completati = pomodoro_completati + 1, '
      '$colonnaTipo = $colonnaTipo + 1 WHERE id = ?',
      [id],
    );
  }

  /// Conta il totale pomodori completati per un obiettivo.
  Future<int> countPomodoroCompletati(String obiettivoId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(pomodoro_completati), 0) as total '
      'FROM attivita WHERE obiettivo_id = ?',
      [obiettivoId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Conta il totale pomodori assegnati per un obiettivo.
  Future<int> countPomodoroTotali(String obiettivoId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(pomodoro_totali), 0) as total '
      'FROM attivita WHERE obiettivo_id = ?',
      [obiettivoId],
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
