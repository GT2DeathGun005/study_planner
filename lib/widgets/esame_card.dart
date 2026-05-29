import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/esame.dart';

/// Card per visualizzare un esame nella lista.
///
/// Mostra titolo, data, tipologia, priorità con colore, stato, voto
/// e peso percentuale. Il voto appare a destra nella riga del titolo
/// per mantenere altezza uniforme.
/// Supporta swipe per rivelare il cestino ed eliminare.
class EsameCard extends StatelessWidget {
  final Esame esame;
  final String? nomeCorso;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EsameCard({
    super.key,
    required this.esame,
    this.nomeCorso,
    this.onTap,
    this.onDelete,
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

  Color _statoColor(String stato) {
    switch (stato) {
      case 'programmato':
        return Colors.blue;
      case 'completato':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prioritaColor = _prioritaColor(esame.priorita);
    final hasVoto = esame.voto != null;
    final votoColor = esame.superato ? Colors.amber[700]! : Colors.red;

    // Formattazione data con mese abbreviato capitalizzato (es: 28 Mag 2026)
    final dayStr = DateFormat('dd', 'it_IT').format(esame.data);
    final monthStr = DateFormat('MMM', 'it_IT').format(esame.data);
    final yearStr = DateFormat('yyyy', 'it_IT').format(esame.data);
    final capitalizedMonth = monthStr.isEmpty
        ? ''
        : (monthStr[0].toUpperCase() + monthStr.substring(1));
    final formattedDate = '$dayStr $capitalizedMonth $yearStr';

    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: prioritaColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Contenuto principale
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: prioritaColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: hasVoto ? 50 : 0),
                              child: Text(
                                esame.titolo,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (nomeCorso != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                nomeCorso!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
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
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Esame.tipologiaLabel(esame.tipologia),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Peso percentuale
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${esame.pesoPercentuale}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _statoColor(esame.stato).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Esame.statoLabel(esame.stato),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _statoColor(esame.stato),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
            // Badge voto nell'angolo in alto a destra
            if (hasVoto)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 12, right: 10, top: 6, bottom: 8),
                  decoration: BoxDecoration(
                    color: votoColor.withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.elliptical(24, 20),
                    ),
                  ),
                  child: Text(
                    '${esame.voto}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: votoColor,
                    ),
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
              key: ValueKey(esame.id),
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
