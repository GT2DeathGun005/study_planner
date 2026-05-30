import 'package:flutter/material.dart';
import '../models/attivita.dart';

/// Card per visualizzare un'attività all'interno del dettaglio obiettivo.
///
/// Mostra checkbox, titolo (con strikethrough se completata),
/// chip priorità, indicatore pomodori e pulsante timer.
/// Supporta swipe per rivelare il cestino ed eliminare.
class AttivitaCard extends StatelessWidget {
  final Attivita attivita;
  final VoidCallback? onToggle;
  final VoidCallback? onPomodoro;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AttivitaCard({
    super.key,
    required this.attivita,
    this.onToggle,
    this.onPomodoro,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completata = attivita.completata;

    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: completata
              ? Colors.green.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: completata,
                  onChanged: (_) => onToggle?.call(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Contenuto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attivita.titolo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: completata
                            ? TextDecoration.lineThrough
                            : null,
                        color: completata
                            ? theme.colorScheme.onSurface
                                .withValues(alpha: 0.4)
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Indicatore pomodori
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                Colors.deepOrange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('\u{1F345}',
                                  style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 3),
                              Text(
                                '${attivita.pomodoroCompletati}/${attivita.pomodoroTotali}',
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepOrange,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (attivita.descrizione.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              attivita.descrizione,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Pulsante Pomodoro (sempre visibile, centrato verticalmente con la spunta)
              if (onPomodoro != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onPomodoro,
                  icon: const Icon(Icons.timer_outlined),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Avvia Pomodoro',
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Swipe to reveal delete
    if (onDelete != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child:
                    const Icon(Icons.delete, color: Colors.white, size: 24),
              ),
            ),
            Dismissible(
              key: ValueKey(attivita.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                onDelete!();
                return false;
              },
              child: card,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: card,
    );
  }
}
