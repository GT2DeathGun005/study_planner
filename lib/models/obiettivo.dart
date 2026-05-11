/// Modello dati per un Obiettivo o Task di studio.
///
/// Rappresenta un'attività pianificata: sessione di studio, ripasso,
/// esercitazione, consegna, ecc. Può essere associata a un corso e/o esame.
class Obiettivo {
  final String id;
  final String titolo;
  final String descrizione;
  final String? corsoId;
  final String? esameId;
  final String priorita; // alta, media, bassa
  final int tempoStimato; // minuti
  final int tempoEffettivo; // minuti accumulati (Pomodoro)
  final bool completato;
  final DateTime? dataPianificata;
  final DateTime? dataScadenza;
  final String note;
  final DateTime createdAt;

  const Obiettivo({
    required this.id,
    required this.titolo,
    this.descrizione = '',
    this.corsoId,
    this.esameId,
    this.priorita = 'media',
    this.tempoStimato = 0,
    this.tempoEffettivo = 0,
    this.completato = false,
    this.dataPianificata,
    this.dataScadenza,
    this.note = '',
    required this.createdAt,
  });

  /// Priorità disponibili.
  static const List<String> prioritaDisponibili = [
    'alta',
    'media',
    'bassa',
  ];

  /// Label leggibile per la priorità.
  static String prioritaLabel(String p) {
    switch (p) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Media';
      case 'bassa':
        return 'Bassa';
      default:
        return p;
    }
  }

  /// Formatta i minuti in ore e minuti leggibili (es. "2h 30m").
  static String formatMinuti(int minuti) {
    if (minuti <= 0) return '0m';
    final ore = minuti ~/ 60;
    final min = minuti % 60;
    if (ore > 0 && min > 0) return '${ore}h ${min}m';
    if (ore > 0) return '${ore}h';
    return '${min}m';
  }

  /// Percentuale di completamento basata sul tempo.
  double get progressoTempo {
    if (tempoStimato <= 0) return 0.0;
    return (tempoEffettivo / tempoStimato).clamp(0.0, 1.0);
  }

  /// Converte il modello in una Map per SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titolo': titolo,
      'descrizione': descrizione,
      'corso_id': corsoId,
      'esame_id': esameId,
      'priorita': priorita,
      'tempo_stimato': tempoStimato,
      'tempo_effettivo': tempoEffettivo,
      'completato': completato ? 1 : 0,
      'data_pianificata': dataPianificata?.toIso8601String(),
      'data_scadenza': dataScadenza?.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea un Obiettivo da una Map SQLite.
  factory Obiettivo.fromMap(Map<String, dynamic> map) {
    return Obiettivo(
      id: map['id'] as String,
      titolo: map['titolo'] as String,
      descrizione: (map['descrizione'] as String?) ?? '',
      corsoId: map['corso_id'] as String?,
      esameId: map['esame_id'] as String?,
      priorita: (map['priorita'] as String?) ?? 'media',
      tempoStimato: (map['tempo_stimato'] as int?) ?? 0,
      tempoEffettivo: (map['tempo_effettivo'] as int?) ?? 0,
      completato: (map['completato'] as int?) == 1,
      dataPianificata: map['data_pianificata'] != null
          ? DateTime.parse(map['data_pianificata'] as String)
          : null,
      dataScadenza: map['data_scadenza'] != null
          ? DateTime.parse(map['data_scadenza'] as String)
          : null,
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Crea una copia con campi opzionalmente modificati.
  Obiettivo copyWith({
    String? id,
    String? titolo,
    String? descrizione,
    String? corsoId,
    bool clearCorsoId = false,
    String? esameId,
    bool clearEsameId = false,
    String? priorita,
    int? tempoStimato,
    int? tempoEffettivo,
    bool? completato,
    DateTime? dataPianificata,
    bool clearDataPianificata = false,
    DateTime? dataScadenza,
    bool clearDataScadenza = false,
    String? note,
    DateTime? createdAt,
  }) {
    return Obiettivo(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      descrizione: descrizione ?? this.descrizione,
      corsoId: clearCorsoId ? null : (corsoId ?? this.corsoId),
      esameId: clearEsameId ? null : (esameId ?? this.esameId),
      priorita: priorita ?? this.priorita,
      tempoStimato: tempoStimato ?? this.tempoStimato,
      tempoEffettivo: tempoEffettivo ?? this.tempoEffettivo,
      completato: completato ?? this.completato,
      dataPianificata: clearDataPianificata
          ? null
          : (dataPianificata ?? this.dataPianificata),
      dataScadenza:
          clearDataScadenza ? null : (dataScadenza ?? this.dataScadenza),
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
