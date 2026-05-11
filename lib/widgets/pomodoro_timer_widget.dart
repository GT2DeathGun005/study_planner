import 'dart:math';
import 'package:flutter/material.dart';

/// Widget del timer Pomodoro con progresso circolare animato.
///
/// Disegna un arco che si riempie col passare del tempo,
/// mostrando i minuti e secondi rimanenti al centro.
class PomodoroTimerWidget extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final bool isRunning;
  final bool isBreak;

  const PomodoroTimerWidget({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.isRunning,
    this.isBreak = false,
  });

  String get timeDisplay {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (totalSeconds <= 0) return 0;
    return 1.0 - (secondsRemaining / totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isBreak ? Colors.green : theme.colorScheme.primary;

    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _CircularProgressPainter(
          progress: progress,
          color: color,
          backgroundColor:
              theme.colorScheme.surfaceContainerHighest,
          strokeWidth: 10,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeDisplay,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBreak ? 'Pausa' : 'Studio',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter per il progresso circolare del timer Pomodoro.
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Sfondo
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progresso
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Inizia dall'alto
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
