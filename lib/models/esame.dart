/// Modello dati per un Esame o scadenza accademica.
///
/// Rappresenta un esame, appello, consegna o altra scadenza
/// associata a un corso specifico.
class Esame {
  final String id;
  final String titolo;
  final String corsoId;
  final DateTime data;
  final String tipologia; // scritto, orale, progetto, consegna, altro
  final String priorita; // alta, media, bassa
  final String stato; // programmato, completato, annullato
  final int? voto;
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
    this.note = '',
    required this.createdAt,
  });

  /// Tipologie disponibili per un esame.
  static const List<String> tipologieDisponibili = [
    'scritto',
    'orale',
    'progetto',
    'consegna',
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
    'annullato',
  ];

  /// Label leggibile per la tipologia.
  static String tipologiaLabel(String tipo) {
    switch (tipo) {
      case 'scritto':
        return 'Scritto';
      case 'orale':
        return 'Orale';
      case 'progetto':
        return 'Progetto';
      case 'consegna':
        return 'Consegna';
      case 'altro':
        return 'Altro';
      default:
        return tipo;
    }
  }

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

  /// Label leggibile per lo stato.
  static String statoLabel(String s) {
    switch (s) {
      case 'programmato':
        return 'Programmato';
      case 'completato':
        return 'Completato';
      case 'annullato':
        return 'Annullato';
      default:
        return s;
    }
  }

  /// Indica se l'esame è superato (completato con voto >= 18).
  bool get superato => stato == 'completato' && voto != null && voto! >= 18;

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
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
