import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/esame.dart';

/// Card per visualizzare un esame nella lista.
///
/// Mostra titolo, data, tipologia, priorità con colore, stato e voto.
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
      case 'annullato':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prioritaColor = _prioritaColor(esame.priorita);
    final dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: prioritaColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
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
                        Text(
                          esame.titolo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: esame.stato == 'annullato'
                                ? TextDecoration.lineThrough
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
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: theme.colorScheme.error, size: 20),
                      onPressed: onDelete,
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
                    dateFormat.format(esame.data),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Esame.tipologiaLabel(esame.tipologia),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statoColor(esame.stato).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
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
              if (esame.voto != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.grade,
                        size: 16,
                        color: esame.superato ? Colors.amber[700] : Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Voto: ${esame.voto}/30',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            esame.superato ? Colors.amber[700] : Colors.red,
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
  }
}
