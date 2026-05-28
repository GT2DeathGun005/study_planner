/// Modello dati per un Corso universitario.
///
/// Rappresenta un insegnamento con informazioni come nome, docente,
/// semestre, CFU, stato, tipo di laurea e anno accademico.
class Corso {
  final String id;
  final String nome;
  final String docente;
  final int semestre;
  final int cfu;
  final String descrizione;
  final String stato; // da_iniziare, in_corso, terminato, da_ripassare, superato
  final String tipoLaurea; // triennale, magistrale
  final int anno; // triennale: 1-3, magistrale: 1-2
  final int? votoPrevisto;
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
    this.tipoLaurea = 'triennale',
    this.anno = 1,
    this.votoPrevisto,
    this.materiali = '',
    required this.createdAt,
  });

  /// Stati disponibili per un corso.
  static const List<String> statiDisponibili = [
    'da_iniziare',
    'in_corso',
    'terminato',
    'da_ripassare',
    'superato',
  ];

  /// Tipi di laurea disponibili.
  static const List<String> tipiLaureaDisponibili = [
    'triennale',
    'magistrale',
  ];

  /// Label leggibile per lo stato.
  static String statoLabel(String stato) {
    switch (stato) {
      case 'da_iniziare':
        return 'Da iniziare';
      case 'in_corso':
        return 'In corso';
      case 'terminato':
        return 'Terminato';
      case 'da_ripassare':
        return 'Da ripassare';
      case 'superato':
        return 'Superato';
      default:
        return stato;
    }
  }

  /// Label leggibile per il tipo di laurea.
  static String tipoLaureaLabel(String tipo) {
    switch (tipo) {
      case 'triennale':
        return 'Triennale';
      case 'magistrale':
        return 'Magistrale';
      default:
        return tipo;
    }
  }

  /// Anni disponibili in base al tipo di laurea.
  static List<int> anniPerTipo(String tipoLaurea) {
    switch (tipoLaurea) {
      case 'triennale':
        return [1, 2, 3];
      case 'magistrale':
        return [1, 2];
      default:
        return [1, 2, 3];
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
      'tipo_laurea': tipoLaurea,
      'anno': anno,
      'voto_previsto': votoPrevisto,
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
      tipoLaurea: (map['tipo_laurea'] as String?) ?? 'triennale',
      anno: (map['anno'] as int?) ?? 1,
      votoPrevisto: map['voto_previsto'] as int?,
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
    String? tipoLaurea,
    int? anno,
    int? votoPrevisto,
    bool clearVotoPrevisto = false,
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
      tipoLaurea: tipoLaurea ?? this.tipoLaurea,
      anno: anno ?? this.anno,
      votoPrevisto: clearVotoPrevisto ? null : (votoPrevisto ?? this.votoPrevisto),
      materiali: materiali ?? this.materiali,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
