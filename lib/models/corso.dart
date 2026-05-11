/// Modello dati per un Corso universitario.
///
/// Rappresenta un insegnamento con informazioni come nome, docente,
/// semestre, CFU, stato e voti.
class Corso {
  final String id;
  final String nome;
  final String docente;
  final int semestre;
  final int cfu;
  final String descrizione;
  final String stato; // da_iniziare, in_corso, completato, da_ripassare, superato
  final int? votoPrevisto;
  final int? votoOttenuto;
  final String materiali;
  final DateTime createdAt;

  const Corso({
    required this.id,
    required this.nome,
    required this.docente,
    required this.semestre,
    required this.cfu,
    this.descrizione = '',
    this.stato = 'da_iniziare',
    this.votoPrevisto,
    this.votoOttenuto,
    this.materiali = '',
    required this.createdAt,
  });

  /// Stati disponibili per un corso.
  static const List<String> statiDisponibili = [
    'da_iniziare',
    'in_corso',
    'completato',
    'da_ripassare',
    'superato',
  ];

  /// Label leggibile per lo stato.
  static String statoLabel(String stato) {
    switch (stato) {
      case 'da_iniziare':
        return 'Da iniziare';
      case 'in_corso':
        return 'In corso';
      case 'completato':
        return 'Completato';
      case 'da_ripassare':
        return 'Da ripassare';
      case 'superato':
        return 'Superato';
      default:
        return stato;
    }
  }

  /// Converte il modello in una Map per SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'docente': docente,
      'semestre': semestre,
      'cfu': cfu,
      'descrizione': descrizione,
      'stato': stato,
      'voto_previsto': votoPrevisto,
      'voto_ottenuto': votoOttenuto,
      'materiali': materiali,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea un Corso da una Map SQLite.
  factory Corso.fromMap(Map<String, dynamic> map) {
    return Corso(
      id: map['id'] as String,
      nome: map['nome'] as String,
      docente: map['docente'] as String,
      semestre: map['semestre'] as int,
      cfu: map['cfu'] as int,
      descrizione: (map['descrizione'] as String?) ?? '',
      stato: (map['stato'] as String?) ?? 'da_iniziare',
      votoPrevisto: map['voto_previsto'] as int?,
      votoOttenuto: map['voto_ottenuto'] as int?,
      materiali: (map['materiali'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Crea una copia con campi opzionalmente modificati.
  Corso copyWith({
    String? id,
    String? nome,
    String? docente,
    int? semestre,
    int? cfu,
    String? descrizione,
    String? stato,
    int? votoPrevisto,
    bool clearVotoPrevisto = false,
    int? votoOttenuto,
    bool clearVotoOttenuto = false,
    String? materiali,
    DateTime? createdAt,
  }) {
    return Corso(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      docente: docente ?? this.docente,
      semestre: semestre ?? this.semestre,
      cfu: cfu ?? this.cfu,
      descrizione: descrizione ?? this.descrizione,
      stato: stato ?? this.stato,
      votoPrevisto: clearVotoPrevisto ? null : (votoPrevisto ?? this.votoPrevisto),
      votoOttenuto: clearVotoOttenuto ? null : (votoOttenuto ?? this.votoOttenuto),
      materiali: materiali ?? this.materiali,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
