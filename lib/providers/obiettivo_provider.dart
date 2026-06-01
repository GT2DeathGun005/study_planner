import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/obiettivo.dart';
import '../services/obiettivo_repository.dart';
import '../services/attivita_repository.dart';

/// Provider per la gestione dello stato degli Obiettivi.
///
/// Gestisce la lista obiettivi, filtri per stato e priorità,
/// e ricerca testuale.
class ObiettivoProvider extends ChangeNotifier {
  final ObiettivoRepository _repository = ObiettivoRepository();
  final AttivitaRepository _attivitaRepository = AttivitaRepository();
  final Uuid _uuid = const Uuid();

  List<Obiettivo> _obiettivi = [];
  bool _isLoading = false;
  List<String> _filtroStato = []; // 'prefissato' o 'raggiunto'
  List<String> _filtroPriorita = [];
  String _searchQuery = '';
  String _sortBy = 'default';
  bool _sortAscending = true;
  Map<String, int> _pomodoriCompletatiMap = {};

  /// Lista obiettivi filtrata.
  List<Obiettivo> get obiettivi {
    var result = _obiettivi;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((o) =>
              o.titolo.toLowerCase().contains(query) ||
              o.descrizione.toLowerCase().contains(query))
          .toList();
    }
    if (_filtroStato.isNotEmpty) {
      result = result.where((o) => _filtroStato.contains(o.stato)).toList();
    }
    if (_filtroPriorita.isNotEmpty) {
      result = result.where((o) => _filtroPriorita.contains(o.priorita)).toList();
    }
    
    // Applica ordinamento
    if (_sortBy != 'default') {
      result = List.from(result);
      if (_sortBy == 'titolo') {
        result.sort((a, b) => _sortAscending
            ? a.titolo.compareTo(b.titolo)
            : b.titolo.compareTo(a.titolo));
      } else if (_sortBy == 'data') {
        int compareData(Obiettivo a, Obiettivo b) {
          if (a.dataPianificata == null && b.dataPianificata == null) return 0;
          if (a.dataPianificata == null) return 1;
          if (b.dataPianificata == null) return -1;
          return a.dataPianificata!.compareTo(b.dataPianificata!);
        }
        result.sort((a, b) => _sortAscending
            ? compareData(a, b)
            : compareData(b, a));
      } else if (_sortBy == 'pomodori') {
        result.sort((a, b) {
          final countA = _pomodoriCompletatiMap[a.id] ?? 0;
          final countB = _pomodoriCompletatiMap[b.id] ?? 0;
          return _sortAscending
              ? countA.compareTo(countB)
              : countB.compareTo(countA);
        });
      }
    }
    return result;
  }

  /// Lista completa senza filtri.
  List<Obiettivo> get tuttiObiettivi => _obiettivi;

  bool get isLoading => _isLoading;
  List<String> get filtroStato => _filtroStato;
  List<String> get filtroPriorita => _filtroPriorita;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  /// Numero obiettivi raggiunti.
  int get raggiunti =>
      _obiettivi.where((o) => o.stato == 'raggiunto').length;

  /// Carica tutti gli obiettivi dal database.
  Future<void> loadObiettivi() async {
    _isLoading = true;
    notifyListeners();

    _obiettivi = await _repository.getAll();
    
    // Carica tutti i pomodori svolti per gli obiettivi
    final tutteAtt = await _attivitaRepository.getAll();
    _pomodoriCompletatiMap = {};
    for (final a in tutteAtt) {
      _pomodoriCompletatiMap[a.obiettivoId] =
          (_pomodoriCompletatiMap[a.obiettivoId] ?? 0) + a.pomodoroCompletati;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Inserisce un nuovo obiettivo.
  Future<void> addObiettivo({
    required String titolo,
    String descrizione = '',
    String? corsoId,
    String priorita = 'media',
    DateTime? dataPianificata,
  }) async {
    final obiettivo = Obiettivo(
      id: _uuid.v4(),
      titolo: titolo,
      descrizione: descrizione,
      corsoId: corsoId,
      priorita: priorita,
      dataPianificata: dataPianificata,
      createdAt: DateTime.now(),
    );

    await _repository.insert(obiettivo);
    await loadObiettivi();
  }

  /// Aggiorna un obiettivo esistente.
  /// Dopo il salvataggio, ri-verifica lo stato in base alle attività
  /// per non sovrascrivere la transizione automatica prefissato/raggiunto.
  Future<void> updateObiettivo(Obiettivo obiettivo) async {
    // Verifica lo stato basato sulle attività prima di salvare
    final attivitaObiettivo =
        await _attivitaRepository.getByObiettivoId(obiettivo.id);
    final tutteCompletate = attivitaObiettivo.isNotEmpty &&
        attivitaObiettivo.every((a) => a.completata);
    final statoCorretto = tutteCompletate ? 'raggiunto' : 'prefissato';
    await _repository.update(obiettivo.copyWith(stato: statoCorretto));
    await loadObiettivi();
  }

  /// Elimina un obiettivo e le sue attività.
  Future<void> deleteObiettivo(String id) async {
    await _attivitaRepository.deleteByObiettivoId(id);
    await _repository.delete(id);
    await loadObiettivi();
  }

  /// Elimina tutti gli obiettivi associati a un corso.
  Future<void> deleteObiettiviByCorso(String corsoId) async {
    final obiettiviCorso =
        _obiettivi.where((o) => o.corsoId == corsoId).toList();
    for (final o in obiettiviCorso) {
      await _attivitaRepository.deleteByObiettivoId(o.id);
      await _repository.delete(o.id);
    }
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

  /// Imposta il filtro per stato.
  void setFiltroStato(List<String> stato) {
    _filtroStato = List.from(stato);
    notifyListeners();
  }

  /// Imposta il filtro per priorità.
  void setFiltroPriorita(List<String> priorita) {
    _filtroPriorita = List.from(priorita);
    notifyListeners();
  }

  /// Imposta la query di ricerca.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Imposta l'ordinamento.
  void setOrdinamento(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    notifyListeners();
  }

  /// Resetta tutti i filtri.
  void resetFiltri() {
    _filtroStato = [];
    _filtroPriorita = [];
    _searchQuery = '';
    _sortBy = 'default';
    _sortAscending = true;
    notifyListeners();
  }
}
