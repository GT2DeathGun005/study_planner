import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/esame.dart';
import '../services/esame_repository.dart';

/// Provider per la gestione dello stato degli Esami.
///
/// Mantiene una copia locale degli esami e offre filtri per data, corso e stato.
/// Fornisce anche il calcolo del voto ponderato per corso.
class EsameProvider extends ChangeNotifier {
  final EsameRepository _repository = EsameRepository();
  final Uuid _uuid = const Uuid();

  List<Esame> _esami = [];
  bool _isLoading = false;

  List<Esame> get esami => _esami;
  bool get isLoading => _isLoading;

  /// Esami programmati futuri ordinati per data.
  List<Esame> get esamiProgrammati =>
      _esami.where((e) => e.stato == 'programmato').toList()
        ..sort((a, b) => a.data.compareTo(b.data));

  /// Esami superati.
  List<Esame> get esamiSuperati => _esami.where((e) => e.superato).toList();

  /// Esami imminenti (prossimi 7 giorni, non completati).
  List<Esame> get scadenzeImminenti {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));
    return _esami
        .where((e) =>
            e.stato == 'programmato' &&
            e.data.isAfter(now) &&
            e.data.isBefore(limit))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
  }


  /// Calcola il voto ponderato di un corso basato sui suoi esami completati.
  /// Il voto ponderato è la somma dei punti ponderati: Σ(voto × pesoPercentuale / 100).
  double calcolaVotoCorso(String corsoId) {
    final esamiCorso = _esami
        .where((e) => e.corsoId == corsoId && e.stato == 'completato' && e.voto != null)
        .toList();
    if (esamiCorso.isEmpty) return 0;
    return esamiCorso.fold<double>(0, (sum, e) => sum + e.puntiPonderati);
  }

  /// Restituisce la percentuale totale già assegnata per un corso.
  /// Esclude l'esame con [excludeEsameId] per la modifica.
  double getPercentualeTotale(String corsoId, {String? excludeEsameId}) {
    return _esami
        .where((e) =>
            e.corsoId == corsoId &&
            (excludeEsameId == null || e.id != excludeEsameId))
        .fold<double>(0, (sum, e) => sum + e.pesoPercentuale);
  }

  /// Restituisce la percentuale disponibile per un nuovo esame di un corso.
  /// Esclude l'esame con [excludeEsameId] per la modifica.
  double getPercentualeDisponibile(String corsoId,
      {String? excludeEsameId}) {
    final usata = getPercentualeTotale(corsoId, excludeEsameId: excludeEsameId);
    return (100 - usata).clamp(0, 100);
  }

  /// Restituisce gli esami di un corso specifico.
  List<Esame> getEsamiCorso(String corsoId) {
    return _esami.where((e) => e.corsoId == corsoId).toList();
  }

  /// Carica tutti gli esami dal database.
  Future<void> loadEsami() async {
    _isLoading = true;
    notifyListeners();

    _esami = await _repository.getAll();

    _isLoading = false;
    notifyListeners();
  }


  /// Inserisce un nuovo esame.
  Future<void> addEsame({
    required String titolo,
    required String corsoId,
    required DateTime data,
    String tipologia = 'scritto',
    String priorita = 'media',
    String stato = 'programmato',
    int? voto,
    int pesoPercentuale = 100,
    String note = '',
  }) async {
    final esame = Esame(
      id: _uuid.v4(),
      titolo: titolo,
      corsoId: corsoId,
      data: data,
      tipologia: tipologia,
      priorita: priorita,
      stato: stato,
      voto: voto,
      pesoPercentuale: pesoPercentuale,
      note: note,
      createdAt: DateTime.now(),
    );

    await _repository.insert(esame);
    await loadEsami();
  }

  /// Aggiorna un esame esistente.
  Future<void> updateEsame(Esame esame) async {
    await _repository.update(esame);
    await loadEsami();
  }

  /// Elimina un esame.
  Future<void> deleteEsame(String id) async {
    await _repository.delete(id);
    await loadEsami();
  }

  /// Restituisce esami per un intervallo di date per il calendario.
  List<Esame> getEsamiByDate(DateTime date) {
    return _esami.where((e) {
      return e.data.year == date.year &&
          e.data.month == date.month &&
          e.data.day == date.day;
    }).toList();
  }
}
