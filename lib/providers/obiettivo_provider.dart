import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/obiettivo.dart';
import '../services/obiettivo_repository.dart';

/// Provider per la gestione dello stato degli Obiettivi/Task.
///
/// Gestisce la lista task, filtri per completamento e priorità,
/// e l'aggiornamento del tempo dal timer Pomodoro.
class ObiettivoProvider extends ChangeNotifier {
  final ObiettivoRepository _repository = ObiettivoRepository();
  final Uuid _uuid = const Uuid();

  List<Obiettivo> _obiettivi = [];
  bool _isLoading = false;
  bool? _filtroCompletato;
  String? _filtroPriorita;

  /// Lista obiettivi filtrata.
  List<Obiettivo> get obiettivi {
    var result = _obiettivi;
    if (_filtroCompletato != null) {
      result =
          result.where((o) => o.completato == _filtroCompletato).toList();
    }
    if (_filtroPriorita != null) {
      result = result.where((o) => o.priorita == _filtroPriorita).toList();
    }
    return result;
  }

  /// Lista completa senza filtri.
  List<Obiettivo> get tuttiObiettivi => _obiettivi;

  bool get isLoading => _isLoading;
  bool? get filtroCompletato => _filtroCompletato;
  String? get filtroPriorita => _filtroPriorita;

  /// Totale minuti di studio pianificati.
  int get totaleTempoStimato =>
      _obiettivi.fold(0, (sum, o) => sum + o.tempoStimato);

  /// Totale minuti di studio effettuati.
  int get totaleTempoEffettivo =>
      _obiettivi.fold(0, (sum, o) => sum + o.tempoEffettivo);

  /// Numero obiettivi completati.
  int get completati => _obiettivi.where((o) => o.completato).length;

  /// Tempo effettivo per corso (per grafici analytics).
  Map<String, int> get tempoPerCorso {
    final map = <String, int>{};
    for (final o in _obiettivi) {
      if (o.corsoId != null && o.tempoEffettivo > 0) {
        map[o.corsoId!] = (map[o.corsoId!] ?? 0) + o.tempoEffettivo;
      }
    }
    return map;
  }

  /// Carica tutti gli obiettivi dal database.
  Future<void> loadObiettivi() async {
    _isLoading = true;
    notifyListeners();

    _obiettivi = await _repository.getAll();

    _isLoading = false;
    notifyListeners();
  }

  /// Inserisce un nuovo obiettivo.
  Future<void> addObiettivo({
    required String titolo,
    String descrizione = '',
    String? corsoId,
    String? esameId,
    String priorita = 'media',
    int tempoStimato = 0,
    DateTime? dataPianificata,
    DateTime? dataScadenza,
    String note = '',
  }) async {
    final obiettivo = Obiettivo(
      id: _uuid.v4(),
      titolo: titolo,
      descrizione: descrizione,
      corsoId: corsoId,
      esameId: esameId,
      priorita: priorita,
      tempoStimato: tempoStimato,
      dataPianificata: dataPianificata,
      dataScadenza: dataScadenza,
      note: note,
      createdAt: DateTime.now(),
    );

    await _repository.insert(obiettivo);
    await loadObiettivi();
  }

  /// Aggiorna un obiettivo esistente.
  Future<void> updateObiettivo(Obiettivo obiettivo) async {
    await _repository.update(obiettivo);
    await loadObiettivi();
  }

  /// Elimina un obiettivo.
  Future<void> deleteObiettivo(String id) async {
    await _repository.delete(id);
    await loadObiettivi();
  }

  /// Elimina tutti gli obiettivi associati a un corso.
  Future<void> deleteObiettiviByCorso(String corsoId) async {
    final obiettiviCorso =
        _obiettivi.where((o) => o.corsoId == corsoId).toList();
    for (final o in obiettiviCorso) {
      await _repository.delete(o.id);
    }
    await loadObiettivi();
  }

  /// Elimina tutti gli obiettivi associati a un esame.
  Future<void> deleteObiettiviByEsame(String esameId) async {
    final obiettiviEsame =
        _obiettivi.where((o) => o.esameId == esameId).toList();
    for (final o in obiettiviEsame) {
      await _repository.delete(o.id);
    }
    await loadObiettivi();
  }

  /// Toggle completamento di un obiettivo.
  Future<void> toggleCompletato(String id) async {
    final obiettivo = _obiettivi.firstWhere((o) => o.id == id);
    await _repository.toggleCompletato(id, !obiettivo.completato);
    await loadObiettivi();
  }

  /// Aggiorna il tempo effettivo (aggiunta dal Pomodoro).
  Future<void> aggiungiTempo(String id, int minuti) async {
    await _repository.updateTempoEffettivo(id, minuti);
    await loadObiettivi();
  }

  /// Recupera obiettivi pianificati per una data (per il calendario).
  List<Obiettivo> getObiettiviByDate(DateTime date) {
    return _obiettivi.where((o) {
      if (o.dataPianificata == null) return false;
      return o.dataPianificata!.year == date.year &&
          o.dataPianificata!.month == date.month &&
          o.dataPianificata!.day == date.day;
    }).toList();
  }

  /// Imposta il filtro per completamento.
  void setFiltroCompletato(bool? completato) {
    _filtroCompletato = completato;
    notifyListeners();
  }

  /// Imposta il filtro per priorità.
  void setFiltroPriorita(String? priorita) {
    _filtroPriorita = priorita;
    notifyListeners();
  }

  /// Resetta tutti i filtri.
  void resetFiltri() {
    _filtroCompletato = null;
    _filtroPriorita = null;
    notifyListeners();
  }
}
