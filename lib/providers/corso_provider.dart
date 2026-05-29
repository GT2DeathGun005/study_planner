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
  List<String> _filtroStato = [];
  List<int> _filtroSemestre = [];
  List<String> _filtroTipoLaurea = [];
  List<int> _filtroAnno = [];
  int? _filtroCfuMin;
  int? _filtroCfuMax;
  String _sortBy = 'default';
  bool _sortAscending = true;

  /// Lista corsi filtrata in base a ricerca e filtri attivi.
  List<Corso> get corsi {
    var result = _corsi;
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((c) =>
              c.nome.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_filtroStato.isNotEmpty) {
      result = result.where((c) => _filtroStato.contains(c.stato)).toList();
    }
    if (_filtroSemestre.isNotEmpty) {
      result = result.where((c) => _filtroSemestre.contains(c.semestre)).toList();
    }
    if (_filtroTipoLaurea.isNotEmpty) {
      result =
          result.where((c) => _filtroTipoLaurea.contains(c.tipoLaurea)).toList();
    }
    if (_filtroAnno.isNotEmpty) {
      result = result.where((c) => _filtroAnno.contains(c.anno)).toList();
    }
    if (_filtroCfuMin != null) {
      result = result.where((c) => c.cfu >= _filtroCfuMin!).toList();
    }
    if (_filtroCfuMax != null) {
      result = result.where((c) => c.cfu <= _filtroCfuMax!).toList();
    }
    
    // Applica ordinamento
    if (_sortBy != 'default') {
      result = List.from(result);
      if (_sortBy == 'titolo') {
        result.sort((a, b) => _sortAscending
            ? a.nome.compareTo(b.nome)
            : b.nome.compareTo(a.nome));
      } else if (_sortBy == 'anno_semestre') {
        int compareAnnoSemestre(Corso a, Corso b) {
          final aLaurea = a.tipoLaurea == 'triennale' ? 0 : 1;
          final bLaurea = b.tipoLaurea == 'triennale' ? 0 : 1;
          if (aLaurea != bLaurea) {
            return aLaurea.compareTo(bLaurea);
          }
          if (a.anno != b.anno) {
            return a.anno.compareTo(b.anno);
          }
          return a.semestre.compareTo(b.semestre);
        }
        result.sort((a, b) => _sortAscending
            ? compareAnnoSemestre(a, b)
            : compareAnnoSemestre(b, a));
      } else if (_sortBy == 'stato') {
        const statoOrder = {
          'da_iniziare': 0,
          'in_corso': 1,
          'terminato': 2,
          'da_ripassare': 3,
          'superato': 4,
        };
        int compareStato(Corso a, Corso b) {
          final wA = statoOrder[a.stato] ?? 0;
          final wB = statoOrder[b.stato] ?? 0;
          return wA.compareTo(wB);
        }
        result.sort((a, b) => _sortAscending
            ? compareStato(a, b)
            : compareStato(b, a));
      }
    }
    return result;
  }

  /// Lista completa senza filtri (per dropdown, ecc.).
  List<Corso> get tuttiCorsi => _corsi;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  List<String> get filtroStato => _filtroStato;
  List<int> get filtroSemestre => _filtroSemestre;
  List<String> get filtroTipoLaurea => _filtroTipoLaurea;
  List<int> get filtroAnno => _filtroAnno;
  int? get filtroCfuMin => _filtroCfuMin;
  int? get filtroCfuMax => _filtroCfuMax;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  /// Numero di filtri attivi (esclusa la ricerca).
  int get filtriAttiviCount {
    int count = 0;
    if (_filtroStato.isNotEmpty) count++;
    if (_filtroSemestre.isNotEmpty) count++;
    if (_filtroTipoLaurea.isNotEmpty) count++;
    if (_filtroAnno.isNotEmpty) count++;
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
    bool lode = false,
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
      lode: lode,
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
  void setFiltroStato(List<String> stato) {
    _filtroStato = List.from(stato);
    notifyListeners();
  }

  /// Imposta il filtro per semestre.
  void setFiltroSemestre(List<int> semestre) {
    _filtroSemestre = List.from(semestre);
    notifyListeners();
  }

  /// Imposta il filtro per tipo laurea.
  void setFiltroTipoLaurea(List<String> tipoLaurea) {
    _filtroTipoLaurea = List.from(tipoLaurea);
    // Reset anni non validi per i tipi laurea selezionati
    if (_filtroTipoLaurea.isNotEmpty && _filtroAnno.isNotEmpty) {
      final allAnniValidi = _filtroTipoLaurea.expand((tl) => Corso.anniPerTipo(tl)).toSet();
      _filtroAnno.removeWhere((a) => !allAnniValidi.contains(a));
    }
    notifyListeners();
  }

  /// Imposta il filtro per anno.
  void setFiltroAnno(List<int> anno) {
    _filtroAnno = List.from(anno);
    notifyListeners();
  }

  /// Imposta il filtro per range CFU.
  void setFiltroCfu({int? min, int? max}) {
    _filtroCfuMin = min;
    _filtroCfuMax = max;
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
    _searchQuery = '';
    _filtroStato = [];
    _filtroSemestre = [];
    _filtroTipoLaurea = [];
    _filtroAnno = [];
    _filtroCfuMin = null;
    _filtroCfuMax = null;
    _sortBy = 'default';
    _sortAscending = true;
    notifyListeners();
  }
}
