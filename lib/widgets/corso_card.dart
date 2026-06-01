import 'package:flutter/material.dart';
import '../models/corso.dart';

/// Card per visualizzare un corso nella lista.
///
/// Mostra nome, docente, CFU, semestre, tipo laurea/anno e badge con lo stato.
/// Il voto calcolato viene passato come parametro opzionale e appare a destra
/// nella riga del titolo per mantenere altezza uniforme.
/// Supporta swipe per rivelare il cestino ed eliminare.
class CorsoCard extends StatelessWidget {
  final Corso corso;
  final double? votoCalcolato;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CorsoCard({
    super.key,
    required this.corso,
    this.votoCalcolato,
    this.onTap,
    this.onDelete,
  });

  Color _statoColor(String stato) {
    switch (stato) {
      case 'da_iniziare':
        return Colors.grey;
      case 'in_corso':
        return Colors.blue;
      case 'terminato':
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
      case 'terminato':
        return Icons.check_circle_outline;
      case 'da_ripassare':
        return Icons.refresh;
      case 'superato':
        return Icons.emoji_events;
      default:
        return Icons.help_outline;
    }
  }

  int _arrotondaVoto(double voto) {
    final roundedDec = double.parse(voto.toStringAsFixed(2));
    final intero = roundedDec.floor();
    final decimale = roundedDec - intero;
    return decimale > 0.5 ? (intero + 1) : intero;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statoColor(corso.stato);
    final int? votoIntero = votoCalcolato != null && votoCalcolato! > 0
        ? _arrotondaVoto(votoCalcolato!)
        : null;
    final hasVoto = votoIntero != null;
    final showVotoPrevisto = !hasVoto && corso.votoPrevisto != null;
    final showBadge = hasVoto || showVotoPrevisto;

    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _statoIcon(corso.stato),
                          color: color, 
                          size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Padding a destra per non sovrapporsi al badge voto
                            Padding(
                              padding: EdgeInsets.only(
                                  right: showBadge ? 60 : 0),
                              child: Text(
                                corso.nome,
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              corso.docente,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
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
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.workspace_premium,
                        label: '${Corso.tipoLaureaLabel(corso.tipoLaurea)[0]}${corso.anno}',
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                ],
              ),
            ),
            // Badge voto nell'angolo in alto a destra
            if (showBadge)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 12, right: 10, top: 6, bottom: 8),
                  decoration: BoxDecoration(
                    color: hasVoto
                        ? Colors.amber.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.elliptical(24, 20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasVoto
                            ? ((corso.stato == 'superato')
                                ? (corso.lode ? Icons.star_rounded : Icons.check_rounded)
                                : Icons.star_rounded)
                            : Icons.trending_up,
                        size: 16,
                        color: hasVoto ? Colors.amber[700] : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        hasVoto ? '$votoIntero' : '${corso.votoPrevisto}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: hasVoto ? Colors.amber[700] : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
              key: ValueKey(corso.id),
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
        Icon(icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
      ],
    );
  }
}
