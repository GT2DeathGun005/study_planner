# Relazione Tecnica: Study Planner & Exam Tracker App

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
4. **Monitoraggio Progressi:** L'utente controlla la propria "Dashboard Analytics" per verificare la media voti, i crediti acquisiti e la distribuzione del tempo di studio, ottenendo un riscontro visivo dei propri risultati.

---

## Requisiti

### Funzionalità implementate
- **Gestione Corsi:** Operazioni CRUD per i corsi, inclusivi di informazioni come docente, semestre, CFU, stato (es. in corso, superato) e voto.
- **Gestione Esami e Scadenze:** CRUD completo, con associazione agli esami di una tipologia (scritto/orale), priorità e stato.
- **Pianificazione e Obiettivi (Task):** Creazione di task con tracciamento di tempo stimato ed effettivo.
- **Ricerca e Filtri:** Ricerca testuale e filtri per stato (sui corsi) e per completamento/priorità (sugli obiettivi).
- **Dashboard Analytics:** Visualizzazione di KPI (esami superati, media, task completati) e grafici relativi al tempo di studio.

### Funzionalità considerate ma non implementate
- Sincronizzazione in cloud multipiattaforma.
- Notifiche push locali per le scadenze imminenti e avvisi del timer a schermo spento.
- Esportazione/condivisione del libretto universitario (es. in PDF).

### Feature avanzate scelte
1. **Calendario Interattivo (`table_calendar`):** Una vista calendario (mensile e settimanale) con marker per visualizzare rapidamente i giorni con task o scadenze.
2. **Timer Pomodoro:** Un timer integrato, con animazioni custom tramite `CustomPainter`, che gestisce il ciclo studio-pausa (25/5 minuti) e salva automaticamente il tempo speso nei relativi obiettivi.

### Eventuali limitazioni note
- L'app salva i dati esclusivamente in locale tramite database SQLite. Questo significa che i dati non sono sincronizzati su più dispositivi e verrebbero persi in caso di disinstallazione, a meno di non implementare backup esterni.

---

## Progettazione dell'app

### Struttura generale dell'app
L'applicazione è strutturata secondo un'architettura modulare e a strati: Data Access (SQLite/Repositories), State Management (Providers) e UI (Screens/Widgets). L'interfaccia si basa sui principi del Material Design 3.

### Schermate principali
- **Home/Dashboard (Profilo):** Mostra un riassunto dello stato accademico tramite KPI, grafici a torta e scadenze imminenti.
- **Lista Corsi ed Esami:** Una vista navigabile per esplorare i corsi inseriti, filtrarli e vederne il dettaglio con gli esami collegati.
- **Obiettivi (Task List):** Elenco delle cose da fare e delle ore di studio programmate, con accesso rapido al timer.
- **Calendario:** Vista calendario con marker visuali.

### Flusso di navigazione
La navigazione principale avviene tramite una `BottomNavigationBar` onnipresente che permette di muoversi tra Dashboard, Corsi, Obiettivi e Calendario. Dalle liste (Corsi/Obiettivi) è possibile navigare, tramite tap, verso le schermate di dettaglio e, tramite un Floating Action Button (FAB), verso i form di inserimento/modifica.

### Organizzazione dei dati
I dati sono modellati a livello relazionale:
- L'entità centrale è il **Corso**.
- Un **Esame** è dipendente e appartiene a un Corso (relazione 1:N).
- Un **Obiettivo** può essere generico, oppure collegato opzionalmente a un Corso e/o a un Esame specifico.

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
- `/models`: Classi dati immutabili con metodi di serializzazione `toMap()`/`fromMap()`.
- `/services`: Classi per l'interazione diretta con SQLite (Repositories).
- `/providers`: Logica di business ed estensioni di `ChangeNotifier`.
- `/screens`: Pagine principali raggruppate per feature (es. /esami, /obiettivi, /calendario).
- `/widgets`: Componenti UI riutilizzabili.

### Componenti/widget principali
- **Card Riutilizzabili:** `CorsoCard`, `EsameCard`, `ObiettivoCard` uniformano l'aspetto delle liste nell'app.
- **Timer Animato:** `PomodoroTimerWidget` utilizza un `CustomPainter` per disegnare il progresso circolare del tempo in modo fluido, aggiornandosi tramite `Ticker`.

### Gestione dello stato
Ogni entità (Corsi, Esami, Obiettivi) dispone di un proprio `ChangeNotifier` (`CorsoProvider`, `EsameProvider`, ecc.). Questi provider leggono i dati dal DB tramite i Repository, mantengono le liste in memoria per una UI reattiva, e chiamano `notifyListeners()` ogni volta che avviene una modifica (creazione, aggiornamento, eliminazione).
I widget utilizzano `context.watch<T>()` o il widget `Consumer` per reagire unicamente ai cambiamenti necessari.

### Gestione della navigazione
La navigazione è gestita primariamente dal router standard di Flutter, con un approccio basato sul push/pop di schermate figlie partendo dalla shell contenente la BottomNavigationBar.

### Gestione dei dati persistenti
Le operazioni sul DB fanno ampio uso di vincoli relazionali. Ad esempio, l'eliminazione di un Corso esegue automaticamente un `ON DELETE CASCADE` sui relativi Esami, mentre imposta a `NULL` il riferimento negli Obiettivi (`ON DELETE SET NULL`), per evitare che lo studente perda il track del tempo studiato anche se un corso viene rimosso.

### Eventuali parti particolarmente significative o complesse
L'integrazione del **Timer Pomodoro** ha richiesto particolare attenzione. A differenza di form statici, il timer necessita di:
1. Una corretta gestione del lifecycle per evitare memory leaks (gestione dei `Timer` di Dart).
2. Un salvataggio sincronizzato nel database alla fine della sessione di studio o quando il timer viene messo in pausa/interrotto, in modo da incrementare correttamente il campo `tempoEffettivo` del task senza causare colli di bottiglia nel database.
