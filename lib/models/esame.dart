/// Modello dati per un Esame o scadenza accademica.
///
/// Rappresenta un esame, appello, consegna o altra scadenza
/// associata a un corso specifico. Include un peso percentuale
/// che indica quanto l'esame incide sul voto finale del corso.
class Esame {
  final String id;
  final String titolo;
  final String corsoId;
  final DateTime data;
  final String tipologia; // scritto, orale, progetto, consegna, altro
  final String priorita; // alta, media, bassa
  final String stato; // programmato, completato
  final int? voto;
  final int pesoPercentuale; // 0-100, peso sul voto finale del corso
  final String note;
  final DateTime createdAt;

  const Esame({
    required this.id,
    required this.titolo,
    required this.corsoId,
    required this.data,
    this.tipologia = 'scritto',
    this.priorita = 'media',
    this.stato = 'programmato',
    this.voto,
    this.pesoPercentuale = 100,
    this.note = '',
    required this.createdAt,
  });

  /// Tipologie disponibili per un esame.
  static const List<String> tipologieDisponibili = [
    'scritto',
    'orale',
    'progetto',
    'altro',
  ];

  /// Priorità disponibili.
  static const List<String> prioritaDisponibili = [
    'alta',
    'media',
    'bassa',
  ];

  /// Stati disponibili per un esame.
  static const List<String> statiDisponibili = [
    'programmato',
    'completato',
  ];

  /// Label per la tipologia.
  static String tipologiaLabel(String tipo) {
    switch (tipo) {
      case 'scritto':
        return 'Scritto';
      case 'orale':
        return 'Orale';
      case 'progetto':
        return 'Progetto';
      case 'altro':
        return 'Altro';
      default:
        return tipo;
    }
  }

  /// Label per la priorità.
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

  /// Label per lo stato.
  static String statoLabel(String s) {
    switch (s) {
      case 'programmato':
        return 'Programmato';
      case 'completato':
        return 'Completato';
      default:
        return s;
    }
  }

  /// Indica se l'esame è superato (completato con voto >= 18).
  bool get superato => stato == 'completato' && voto != null && voto! >= 18;

  /// Calcola i punti ponderati: (voto * pesoPercentuale / 100).
  /// Es: voto 30 con peso 60% = 18 punti.
  double get puntiPonderati {
    if (voto == null) return 0;
    return voto! * pesoPercentuale / 100;
  }

  /// Converte il modello in una Map per SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titolo': titolo,
      'corso_id': corsoId,
      'data': data.toIso8601String(),
      'tipologia': tipologia,
      'priorita': priorita,
      'stato': stato,
      'voto': voto,
      'peso_percentuale': pesoPercentuale,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea un Esame da una Map SQLite.
  factory Esame.fromMap(Map<String, dynamic> map) {
    return Esame(
      id: map['id'] as String,
      titolo: map['titolo'] as String,
      corsoId: map['corso_id'] as String,
      data: DateTime.parse(map['data'] as String),
      tipologia: (map['tipologia'] as String?) ?? 'scritto',
      priorita: (map['priorita'] as String?) ?? 'media',
      stato: (map['stato'] as String?) ?? 'programmato',
      voto: map['voto'] as int?,
      pesoPercentuale: (map['peso_percentuale'] as int?) ?? 100,
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Crea una copia con campi opzionalmente modificati.
  Esame copyWith({
    String? id,
    String? titolo,
    String? corsoId,
    DateTime? data,
    String? tipologia,
    String? priorita,
    String? stato,
    int? voto,
    bool clearVoto = false,
    int? pesoPercentuale,
    String? note,
    DateTime? createdAt,
  }) {
    return Esame(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      corsoId: corsoId ?? this.corsoId,
      data: data ?? this.data,
      tipologia: tipologia ?? this.tipologia,
      priorita: priorita ?? this.priorita,
      stato: stato ?? this.stato,
      voto: clearVoto ? null : (voto ?? this.voto),
      pesoPercentuale: pesoPercentuale ?? this.pesoPercentuale,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
