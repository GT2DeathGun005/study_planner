import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/attivita.dart';
import '../../providers/attivita_provider.dart';
import '../../widgets/pomodoro_timer_widget.dart';

/// Tipologie di Pomodoro disponibili.
enum TipoPomodoro {
  datterino(
    label: '🍅 Datterino',
    workMinutes: 25,
    breakMinutes: 5,
    key: 'datterino',
  ),
  sanMarzano(
    label: '🍅 San Marzano',
    workMinutes: 50,
    breakMinutes: 10,
    key: 'san_marzano',
  ),
  cuoreDiBue(
    label: '🍅 Cuore di Bue',
    workMinutes: 100,
    breakMinutes: 20,
    key: 'cuore_di_bue',
  );

  final String label;
  final int workMinutes;
  final int breakMinutes;
  final String key;

  const TipoPomodoro({
    required this.label,
    required this.workMinutes,
    required this.breakMinutes,
    required this.key,
  });

  String get assetPath {
    switch (this) {
      case TipoPomodoro.datterino:
        return 'assets/Datterino.png';
      case TipoPomodoro.sanMarzano:
        return 'assets/San_Marzano.png';
      case TipoPomodoro.cuoreDiBue:
        return 'assets/Cuore_di_Bue.png';
    }
  }

  String get labelWithoutEmoji {
    switch (this) {
      case TipoPomodoro.datterino:
        return 'Datterino';
      case TipoPomodoro.sanMarzano:
        return 'San Marzano';
      case TipoPomodoro.cuoreDiBue:
        return 'Cuore di Bue';
    }
  }
}

/// Schermata Timer Pomodoro con selezione tipo.
///
/// Ciclo: studio → pausa → ripeti.
/// Al termine di ogni sessione di studio, aggiorna i contatori
/// dell'attività nel database.
class PomodoroScreen extends StatefulWidget {
  final Attivita attivita;
  const PomodoroScreen({super.key, required this.attivita});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  TipoPomodoro _tipoPomodoro = TipoPomodoro.datterino;

  late int _totalSeconds;
  late int _remainingSeconds;
  bool _isRunning = false;
  bool _isBreak = false;
  int _sessionsCompleted = 0;
  int _minutesStudied = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _tipoPomodoro.workMinutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _onTimerComplete();
        }
      });
    });
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _totalSeconds = _tipoPomodoro.workMinutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _onTimerComplete() {
    SystemSound.play(SystemSoundType.alert);
    if (!_isBreak) {
      // Fine sessione di studio
      _sessionsCompleted++;
      _minutesStudied += _tipoPomodoro.workMinutes;
      // Salva il pomodoro nel DB con il tipo
      context.read<AttivitaProvider>().completaPomodoro(
            widget.attivita.id,
            _tipoPomodoro.key,
          );
      // Passa alla pausa
      setState(() {
        _isRunning = false;
        _isBreak = true;
        _totalSeconds = _tipoPomodoro.breakMinutes * 60;
        _remainingSeconds = _totalSeconds;
      });
      _showSnackBar('Sessione completata! Tempo per una pausa 🎉');
    } else {
      // Fine pausa, torna al lavoro
      setState(() {
        _isRunning = false;
        _isBreak = false;
        _totalSeconds = _tipoPomodoro.workMinutes * 60;
        _remainingSeconds = _totalSeconds;
      });
      _showSnackBar('Pausa finita! Pronto per un\'altra sessione? 💪');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _changeTipo(TipoPomodoro tipo) {
    if (_isRunning) return; // Non cambiare tipo durante il timer
    _timer?.cancel();
    setState(() {
      _tipoPomodoro = tipo;
      _isBreak = false;
      _totalSeconds = tipo.workMinutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Pomodoro'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nome attività
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.attivita.titolo,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),

              // Selettore tipo pomodoro
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TipoPomodoro>(
                    value: _tipoPomodoro,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    items: TipoPomodoro.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Row(
                                children: [
                                  Image.asset(
                                    t.assetPath,
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t.labelWithoutEmoji,
                                      style: theme
                                          .textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${t.workMinutes}m/${t.breakMinutes}m',
                                    style: theme
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme
                                          .colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: _isRunning
                        ? null
                        : (v) {
                            if (v != null) _changeTipo(v);
                          },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Timer widget
              PomodoroTimerWidget(
                secondsRemaining: _remainingSeconds,
                totalSeconds: _totalSeconds,
                isRunning: _isRunning,
                isBreak: _isBreak,
              ),
              const SizedBox(height: 40),

              // Controlli
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset
                  IconButton.outlined(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    iconSize: 28,
                  ),
                  const SizedBox(width: 20),
                  // Play/Pause
                  IconButton.filled(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    icon: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow),
                    iconSize: 40,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Skip
                  IconButton.outlined(
                    onPressed: () {
                      _timer?.cancel();
                      _onTimerComplete();
                    },
                    icon: const Icon(Icons.skip_next),
                    iconSize: 28,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Stats sessione
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      Text('$_sessionsCompleted',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Pomodori',
                          style: theme.textTheme.bodySmall),
                    ]),
                    Container(
                        width: 1,
                        height: 40,
                        color: theme.colorScheme.outline
                            .withValues(alpha: 0.3)),
                    Column(children: [
                      Text('${_minutesStudied}m',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Studiato',
                          style: theme.textTheme.bodySmall),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
