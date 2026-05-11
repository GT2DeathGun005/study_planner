import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/esame.dart';
import '../services/esame_repository.dart';

/// Provider per la gestione dello stato degli Esami.
///
/// Mantiene la cache degli esami e offre filtri per data, corso e stato.
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

  /// Esami completati (superati).
  List<Esame> get esamiSuperati => _esami.where((e) => e.superato).toList();

  /// Scadenze imminenti (prossimi 7 giorni, non completati).
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

  /// Media dei voti degli esami superati.
  double get mediaVoti {
    final superati = esamiSuperati;
    if (superati.isEmpty) return 0;
    final somma = superati.fold<int>(0, (sum, e) => sum + (e.voto ?? 0));
    return somma / superati.length;
  }

  /// Carica tutti gli esami dal database.
  Future<void> loadEsami() async {
    _isLoading = true;
    notifyListeners();

    _esami = await _repository.getAll();

    _isLoading = false;
    notifyListeners();
  }

  /// Recupera esami per un corso specifico.
  Future<List<Esame>> getEsamiByCorso(String corsoId) async {
    return await _repository.getByCorsoId(corsoId);
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

  /// Restituisce esami per un intervallo di date (per il calendario).
  List<Esame> getEsamiByDate(DateTime date) {
    return _esami.where((e) {
      return e.data.year == date.year &&
          e.data.month == date.month &&
          e.data.day == date.day;
    }).toList();
  }
}
