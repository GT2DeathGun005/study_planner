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

  /// Lista corsi filtrata in base a ricerca e stato.
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
    return result;
  }

  /// Lista completa senza filtri (per dropdown, ecc.).
  List<Corso> get tuttiCorsi => _corsi;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filtroStato => _filtroStato;

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
    int? votoPrevisto,
    int? votoOttenuto,
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
      votoPrevisto: votoPrevisto,
      votoOttenuto: votoOttenuto,
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

  /// Resetta tutti i filtri.
  void resetFiltri() {
    _searchQuery = '';
    _filtroStato = null;
    notifyListeners();
  }
}
