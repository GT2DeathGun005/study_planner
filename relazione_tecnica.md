# Relazione Tecnica: Pantone Planner App

## Descrizione dell'app

### Obiettivo dell'applicazione
L'obiettivo principale dell'applicazione è fornire uno strumento completo e centralizzato per la gestione della vita accademica. L'app permette di organizzare i corsi universitari, pianificare e tracciare gli esami, impostare sessioni di studio mirate e monitorare i progressi attraverso statistiche dettagliate.

### Tipologia di utenti a cui è rivolta
L'app è rivolta specificamente agli **studenti universitari** di qualsiasi corso di laurea, che necessitano di uno strumento digitale per organizzare lo studio, rispettare le scadenze e migliorare la propria produttività.

### Problema che l'app intende risolvere
Gli studenti universitari spesso affrontano il problema della frammentazione delle informazioni: date degli esami su un calendario, appunti sui corsi da un'altra parte, e l'utilizzo di diverse app per timer o task manager. L'app risolve questa frammentazione unendo in un'unica piattaforma la gestione amministrativa (corsi e voti), la pianificazione (scadenze e task) e l'esecuzione dello studio (timer Pomodoro).

### Principali scenari d'uso
1. **Pianificazione Iniziale:** All'inizio del semestre, l'utente inserisce i propri corsi (con i relativi CFU e docenti) e fissa le date degli esami previsti.
2. **Organizzazione dello Studio:** Settimanalmente, l'utente crea degli "Obiettivi" (task) associandoli ai vari corsi/esami, stimando il tempo necessario per il completamento.
3. **Sessione di Studio (Esecuzione):** L'utente avvia il timer Pomodoro integrato per focalizzarsi su un task specifico, accumulando "tempo effettivo" di studio registrato automaticamente.
4. **Monitoraggio Progressi:** L'utente controlla la propria "Dashboard Analytics" per verificare la media voti, i crediti acquisiti e l'andamento temporale dei voti degli esami superati, ottenendo un riscontro visivo dei propri risultati.

---

## Requisiti

### Funzionalità implementate
- **Gestione Corsi:** Operazioni CRUD per i corsi, inclusivi di informazioni come docente, semestre, CFU, stato (es. in corso, superato), anno accademico (1-3 o 1-2), tipo di laurea (triennale o magistrale) e lode.
- **Gestione Esami e Scadenze:** CRUD completo, con associazione agli esami di una tipologia (scritto/orale/progetto/altro), priorità, stato, voto finale e peso percentuale (incidenza sul voto del corso).
- **Pianificazione, Obiettivi e Attività:** Creazione di macro-obiettivi strutturati che fungono da contenitori per molteplici sotto-attività (sotto-task), ciascuna con una stima di pomodori e tracciamento del tempo effettivo di studio.
- **Ricerca e Filtri:** Ricerca testuale per i corsi e filtri avanzati per stato/semestre/anno/tipo-laurea. Filtri per stato e priorità per gli obiettivi.
- **Dashboard Analytics:** Visualizzazione di KPI (esami superati, CFU acquisiti, media ponderata distinta per triennale/magistrale, obiettivi raggiunti) e del grafico ad andamento lineare dei voti e della media ponderata nel tempo.

### Funzionalità considerate ma non implementate
- Sincronizzazione in cloud multipiattaforma.
- Notifiche push locali per le scadenze imminenti e avvisi del timer a schermo spento.
- Esportazione/condivisione del libretto universitario (es. in PDF).

### Feature avanzate scelte
1. **Calendario Interattivo (`table_calendar`):** Una vista calendario (mensile e settimanale) con marker per visualizzare rapidamente i giorni con obiettivi pianificati o scadenze esami.
2. **Timer Pomodoro Multiforme:** Un timer integrato con tre varietà di pomodoro italiano (Datterino da 25 min, San Marzano da 50 min, Cuore di Bue da 100 min), animato in modo fluido tramite `CustomPainter`, che gestisce lo studio-pausa e salva automaticamente il tempo registrando la quantità per tipologia di pomodoro nell'attività selezionata.

### Eventuali limitazioni note
- L'app salva i dati esclusivamente in locale tramite database SQLite. Questo significa che i dati non sono sincronizzati su più dispositivi e verrebbero persi in caso di disinstallazione.

---

## Progettazione dell'app

### Struttura generale dell'app
L'applicazione è strutturata secondo un'architettura modulare e a strati: Data Access (SQLite/Repositories), State Management (Providers) e UI (Screens/Widgets). L'interfaccia si basa sui principi del Material Design 3.

### Schermate principali
- **Home/Dashboard (Profilo):** Mostra un riassunto dello stato accademico tramite KPI, un grafico di andamento lineare dei voti conseguiti e le scadenze imminenti.
- **Lista Corsi ed Esami:** Una vista navigabile per esplorare i corsi inseriti, filtrarli e vederne il dettaglio con gli esami collegati.
- **Obiettivi (Task List):** Elenco dei macro-obiettivi pianificati. Facendo tap su un obiettivo, l'utente accede alla schermata di dettaglio del singolo obiettivo (`obiettivo_detail_screen.dart`), da cui può gestire le sotto-attività, controllarne il progresso complessivo e lanciare il timer Pomodoro su di esse.
- **Calendario:** Vista calendario con marker visuali per date pianificate.

