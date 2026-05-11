# Study Planner & Exam Tracker App

App Flutter per studenti universitari che permette di gestire corsi, esami, sessioni di studio, attività/obiettivi e monitorare i propri progressi accademici.

## Indice

- [Descrizione](#descrizione)
- [Prerequisiti](#prerequisiti)
- [Installazione ed Esecuzione](#installazione-ed-esecuzione)
- [Struttura del Progetto](#struttura-del-progetto)
- [Architettura](#architettura)
- [Modelli Dati](#modelli-dati)
- [Funzionalità](#funzionalità)
- [Feature Avanzate](#feature-avanzate)
- [Librerie Utilizzate](#librerie-utilizzate)

---

## Descrizione

L'app si rivolge a studenti universitari che necessitano di uno strumento per:
- Organizzare i corsi e le informazioni relative (docente, CFU, semestre, stato, voti)
- Pianificare e tracciare esami e scadenze accademiche
- Creare obiettivi di studio e attività, associandoli a corsi o esami
- Visualizzare il calendario con le attività pianificate
- Monitorare i progressi tramite statistiche e grafici
- Utilizzare un timer Pomodoro per sessioni di studio focalizzate

## Prerequisiti

- **Flutter SDK** ≥ 3.7.0
- **Dart SDK** ≥ 3.7.0
- Emulatore Android/iOS o dispositivo fisico collegato

> **Nota**: non è richiesto alcun backend remoto o database esterno. L'app utilizza SQLite come database locale, creato automaticamente al primo avvio.

## Installazione ed Esecuzione

```bash
# 1. Clona il repository
git clone <url-del-repository>
cd study_planner

# 2. Installa le dipendenze
flutter pub get

# 3. Esegui l'app
flutter run
```

Su Windows, se si riceve un avviso sui symlink, attivare la Modalità Sviluppatore:
```
start ms-settings:developers
```

## Struttura del Progetto

```
lib/
├── main.dart                          # Entry point, Provider setup, tema Material 3
├── models/
│   ├── corso.dart                     # Modello Corso
│   ├── esame.dart                     # Modello Esame/Scadenza
│   └── obiettivo.dart                 # Modello Obiettivo/Task
├── services/
│   ├── database_helper.dart           # Singleton SQLite (creazione tabelle, connessione)
│   ├── corso_repository.dart          # CRUD corsi
│   ├── esame_repository.dart          # CRUD esami
│   └── obiettivo_repository.dart      # CRUD obiettivi
├── providers/
│   ├── corso_provider.dart            # ChangeNotifier per corsi
│   ├── esame_provider.dart            # ChangeNotifier per esami
│   └── obiettivo_provider.dart        # ChangeNotifier per obiettivi
├── screens/
│   ├── home_screen.dart               # BottomNavigationBar (4 sezioni)
│   ├── esami/
│   │   ├── esami_screen.dart          # Lista corsi con ricerca e filtri
│   │   ├── corso_form_screen.dart     # Crea/modifica corso
│   │   ├── corso_detail_screen.dart   # Dettaglio corso + esami associati
│   │   └── esame_form_screen.dart     # Crea/modifica esame
│   ├── obiettivi/
│   │   ├── obiettivi_screen.dart      # Lista obiettivi con filtri
│   │   ├── obiettivo_form_screen.dart # Crea/modifica obiettivo
│   │   └── pomodoro_screen.dart       # Timer Pomodoro
│   ├── calendario/
│   │   └── calendario_screen.dart     # Calendario mensile/settimanale
│   └── profilo/
│       └── profilo_screen.dart        # Dashboard analytics
└── widgets/
    ├── corso_card.dart                # Card corso riutilizzabile
    ├── esame_card.dart                # Card esame riutilizzabile
    ├── obiettivo_card.dart            # Card obiettivo con checkbox
    ├── stat_card.dart                 # Card KPI per dashboard
    └── pomodoro_timer_widget.dart     # Timer circolare animato
```

## Architettura

### Pattern di gestione dello stato: Provider

L'app utilizza il pattern **Provider** (`ChangeNotifier` + `MultiProvider`) per la gestione dello stato:

```
UI (Screens/Widgets)
    ↕ Consumer/context.watch/context.read
Providers (ChangeNotifier)
    ↕ async calls
Repositories (Data Access Layer)
    ↕ SQL queries
DatabaseHelper (SQLite singleton)
```

Ogni entità (Corso, Esame, Obiettivo) ha:
1. **Model** - Data class immutabile con `toMap()`, `fromMap()`, `copyWith()`
2. **Repository** - Operazioni CRUD e query specifiche verso SQLite
3. **Provider** - ChangeNotifier che mantiene lo stato in memoria e notifica la UI

### Persistenza: SQLite

Il database SQLite viene creato automaticamente al primo avvio dell'app tramite il `DatabaseHelper` singleton. Le tabelle hanno relazioni tramite foreign key:

- `corsi` → tabella principale
- `esami` → FK verso `corsi` (ON DELETE CASCADE)
- `obiettivi` → FK opzionali verso `corsi` e `esami` (ON DELETE SET NULL)

## Modelli Dati

### Corso
| Campo | Tipo | Descrizione |
|-------|------|-------------|
| id | String (UUID) | Chiave primaria |
| nome | String | Nome del corso |
| docente | String | Docente |
| semestre | int | 1 o 2 |
| cfu | int | Crediti formativi |
| descrizione | String | Note/descrizione |
| stato | String | da_iniziare, in_corso, completato, da_ripassare, superato |
| votoPrevisto | int? | Voto previsto/desiderato |
| votoOttenuto | int? | Voto finale ottenuto |
| materiali | String | Riferimenti e materiali |

### Esame
| Campo | Tipo | Descrizione |
|-------|------|-------------|
| id | String (UUID) | Chiave primaria |
| titolo | String | Titolo esame/scadenza |
| corsoId | String | FK verso Corso |
| data | DateTime | Data esame |
| tipologia | String | scritto, orale, progetto, consegna, altro |
| priorita | String | alta, media, bassa |
| stato | String | programmato, completato, annullato |
| voto | int? | Voto ottenuto |
| note | String | Note aggiuntive |

### Obiettivo
| Campo | Tipo | Descrizione |
|-------|------|-------------|
| id | String (UUID) | Chiave primaria |
| titolo | String | Nome del task |
| descrizione | String | Descrizione |
| corsoId | String? | FK opzionale verso Corso |
| esameId | String? | FK opzionale verso Esame |
| priorita | String | alta, media, bassa |
| tempoStimato | int | Minuti pianificati |
| tempoEffettivo | int | Minuti accumulati (Pomodoro) |
| completato | bool | Stato completamento |
| dataPianificata | DateTime? | Data nel calendario |
| dataScadenza | DateTime? | Scadenza |

## Funzionalità

### Gestione Corsi
- Visualizzazione elenco con ricerca per nome
- Filtri per stato (chip orizzontali)
- Creazione, modifica, eliminazione
- Dettaglio corso con esami associati

### Gestione Esami e Scadenze
- CRUD completo con associazione a un corso
- Tipologia (scritto/orale/progetto/consegna)
- Priorità e stato
- Voto opzionale, calcolo esami superati

### Pianificazione e Obiettivi
- Task con associazione a corso e/o esame
- Tempo stimato e tempo effettivo (tracciato dal Pomodoro)
- Data pianificata e scadenza
- Checkbox completamento inline
- Filtri per completamento e priorità

### Ricerca e Filtri
- Ricerca corsi per nome (testo libero)
- Filtro corsi per stato
- Filtro obiettivi per completamento e priorità
- Scadenze imminenti (prossimi 7 giorni)

### Dashboard Analytics
- KPI: corsi totali, esami superati, media voti, task completati
- Barra progresso ore studio effettive vs pianificate
- Grafico a torta distribuzione tempo per corso
- Lista scadenze imminenti

## Feature Avanzate

### 1. Calendario (table_calendar)
- Vista mensile e settimanale (toggle)
- Marker colorati per task e scadenze esami
- Tap su giorno → lista attività del giorno
- FAB per creare task pre-impostati sulla data selezionata

### 2. Timer Pomodoro
- Ciclo 25 min studio → 5 min pausa
- Progresso circolare animato (CustomPainter)
- Controlli play/pause/reset/skip
- Salvataggio automatico del tempo studiato nel database
- Conteggio sessioni e minuti totali nella sessione

## Librerie Utilizzate

| Libreria | Versione | Scopo |
|----------|----------|-------|
| sqflite | ^2.4.2 | Database SQLite locale |
| path_provider | ^2.1.5 | Path del database su filesystem |
| path | ^1.9.1 | Utility per percorsi file |
| provider | ^6.1.2 | State management (ChangeNotifier) |
| table_calendar | ^3.2.0 | Widget calendario mensile/settimanale |
| fl_chart | ^0.70.2 | Grafici (PieChart) per analytics |
| intl | ^0.20.2 | Formattazione date in italiano |
| uuid | ^4.5.1 | Generazione ID univoci |

---

**Sviluppato con Flutter e ❤️**
