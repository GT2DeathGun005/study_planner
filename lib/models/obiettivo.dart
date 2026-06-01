/// Modello dati per un Obiettivo di studio.
///
/// Rappresenta un obiettivo macro che può contenere più attività.
/// Lo stato passa a 'raggiunto' quando tutte le attività sono completate.
class Obiettivo {
  final String id;
  final String titolo;
  final String descrizione;
  final String? corsoId;
  final String priorita; // alta, media, bassa
  final String stato; // prefissato, raggiunto
  final DateTime? dataPianificata;
  final DateTime createdAt;

  const Obiettivo({
    required this.id,
    required this.titolo,
    this.descrizione = '',
    this.corsoId,
    this.priorita = 'media',
    this.stato = 'prefissato',
    this.dataPianificata,
    required this.createdAt,
  });

  /// Stati disponibili per un obiettivo.
  static const List<String> statiDisponibili = ['prefissato', 'raggiunto'];

  /// Label per lo stato.
  static String statoLabel(String s) {
    switch (s) {
      case 'prefissato':
        return 'Prefissato';
      case 'raggiunto':
        return 'Raggiunto';
      default:
        return s;
    }
  }

  /// Priorità disponibili.
  static const List<String> prioritaDisponibili = [
    'alta',
    'media',
    'bassa',
  ];

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

  /// Formatta i minuti in ore e minuti leggibili (es. "2h 30m").
  static String formatMinuti(int minuti) {
    if (minuti <= 0) return '0m';
    final ore = minuti ~/ 60;
    final min = minuti % 60;
    if (ore > 0 && min > 0) return '${ore}h ${min}m';
    if (ore > 0) return '${ore}h';
    return '${min}m';
  }

  /// Converte il modello in una Map per SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titolo': titolo,
      'descrizione': descrizione,
      'corso_id': corsoId,
      'priorita': priorita,
      'stato': stato,
      'data_pianificata': dataPianificata?.toIso8601String(),
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
      priorita: (map['priorita'] as String?) ?? 'media',
      stato: (map['stato'] as String?) ?? 'prefissato',
      dataPianificata: map['data_pianificata'] != null
          ? DateTime.parse(map['data_pianificata'] as String)
          : null,
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
    String? priorita,
    String? stato,
    DateTime? dataPianificata,
    bool clearDataPianificata = false,
    DateTime? createdAt,
  }) {
    return Obiettivo(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      descrizione: descrizione ?? this.descrizione,
      corsoId: clearCorsoId ? null : (corsoId ?? this.corsoId),
      priorita: priorita ?? this.priorita,
      stato: stato ?? this.stato,
      dataPianificata: clearDataPianificata
          ? null
          : (dataPianificata ?? this.dataPianificata),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
