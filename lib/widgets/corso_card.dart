import 'package:flutter/material.dart';
import '../models/corso.dart';

/// Card per visualizzare un corso nella lista.
///
/// Mostra nome, docente, CFU, semestre e badge con lo stato.
/// Supporta tap per navigare al dettaglio e long-press per azioni.
class CorsoCard extends StatelessWidget {
  final Corso corso;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CorsoCard({
    super.key,
    required this.corso,
    this.onTap,
    this.onDelete,
  });

  Color _statoColor(String stato) {
    switch (stato) {
      case 'da_iniziare':
        return Colors.grey;
      case 'in_corso':
        return Colors.blue;
      case 'completato':
        return Colors.orange;
      case 'da_ripassare':
        return Colors.amber;
      case 'superato':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statoIcon(String stato) {
    switch (stato) {
      case 'da_iniziare':
        return Icons.hourglass_empty;
      case 'in_corso':
        return Icons.play_circle_outline;
      case 'completato':
        return Icons.check_circle_outline;
      case 'da_ripassare':
        return Icons.refresh;
      case 'superato':
        return Icons.emoji_events;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statoColor(corso.stato);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_statoIcon(corso.stato), color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          corso.nome,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          corso.docente,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
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
                  _InfoChip(
                    icon: Icons.school,
                    label: '${corso.cfu} CFU',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: '${corso.semestre}° Sem.',
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Corso.statoLabel(corso.stato),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (corso.votoOttenuto != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.grade, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Voto: ${corso.votoOttenuto}/30',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
      ],
    );
  }
}
