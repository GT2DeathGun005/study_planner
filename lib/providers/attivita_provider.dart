import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/attivita.dart';
import '../services/attivita_repository.dart';
import '../services/obiettivo_repository.dart';

/// Provider per la gestione dello stato delle Attività.
///
/// Gestisce le attività che compongono un obiettivo,
/// il completamento dei pomodori e l'aggiornamento automatico
/// dello stato dell'obiettivo padre.
class AttivitaProvider extends ChangeNotifier {
  final AttivitaRepository _repository = AttivitaRepository();
  final ObiettivoRepository _obiettivoRepository = ObiettivoRepository();
  final Uuid _uuid = const Uuid();

  List<Attivita> _attivita = [];
  List<Attivita> _tutteAttivita = []; // tutte le attività globali
  bool _isLoading = false;
  String? _currentObiettivoId;

  /// Lista attività dell'obiettivo corrente.
  List<Attivita> get attivita => _attivita;

  /// Tutte le attività globali (per statistiche).
  List<Attivita> get tutteAttivita => _tutteAttivita;

  bool get isLoading => _isLoading;

  /// Totale pomodori completati dell'obiettivo corrente.
  int get pomodoroCompletati =>
      _attivita.fold(0, (sum, a) => sum + a.pomodoroCompletati);

  /// Totale pomodori assegnati dell'obiettivo corrente.
  int get pomodoroTotali =>
      _attivita.fold(0, (sum, a) => sum + a.pomodoroTotali);



  // ---------- Statistiche globali ----------

  /// Totale minuti di studio di tutte le attività.
  int get minutiStudioTotali =>
      _tutteAttivita.fold(0, (sum, a) => sum + a.minutiStudio);

  /// Totale pomodori Datterino completati globalmente.
  int get totaleDatterino =>
      _tutteAttivita.fold(0, (sum, a) => sum + a.pomodoroDatterino);

  /// Totale pomodori San Marzano completati globalmente.
  int get totaleSanMarzano =>
      _tutteAttivita.fold(0, (sum, a) => sum + a.pomodoroSanMarzano);

  /// Totale pomodori Cuore di Bue completati globalmente.
  int get totaleCuoreDiBue =>
      _tutteAttivita.fold(0, (sum, a) => sum + a.pomodoroCuoreDiBue);

  /// Conteggio pomodori per un obiettivo specifico (per la card).
  int pomodoroCompletatiPerObiettivo(String obiettivoId) {
    return _tutteAttivita
        .where((a) => a.obiettivoId == obiettivoId)
        .fold(0, (sum, a) => sum + a.pomodoroCompletati);
  }

  /// Conteggio pomodori totali per un obiettivo specifico (per la card).
  int pomodoroTotaliPerObiettivo(String obiettivoId) {
    return _tutteAttivita
        .where((a) => a.obiettivoId == obiettivoId)
        .fold(0, (sum, a) => sum + a.pomodoroTotali);
  }

  /// Carica le attività di un obiettivo.
  Future<void> loadAttivita(String obiettivoId) async {
    _isLoading = true;
    _currentObiettivoId = obiettivoId;
    notifyListeners();

    _attivita = await _repository.getByObiettivoId(obiettivoId);

    _isLoading = false;
    notifyListeners();
  }

  /// Carica tutte le attività globali (per statistiche).
  Future<void> loadTutteAttivita() async {
    _tutteAttivita = await _repository.getAll();
    notifyListeners();
  }

  /// Inserisce una nuova attività.
  Future<void> addAttivita({
    required String obiettivoId,
    required String titolo,
    String descrizione = '',
    int pomodoroTotali = 1,
  }) async {
    final attivita = Attivita(
      id: _uuid.v4(),
      obiettivoId: obiettivoId,
      titolo: titolo,
      descrizione: descrizione,
      pomodoroTotali: pomodoroTotali,
      createdAt: DateTime.now(),
    );

    await _repository.insert(attivita);
    await _refreshAll(obiettivoId);
    await _verificaStatoObiettivo(obiettivoId);
  }

  /// Aggiorna un'attività esistente.
  Future<void> updateAttivita(Attivita attivita) async {
    await _repository.update(attivita);
    await _refreshAll(attivita.obiettivoId);
    await _verificaStatoObiettivo(attivita.obiettivoId);
  }

  /// Elimina un'attività.
  Future<void> deleteAttivita(String id, String obiettivoId) async {
    await _repository.delete(id);
    await _refreshAll(obiettivoId);
    await _verificaStatoObiettivo(obiettivoId);
  }



  /// Toggle completamento di un'attività e verifica stato obiettivo.
  Future<void> toggleCompletata(String id) async {
    final attivita = _attivita.firstWhere((a) => a.id == id);
    // Rimosso il blocco: ora è possibile rimuovere la spunta anche se i pomodori sono stati completati.
    await _repository.toggleCompletata(id, !attivita.completata);
    await _refreshAll(attivita.obiettivoId);
    await _verificaStatoObiettivo(attivita.obiettivoId);
  }

  /// Completa un pomodoro per un'attività.
  /// Se raggiunge il totale, segna automaticamente l'attività come completata.
  Future<void> completaPomodoro(String id, String tipoPomodoro) async {
    final attivita = _attivita.firstWhere((a) => a.id == id);
    await _repository.completaPomodoro(id, tipoPomodoro);
    // Ricarica per avere il contatore aggiornato
    final aggiornata = (await _repository.getByObiettivoId(attivita.obiettivoId))
        .firstWhere((a) => a.id == id);
    // Auto-completamento se i pomodori hanno raggiunto il totale
    if (!aggiornata.completata &&
        aggiornata.pomodoroCompletati >= aggiornata.pomodoroTotali) {
      await _repository.toggleCompletata(id, true);
    }
    await _refreshAll(attivita.obiettivoId);
    await _verificaStatoObiettivo(attivita.obiettivoId);
  }

  /// Ricarica attività dell'obiettivo corrente e globali.
  Future<void> _refreshAll(String obiettivoId) async {
    if (_currentObiettivoId == obiettivoId) {
      _attivita = await _repository.getByObiettivoId(obiettivoId);
    }
    _tutteAttivita = await _repository.getAll();
    notifyListeners();
  }

  /// Verifica se tutte le attività sono completate e aggiorna lo stato.
  Future<void> _verificaStatoObiettivo(String obiettivoId) async {
    final attivitaObiettivo =
        await _repository.getByObiettivoId(obiettivoId);
    final tutteCompletate =
        attivitaObiettivo.isNotEmpty &&
        attivitaObiettivo.every((a) => a.completata);

    final nuovoStato = tutteCompletate ? 'raggiunto' : 'prefissato';
    await _obiettivoRepository.updateStato(obiettivoId, nuovoStato);
  }
}
