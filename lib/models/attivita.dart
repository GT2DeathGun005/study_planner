/// Modello dati per un'Attività che compone un Obiettivo.
///
/// Ogni attività ha un titolo, una descrizione, una priorità ereditata
/// dall'obiettivo, un numero di pomodori assegnati e completati,
/// e un flag di completamento indipendente dai pomodori.
class Attivita {
  final String id;
  final String obiettivoId;
  final String titolo;
  final String descrizione;
  final int pomodoroTotali;
  final int pomodoroCompletati;
  final int pomodoroDatterino; // completati tipo Datterino (25min)
  final int pomodoroSanMarzano; // completati tipo San Marzano (50min)
  final int pomodoroCuoreDiBue; // completati tipo Cuore di Bue (100min)
  final bool completata;
  final DateTime createdAt;

  const Attivita({
    required this.id,
    required this.obiettivoId,
    required this.titolo,
    this.descrizione = '',
    this.pomodoroTotali = 1,
    this.pomodoroCompletati = 0,
    this.pomodoroDatterino = 0,
    this.pomodoroSanMarzano = 0,
    this.pomodoroCuoreDiBue = 0,
    this.completata = false,
    required this.createdAt,
  });

  /// Minuti totali di studio effettuati per questa attività.
  int get minutiStudio =>
      pomodoroDatterino * 25 +
      pomodoroSanMarzano * 50 +
      pomodoroCuoreDiBue * 100;

  /// Converte il modello in una Map per SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'obiettivo_id': obiettivoId,
      'titolo': titolo,
      'descrizione': descrizione,
      'pomodoro_totali': pomodoroTotali,
      'pomodoro_completati': pomodoroCompletati,
      'pomodoro_datterino': pomodoroDatterino,
      'pomodoro_san_marzano': pomodoroSanMarzano,
      'pomodoro_cuore_di_bue': pomodoroCuoreDiBue,
      'completata': completata ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea un'Attività da una Map SQLite.
  factory Attivita.fromMap(Map<String, dynamic> map) {
    return Attivita(
      id: map['id'] as String,
      obiettivoId: map['obiettivo_id'] as String,
      titolo: map['titolo'] as String,
      descrizione: (map['descrizione'] as String?) ?? '',
      pomodoroTotali: (map['pomodoro_totali'] as int?) ?? 1,
      pomodoroCompletati: (map['pomodoro_completati'] as int?) ?? 0,
      pomodoroDatterino: (map['pomodoro_datterino'] as int?) ?? 0,
      pomodoroSanMarzano: (map['pomodoro_san_marzano'] as int?) ?? 0,
      pomodoroCuoreDiBue: (map['pomodoro_cuore_di_bue'] as int?) ?? 0,
      completata: (map['completata'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Crea una copia con campi opzionalmente modificati.
  Attivita copyWith({
    String? id,
    String? obiettivoId,
    String? titolo,
    String? descrizione,
    int? pomodoroTotali,
    int? pomodoroCompletati,
    int? pomodoroDatterino,
    int? pomodoroSanMarzano,
    int? pomodoroCuoreDiBue,
    bool? completata,
    DateTime? createdAt,
  }) {
    return Attivita(
      id: id ?? this.id,
      obiettivoId: obiettivoId ?? this.obiettivoId,
      titolo: titolo ?? this.titolo,
      descrizione: descrizione ?? this.descrizione,
      pomodoroTotali: pomodoroTotali ?? this.pomodoroTotali,
      pomodoroCompletati: pomodoroCompletati ?? this.pomodoroCompletati,
      pomodoroDatterino: pomodoroDatterino ?? this.pomodoroDatterino,
      pomodoroSanMarzano: pomodoroSanMarzano ?? this.pomodoroSanMarzano,
      pomodoroCuoreDiBue: pomodoroCuoreDiBue ?? this.pomodoroCuoreDiBue,
      completata: completata ?? this.completata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
