import 'package:flutter/material.dart';
import '../models/obiettivo.dart';

/// Card per visualizzare un obiettivo/task nella lista.
///
/// Mostra checkbox, titolo, priorità, barra di progresso tempo
/// e pulsante per avviare il Pomodoro.
/// Supporta swipe per rivelare il cestino ed eliminare.
class ObiettivoCard extends StatelessWidget {
  final Obiettivo obiettivo;
  final String? nomeCorso;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;
  final VoidCallback? onPomodoro;

  const ObiettivoCard({
    super.key,
    required this.obiettivo,
    this.nomeCorso,
    this.onTap,
    this.onDelete,
    this.onToggle,
    this.onPomodoro,
  });

  Color _prioritaColor(String priorita) {
    switch (priorita) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'bassa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _prioritaColor(obiettivo.priorita);

    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: obiettivo.completato
              ? Colors.green.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Checkbox completamento
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: obiettivo.completato
                            ? Colors.green
                            : Colors.transparent,
                        border: Border.all(
                          color: obiettivo.completato
                              ? Colors.green
                              : theme.colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: obiettivo.completato
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obiettivo.titolo,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: obiettivo.completato
                                ? TextDecoration.lineThrough
                                : null,
                            color: obiettivo.completato
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5)
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (nomeCorso != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            nomeCorso!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Priorità chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Obiettivo.prioritaLabel(obiettivo.priorita),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              // Barra progresso tempo
              if (obiettivo.tempoStimato > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const SizedBox(width: 40), // Allineato con il testo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: obiettivo.progressoTempo,
                              backgroundColor: theme
                                  .colorScheme.surfaceContainerHighest,
                              color: obiettivo.progressoTempo >= 1.0
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${Obiettivo.formatMinuti(obiettivo.tempoEffettivo)} / ${Obiettivo.formatMinuti(obiettivo.tempoStimato)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              // Azioni (solo Pomodoro, il cestino è nello swipe)
              if (!obiettivo.completato && onPomodoro != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 40),
                    TextButton.icon(
                      onPressed: onPomodoro,
                      icon: const Icon(Icons.timer, size: 16),
                      label: const Text('Pomodoro'),
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                child: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
            ),
            Dismissible(
              key: ValueKey(obiettivo.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                onDelete!();
                return false; // La conferma viene gestita dalla dialog
              },
              child: card,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: card,
    );
  }
}
