# Pantone Planner App

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
│   ├── attivita.dart                  # Modello Attività
│   ├── corso.dart                     # Modello Corso
│   ├── esame.dart                     # Modello Esame
│   └── obiettivo.dart                 # Modello Obiettivo macro
├── services/
│   ├── attivita_repository.dart       # CRUD attività
│   ├── database_helper.dart           # Singleton SQLite (creazione tabelle, connessione)
│   ├── corso_repository.dart          # CRUD corsi
│   ├── esame_repository.dart          # CRUD esami
│   └── obiettivo_repository.dart      # CRUD obiettivi
├── providers/
│   ├── attivita_provider.dart         # ChangeNotifier per attività
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
│   │   ├── obiettivo_detail_screen.dart # Dettaglio obiettivo + lista attività
│   │   ├── obiettivo_form_screen.dart # Crea/modifica obiettivo
│   │   ├── attivita_detail_screen.dart # Dettaglio attività
│   │   ├── attivita_form_screen.dart  # Crea/modifica attività
│   │   └── pomodoro_screen.dart       # Timer Pomodoro
│   ├── calendario/
│   │   └── calendario_screen.dart     # Calendario mensile/settimanale
│   └── profilo/
│       └── profilo_screen.dart        # Dashboard analytics
└── widgets/
    ├── attivita_card.dart             # Card attività riutilizzabile
    ├── corso_card.dart                # Card corso riutilizzabile
    ├── esame_card.dart                # Card esame riutilizzabile
    ├── obiettivo_card.dart            # Card obiettivo con progresso
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
| semestre | int | Semestre accademico (1 o 2) |
| anno | int | Anno accademico (1-3 triennale, 1-2 magistrale) |
| tipoLaurea | String | triennale, magistrale |
| cfu | int | Crediti formativi |
| descrizione | String | Note/descrizione |
| stato | String | da_iniziare, in_corso, terminato, da_ripassare, superato |
| votoPrevisto | int? | Voto previsto/desiderato |
| lode | bool | Indica se è stata conseguita la lode |
| materiali | String | Riferimenti e materiali |

### Esame
| Campo | Tipo | Descrizione |
|-------|------|-------------|
| id | String (UUID) | Chiave primaria |
| titolo | String | Titolo dell'esame o dell'appello |
| corsoId | String | FK verso Corso |
| data | DateTime | Data della prova |
| tipologia | String | scritto, orale, progetto, altro |
| priorita | String | alta, media, bassa |
| stato | String | programmato, completato |
| voto | int? | Voto finale conseguito (18-30) |
| pesoPercentuale | int | Incidenza sul voto del corso (0-100%) |
| note | String | Note aggiuntive |

### Obiettivo (Macro-obiettivo)
| Campo | Tipo | Descrizione |
|-------|------|-------------|
| id | String (UUID) | Chiave primaria |
| titolo | String | Titolo del macro-obiettivo |
| descrizione | String | Descrizione |
| corsoId | String? | FK opzionale verso Corso |
| priorita | String | alta, media, bassa |
| stato | String | prefissato, raggiunto (automatico se tutte le attività sono completate) |
| dataPianificata | DateTime? | Data pianificata per l'obiettivo |

### Attività (Sotto-task)
| Campo | Tipo | Descrizione |
|-------|------|-------------|
| id | String (UUID) | Chiave primaria |
| obiettivoId | String | FK verso Obiettivo |
| titolo | String | Titolo del sotto-task |
| descrizione | String | Descrizione dettagliata |
| pomodoroTotali | int | Pomodori totali assegnati/stimati |
| pomodoroCompletati| int | Somma dei pomodori completati |
| pomodoroDatterino | int | Pomodori da 25 min completati |
| pomodoroSanMarzano| int | Pomodori da 50 min completati |
| pomodoroCuoreDiBue| int | Pomodori da 100 min completati |
| completata | bool | Stato di completamento indipendente |

## Funzionalità

### Gestione Corsi
- Visualizzazione elenco con ricerca per nome
- Filtri per stato, anno accademico e tipo di laurea (triennale/magistrale)
- Creazione, modifica, eliminazione
- Dettaglio corso con esami associati e statistiche sul progresso
- Gestione della lode per esami del corso superati

### Gestione Esami e Scadenze
- CRUD completo con associazione a un corso specifico
- Tipologia (scritto/orale/progetto/altro)
- Peso percentuale per l'incidenza sul voto finale del corso
- Priorità e stato
- Voto finale, calcolo dei punti ponderati e degli esami superati

### Pianificazione, Obiettivi e Attività
- Macro-obiettivi con associazione opzionale a un corso
- Sotto-attività specifiche per ciascun macro-obiettivo
- Tracciamento della stima del tempo (pomodori totali) e del tempo di studio effettivo
- Checkbox di completamento indipendente per ogni singola attività
- Passaggio automatico dell'obiettivo allo stato "Raggiunto" al completamento di tutte le attività collegate

### Ricerca e Filtri
- Ricerca corsi per nome (testo libero)
- Filtro corsi per stato, semestre, tipo laurea e anno accademico
- Filtro obiettivi per stato (prefissato/raggiunto) e priorità
- Scadenze imminenti (prossimi 7 giorni) rilevate automaticamente in base agli esami

### Dashboard Analytics
- KPI: corsi totali inseriti, CFU acquisiti, media ponderata (triennale e magistrale), obiettivi raggiunti
- Monitoraggio delle ore di studio totali effettuate rispetto a quelle pianificate
- Grafico ad andamento temporale dei voti degli esami superati
- Lista delle scadenze e degli esami imminenti per un facile tracciamento

## Feature Avanzate

### 1. Calendario (table_calendar)
- Vista mensile e settimanale (toggle)
- Marker colorati per task e scadenze esami
- Tap su giorno → lista attività del giorno
- FAB per creare task pre-impostati sulla data selezionata

### 2. Timer Pomodoro
- Tre tipologie di pomodori configurabili ispirate alle varietà di pomodoro italiano:
  - **Datterino**: 25 min studio → 5 min pausa (breve)
  - **San Marzano**: 50 min studio → 10 min pausa
  - **Cuore di Bue**: 100 min studio → 20 min pausa (lunga)
- Progresso circolare animato e reattivo (CustomPainter)
- Controlli completi: play/pause/reset/skip/stop
- Salvataggio automatico del tempo studiato e del tipo di pomodoro nel database locale alla fine o alla sospensione della sessione
- Visualizzazione del resoconto del tempo e del numero di pomodori completati per ciascun task

## Librerie Utilizzate

| Libreria | Versione | Scopo |
|----------|----------|-------|
| sqflite | ^2.4.2 | Database SQLite locale |
| path_provider | ^2.1.5 | Path del database su filesystem |
| path | ^1.9.1 | Utility per percorsi file |
| provider | ^6.1.2 | State management (ChangeNotifier) |
| table_calendar | ^3.2.0 | Widget calendario mensile/settimanale |
| fl_chart | ^0.70.2 | Grafico ad andamento lineare (LineChart) per i voti degli esami superati |
| intl | ^0.20.2 | Formattazione date in italiano |
| uuid | ^4.5.1 | Generazione ID univoci |

---

**Sviluppato con Flutter e ❤️**