### Flusso di navigazione
La navigazione principale avviene tramite una `BottomNavigationBar` onnipresente che permette di muoversi tra Dashboard, Corsi, Obiettivi e Calendario. Dalle liste è possibile navigare, tramite tap, verso le schermate di dettaglio (es. dettagli corso o dettagli obiettivo) e, tramite un Floating Action Button (FAB), verso i form di inserimento/modifica.

### Organizzazione dei dati
I dati sono modellati a livello relazionale:
- L'entità centrale è il **Corso**.
- Un **Esame** è dipendente e appartiene a un Corso (relazione 1:N).
- Un **Obiettivo** rappresenta una macro-pianificazione e può essere facoltativamente collegato a un Corso (relazione N:1).
- Un'**Attività** (sotto-task) appartiene a un determinato Obiettivo (relazione 1:N) e rappresenta l'unità elementare su cui viene eseguito lo studio (tracciando i pomodori completati).

---

## Scelte tecnologiche

### Framework utilizzato
- **Flutter:** Scelto per sviluppare un'applicazione cross-platform (Android, iOS) fluida e performante utilizzando una singola base di codice (linguaggio Dart).

### Librerie principali
- `sqflite`: Per l'interazione con il database relazionale locale.
- `provider`: Per la gestione reattiva dello stato globale e l'iniezione delle dipendenze.
- `table_calendar`: Per la renderizzazione della schermata di calendario complessa.
- `fl_chart`: Per la visualizzazione dei dati statistici tramite grafici accattivanti.

### Motivazione delle scelte effettuate
Il pattern **Provider** è stato preferito ad altre soluzioni (come BLoC o Riverpod) in quanto offre un eccellente compromesso tra facilità di comprensione, pulizia del codice e performance, risultando ideale per un'app di questa scala. L'utilizzo di **SQLite** è stato scelto per garantire il funzionamento completamente offline, senza forzare lo studente a registrare account o richiedere connettività, e per sfruttare la potenza del modello relazionale.

### Modalità di gestione della persistenza
Il ciclo di vita dei dati è gestito dalla classe singleton `DatabaseHelper` che si occupa della creazione e versione del database SQLite al primo avvio. I repository specifici inviano query SQL, convertendo i Map risultanti in oggetti immutabili (modelli Dart).

---

## Implementazione

### Organizzazione del codice
Il progetto segue una struttura di cartelle chiara:
- `/models`: Classi dati immutabili (es. `corso.dart`, `esame.dart`, `obiettivo.dart`, `attivita.dart`) con metodi di serializzazione e copia.
- `/services`: Classi per l'interazione diretta con SQLite (Singleton `DatabaseHelper` e i vari Repositories).
- `/providers`: Logica di business ed estensioni di `ChangeNotifier` (`CorsoProvider`, `EsameProvider`, `ObiettivoProvider`, `AttivitaProvider`).
- `/screens`: Pagine principali raggruppate per feature (es. `/esami`, `/obiettivi`, `/calendario`, `/profilo`).
- `/widgets`: Componenti UI riutilizzabili (come `CorsoCard`, `EsameCard`, `ObiettivoCard`, `AttivitaCard`).

### Componenti/widget principali
- **Card Riutilizzabili:** Uniformano l'aspetto delle liste all'interno delle schermate. `ObiettivoCard` mostra una barra di progresso basata sulle attività completate, mentre `AttivitaCard` consente il completamento rapido o l'avvio del timer.
- **Timer Animato:** `PomodoroTimerWidget` utilizza un `CustomPainter` per disegnare il progresso circolare del tempo in modo fluido, aggiornandosi tramite un `Ticker` sincrono rispetto allo scorrere del tempo.

### Gestione dello stato
Ogni entità dispone del rispettivo `ChangeNotifier` che mantiene lo stato in memoria. I provider si occupano di sincronizzare la memoria con il database SQLite tramite i Repository e chiamare `notifyListeners()` per forzare il refresh della UI. I widget leggono e ascoltano questi stati reattivi tramite `context.watch<T>()`, `context.read<T>()` e `Consumer`.

### Gestione della navigazione
La navigazione è gestita tramite il routing nativo di Flutter (approccio push/pop) per le viste di dettaglio e di form, mentre la navigazione globale tra le sezioni principali avviene tramite la `BottomNavigationBar` in `home_screen.dart`.

### Gestione dei dati persistenti
Le tabelle sono create nel `DatabaseHelper`. Le foreign key garantiscono l'integrità referenziale dei dati:
- La cancellazione di un `Corso` elimina a cascata (`ON DELETE CASCADE`) i relativi `esami`, mentre imposta a `NULL` il riferimento negli `obiettivi` (`ON DELETE SET NULL`) per non perdere lo storico dello studio effettuato.
- La cancellazione di un `Obiettivo` elimina a cascata (`ON DELETE CASCADE`) tutte le sotto-attività collegate.

### Eventuali parti particolarmente significative o complesse
L'integrazione del **Timer Pomodoro Multiforme** con le sotto-attività ha richiesto particolare attenzione:
1. **Gestione del ciclo di vita:** Corretto rilascio del timer all'uscita della schermata per evitare memory leak.
2. **Diversificazione del tempo:** Gestione di tre durate distinte di pomodoro e di pausa, con calcolo automatico dei minuti equivalenti accumulati.
3. **Persistenza sicura:** Al completamento o all'arresto manuale, il timer contatta `AttivitaProvider` per incrementare e salvare nel DB il rispettivo conteggio dei pomodori completati dell'attività target, aggiornando a catena anche lo stato dell'obiettivo macro se tutte le sotto-attività risultano concluse.
