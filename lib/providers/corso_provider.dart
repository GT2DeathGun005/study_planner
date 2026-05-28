import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/corso.dart';
import '../services/corso_repository.dart';

/// Provider per la gestione dello stato dei Corsi.
///
/// Mantiene una cache locale della lista corsi, gestisce filtri e ricerca,
/// e notifica i listener ad ogni cambiamento.
class CorsoProvider extends ChangeNotifier {
  final CorsoRepository _repository = CorsoRepository();
  final Uuid _uuid = const Uuid();

  List<Corso> _corsi = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _filtroStato;
  int? _filtroSemestre;
  String? _filtroTipoLaurea;
  int? _filtroAnno;
  int? _filtroCfuMin;
  int? _filtroCfuMax;

  /// Lista corsi filtrata in base a ricerca e filtri attivi.
  List<Corso> get corsi {
    var result = _corsi;
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((c) =>
              c.nome.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_filtroStato != null) {
      result = result.where((c) => c.stato == _filtroStato).toList();
    }
    if (_filtroSemestre != null) {
      result = result.where((c) => c.semestre == _filtroSemestre).toList();
    }
    if (_filtroTipoLaurea != null) {
      result =
          result.where((c) => c.tipoLaurea == _filtroTipoLaurea).toList();
    }
    if (_filtroAnno != null) {
      result = result.where((c) => c.anno == _filtroAnno).toList();
    }
    if (_filtroCfuMin != null) {
      result = result.where((c) => c.cfu >= _filtroCfuMin!).toList();
    }
    if (_filtroCfuMax != null) {
      result = result.where((c) => c.cfu <= _filtroCfuMax!).toList();
    }
    return result;
  }

  /// Lista completa senza filtri (per dropdown, ecc.).
  List<Corso> get tuttiCorsi => _corsi;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filtroStato => _filtroStato;
  int? get filtroSemestre => _filtroSemestre;
  String? get filtroTipoLaurea => _filtroTipoLaurea;
  int? get filtroAnno => _filtroAnno;
  int? get filtroCfuMin => _filtroCfuMin;
  int? get filtroCfuMax => _filtroCfuMax;

  /// Numero di filtri attivi (esclusa la ricerca).
  int get filtriAttiviCount {
    int count = 0;
    if (_filtroStato != null) count++;
    if (_filtroSemestre != null) count++;
    if (_filtroTipoLaurea != null) count++;
    if (_filtroAnno != null) count++;
    if (_filtroCfuMin != null || _filtroCfuMax != null) count++;
    return count;
  }

  /// Carica tutti i corsi dal database.
  Future<void> loadCorsi() async {
    _isLoading = true;
    notifyListeners();

    _corsi = await _repository.getAll();

    _isLoading = false;
    notifyListeners();
  }

  /// Inserisce un nuovo corso.
  Future<void> addCorso({
    required String nome,
    required String docente,
    required int semestre,
    required int cfu,
    String descrizione = '',
    String stato = 'da_iniziare',
    String tipoLaurea = 'triennale',
    int anno = 1,
    int? votoPrevisto,
    String materiali = '',
  }) async {
    final corso = Corso(
      id: _uuid.v4(),
      nome: nome,
      docente: docente,
      semestre: semestre,
      cfu: cfu,
      descrizione: descrizione,
      stato: stato,
      tipoLaurea: tipoLaurea,
      anno: anno,
      votoPrevisto: votoPrevisto,
      materiali: materiali,
      createdAt: DateTime.now(),
    );

    await _repository.insert(corso);
    await loadCorsi();
  }

  /// Aggiorna un corso esistente.
  Future<void> updateCorso(Corso corso) async {
    await _repository.update(corso);
    await loadCorsi();
  }

  /// Elimina un corso.
  Future<void> deleteCorso(String id) async {
    await _repository.delete(id);
    await loadCorsi();
  }

  /// Restituisce un corso per ID.
  Corso? getCorsoById(String id) {
    try {
      return _corsi.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Imposta la query di ricerca.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Imposta il filtro per stato.
  void setFiltroStato(String? stato) {
    _filtroStato = stato;
    notifyListeners();
  }

  /// Imposta il filtro per semestre.
  void setFiltroSemestre(int? semestre) {
    _filtroSemestre = semestre;
    notifyListeners();
  }

  /// Imposta il filtro per tipo laurea.
  void setFiltroTipoLaurea(String? tipoLaurea) {
    _filtroTipoLaurea = tipoLaurea;
    // Reset anno se il tipo laurea cambia
    if (tipoLaurea != null && _filtroAnno != null) {
      final anniValidi = Corso.anniPerTipo(tipoLaurea);
      if (!anniValidi.contains(_filtroAnno)) {
        _filtroAnno = null;
      }
    }
    notifyListeners();
  }

  /// Imposta il filtro per anno.
  void setFiltroAnno(int? anno) {
    _filtroAnno = anno;
    notifyListeners();
  }

  /// Imposta il filtro per range CFU.
  void setFiltroCfu({int? min, int? max}) {
    _filtroCfuMin = min;
    _filtroCfuMax = max;
    notifyListeners();
  }

  /// Resetta tutti i filtri.
  void resetFiltri() {
    _searchQuery = '';
    _filtroStato = null;
    _filtroSemestre = null;
    _filtroTipoLaurea = null;
    _filtroAnno = null;
    _filtroCfuMin = null;
    _filtroCfuMax = null;
    notifyListeners();
  }
}
