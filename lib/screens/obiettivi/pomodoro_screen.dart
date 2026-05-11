import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/obiettivo.dart';
import '../../providers/obiettivo_provider.dart';
import '../../widgets/pomodoro_timer_widget.dart';

/// Schermata Timer Pomodoro (Feature Avanzata 2).
///
/// Ciclo: 25 min studio → 5 min pausa → ripeti.
/// Al termine di ogni sessione di studio, aggiorna il tempo effettivo
/// dell'obiettivo nel database.
class PomodoroScreen extends StatefulWidget {
  final Obiettivo obiettivo;
  const PomodoroScreen({super.key, required this.obiettivo});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int _workMinutes = 25;
  static const int _breakMinutes = 5;

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
    _totalSeconds = _workMinutes * 60;
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
      _totalSeconds = _workMinutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _onTimerComplete() {
    if (!_isBreak) {
      // Fine sessione di studio
      _sessionsCompleted++;
      _minutesStudied += _workMinutes;
      // Salva il tempo nel DB
      context.read<ObiettivoProvider>().aggiungiTempo(
            widget.obiettivo.id,
            _workMinutes,
          );
      // Passa alla pausa
      setState(() {
        _isBreak = true;
        _totalSeconds = _breakMinutes * 60;
        _remainingSeconds = _totalSeconds;
      });
      _showSnackBar('Sessione completata! Tempo per una pausa 🎉');
    } else {
      // Fine pausa, torna al lavoro
      setState(() {
        _isBreak = false;
        _totalSeconds = _workMinutes * 60;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Pomodoro'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Nome obiettivo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.obiettivo.titolo,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 40),

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
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
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
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Text('$_sessionsCompleted', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Sessioni', style: theme.textTheme.bodySmall),
                  ]),
                  Container(width: 1, height: 40, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  Column(children: [
                    Text('${_minutesStudied}m', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Studiato', style: theme.textTheme.bodySmall),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
