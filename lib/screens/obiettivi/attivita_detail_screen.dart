import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attivita_provider.dart';
import '../../providers/obiettivo_provider.dart';
import 'attivita_form_screen.dart';

/// Schermata di dettaglio di un'Attività.
///
/// Mostra tutte le informazioni dell'attività, i pomodori completati
/// suddivisi per tipologia (Datterino, San Marzano, Cuore di Bue),
/// i minuti totali di studio e lo stato di completamento.
/// Consente di modificare l'attività tramite un pulsante edit (matita) in alto a destra.
class AttivitaDetailScreen extends StatefulWidget {
  final String attivitaId;
  final String obiettivoId;

  const AttivitaDetailScreen({
    super.key,
    required this.attivitaId,
    required this.obiettivoId,
  });

  @override
  State<AttivitaDetailScreen> createState() => _AttivitaDetailScreenState();
}

class _AttivitaDetailScreenState extends State<AttivitaDetailScreen> {
  @override
  void initState() {
    super.initState();
    final attivitaProvider = context.read<AttivitaProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      attivitaProvider.loadAttivita(widget.obiettivoId);
    });
  }

  Color _statoColor(bool completata) {
    return completata ? Colors.green : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AttivitaProvider>(
      builder: (context, provider, _) {
        final attivitaList = provider.attivita.where(
          (a) => a.id == widget.attivitaId,
        );
        if (attivitaList.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Attività non trovata')),
          );
        }

        final attivita = attivitaList.first;

        return Scaffold(
          appBar: AppBar(
            title: Text(attivita.titolo),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final attivitaProvider = context.read<AttivitaProvider>();
                  final obiettivoProvider = context.read<ObiettivoProvider>();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AttivitaFormScreen(
                            obiettivoId: widget.obiettivoId,
                            attivita: attivita,
                          ),
                    ),
                  );
                  if (!context.mounted) return;
                  await attivitaProvider.loadAttivita(widget.obiettivoId);
                  if (!context.mounted) return;
                  // Rinfresca anche l'obiettivo padre se necessario
                  await obiettivoProvider.loadObiettivi();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        icon: Icons.traffic,
                        label: 'Stato',
                        value: attivita.completata ? 'Completata' : 'In corso',
                        valueColor: _statoColor(attivita.completata),
                      ),
                      _DetailRow(
                        icon: Icons.schedule,
                        label: 'Tempo di studio totale',
                        value: '${attivita.minutiStudio} min',
                        valueColor: theme.colorScheme.primary,
                      ),
                      _DetailRow(
                        icon: Icons.timer_outlined,
                        label: 'Pomodori totali',
                        value:
                            '${attivita.pomodoroCompletati}/${attivita.pomodoroTotali}',
                        valueColor: Colors.deepOrange,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        iconWidget: Image.asset('assets/Datterino.png'),
                        label: 'Pomodori Datterino (25 min)',
                        value: '${attivita.pomodoroDatterino}',
                      ),
                      _DetailRow(
                        iconWidget: Image.asset('assets/San_Marzano.png'),
                        label: 'Pomodori San Marzano (50 min)',
                        value: '${attivita.pomodoroSanMarzano}',
                      ),
                      _DetailRow(
                        iconWidget: Image.asset('assets/Cuore_di_Bue.png'),
                        label: 'Pomodori Cuore di Bue (100 min)',
                        value: '${attivita.pomodoroCuoreDiBue}',
                      ),
                      if (attivita.descrizione.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          'Descrizione',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          attivita.descrizione,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (iconWidget != null)
            SizedBox(width: 20, height: 20, child: iconWidget)
          else if (icon != null)
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )
          else
            const SizedBox(width: 20, height: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
