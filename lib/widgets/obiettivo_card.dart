import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/obiettivo.dart';

/// Card per visualizzare un obiettivo nella lista.
///
/// Simile alla CorsoCard: icona stato a sinistra, titolo e data,
/// chip priorità in alto a destra, pomodori in basso a destra.
/// Supporta swipe per rivelare il cestino ed eliminare.
class ObiettivoCard extends StatelessWidget {
  final Obiettivo obiettivo;
  final String? nomeCorso;
  final int pomodoroCompletati;
  final int pomodoroTotali;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ObiettivoCard({
    super.key,
    required this.obiettivo,
    this.nomeCorso,
    this.pomodoroCompletati = 0,
    this.pomodoroTotali = 0,
    this.onTap,
    this.onDelete,
  });

  Color _statoColor(String stato) {
    switch (stato) {
      case 'raggiunto':
        return Colors.green;
      case 'prefissato':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }


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
    final color = _statoColor(obiettivo.stato);
    final prioColor = _prioritaColor(obiettivo.priorita);

    String? formattedDate;
    if (obiettivo.dataPianificata != null) {
      final dp = obiettivo.dataPianificata!;
      final dayStr = DateFormat('dd', 'it_IT').format(dp);
      final monthStr = DateFormat('MMM', 'it_IT').format(dp);
      final yearStr = DateFormat('yyyy', 'it_IT').format(dp);
      final capitalizedMonth = monthStr.isEmpty
          ? ''
          : (monthStr[0].toUpperCase() + monthStr.substring(1));
      formattedDate = '$dayStr $capitalizedMonth $yearStr';
    }


    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: prioColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Contenuto principale
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 114),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Segnetto vicino al titolo (colore rispecchia la priorità)
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: prioColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 60),
                                child: Text(
                                  obiettivo.titolo,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (nomeCorso != null && nomeCorso!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  nomeCorso!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate ?? 'Nessuna',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        // Stato label sotto a destra
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            Obiettivo.statoLabel(obiettivo.stato),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Pomodori nell'angolo in alto a destra
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(
                    left: 12, right: 10, top: 6, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.elliptical(24, 20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍅', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      pomodoroTotali > 0
                          ? '$pomodoroCompletati/$pomodoroTotali'
                          : '0',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                return false;
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
