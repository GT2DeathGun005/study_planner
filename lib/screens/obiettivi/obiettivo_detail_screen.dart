import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/obiettivo.dart';
import '../../providers/attivita_provider.dart';
import '../../providers/corso_provider.dart';
import '../../providers/obiettivo_provider.dart';
import '../../widgets/attivita_card.dart';
import 'attivita_detail_screen.dart';
import 'attivita_form_screen.dart';
import 'obiettivo_form_screen.dart';
import 'pomodoro_screen.dart';

/// Schermata di dettaglio di un Obiettivo.
///
/// Mostra le informazioni dell'obiettivo in alto e la lista delle attività
/// che lo compongono, con FAB per aggiungere una nuova attività.
class ObiettivoDetailScreen extends StatefulWidget {
  final Obiettivo obiettivo;

  const ObiettivoDetailScreen({super.key, required this.obiettivo});

  @override
  State<ObiettivoDetailScreen> createState() => _ObiettivoDetailScreenState();
}

class _ObiettivoDetailScreenState extends State<ObiettivoDetailScreen> {
  late Obiettivo _obiettivo;

  @override
  void initState() {
    super.initState();
    _obiettivo = widget.obiettivo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttivitaProvider>().loadAttivita(_obiettivo.id);
    });
  }

  String _getFormattedDate(DateTime date) {
    final raw = DateFormat('dd MMM yyyy', 'it_IT').format(date);
    final parts = raw.split(' ');
    if (parts.length >= 2) {
      parts[1] = parts[1][0].toUpperCase() + parts[1].substring(1);
    }
    return parts.join(' ');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corsoProv = context.watch<CorsoProvider>();
    final nomeCorso = _obiettivo.corsoId != null
        ? corsoProv.getCorsoById(_obiettivo.corsoId!)?.nome
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_obiettivo.titolo),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica obiettivo',
            onPressed: () async {
              // Ricarica dal DB per avere stato aggiornato
              await context
                  .read<ObiettivoProvider>()
                  .loadObiettivi();
              if (!context.mounted) return;
              final updated = context
                  .read<ObiettivoProvider>()
                  .tuttiObiettivi
                  .where((o) => o.id == _obiettivo.id)
                  .firstOrNull;
              if (updated == null) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ObiettivoFormScreen(obiettivo: updated),
                ),
              );
              if (context.mounted) {
                await context
                    .read<ObiettivoProvider>()
                    .loadObiettivi();
                final refreshed = context
                    .read<ObiettivoProvider>()
                    .tuttiObiettivi
                    .where((o) => o.id == _obiettivo.id)
                    .firstOrNull;
                if (refreshed != null) {
                  setState(() => _obiettivo = refreshed);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con informazioni obiettivo
          _buildInfoSection(context, theme, nomeCorso),

          // Titolo sezione attività
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Attività',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer<AttivitaProvider>(
                  builder: (context, attProv, _) {
                    final completate = attProv.attivita
                        .where((a) => a.completata)
                        .length;
                    final totale = attProv.attivita.length;
                    if (totale == 0) return const SizedBox.shrink();
                    return Text(
                      '$completate/$totale',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista attività
          Expanded(
            child: Consumer<AttivitaProvider>(
              builder: (context, attivitaProvider, _) {
                if (attivitaProvider.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final attivita = attivitaProvider.attivita;

                if (attivita.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_outlined,
                            size: 56,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Nessuna attività',
                          style:
                              theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aggiungi la prima attività per questo obiettivo',
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: attivita.length,
                  itemBuilder: (context, index) {
                    final att = attivita[index];
                    return AttivitaCard(
                      attivita: att,
                      onToggle: () async {
                        await attivitaProvider.toggleCompletata(att.id);
                        // Ricarica l'obiettivo dopo il toggle per aggiornare lo stato
                        await _refreshObiettivo();
                      },
                      onPomodoro: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PomodoroScreen(attivita: att),
                          ),
                        );
                        if (context.mounted) {
                          await attivitaProvider
                              .loadAttivita(_obiettivo.id);
                          await _refreshObiettivo();
                        }
                      },
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttivitaDetailScreen(
                              attivitaId: att.id,
                              obiettivoId: _obiettivo.id,
                            ),
                          ),
                        );
                        if (context.mounted) {
                          await attivitaProvider
                              .loadAttivita(_obiettivo.id);
                          await _refreshObiettivo();
                        }
                      },
                      onDelete: () =>
                          _confirmDeleteAttivita(context, att),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttivitaFormScreen(
                obiettivoId: _obiettivo.id,
              ),
            ),
          );
          if (context.mounted) {
            await context
                .read<AttivitaProvider>()
                .loadAttivita(_obiettivo.id);
            await _refreshObiettivo();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Attività'),
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, ThemeData theme, String? nomeCorso) {
    return Card(
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
              value: Obiettivo.statoLabel(_obiettivo.stato),
              valueColor: _statoColor(_obiettivo.stato),
            ),
            _DetailRow(
              icon: Icons.priority_high,
              label: 'Priorità',
              value: Obiettivo.prioritaLabel(_obiettivo.priorita),
              valueColor: _prioritaColor(_obiettivo.priorita),
            ),
            _DetailRow(
              icon: Icons.event,
              label: 'Data pianificata',
              value: _obiettivo.dataPianificata != null
                  ? _getFormattedDate(_obiettivo.dataPianificata!)
                  : 'Nessuna',
            ),
            if (nomeCorso != null)
              _DetailRow(
                icon: Icons.book,
                label: 'Corso',
                value: nomeCorso,
              ),
            // Pomodoro summary
            Consumer<AttivitaProvider>(
              builder: (context, attProv, _) {
                final pomComp = attProv.pomodoroCompletati;
                final pomTot = attProv.pomodoroTotali;
                return _DetailRow(
                  icon: Icons.timer,
                  label: 'Pomodori',
                  value: pomTot > 0 ? '$pomComp/$pomTot' : '0',
                  valueColor: Colors.deepOrange,
                );
              },
            ),
            if (_obiettivo.descrizione.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Descrizione',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  )),
              const SizedBox(height: 4),
              Text(_obiettivo.descrizione,
                  style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _refreshObiettivo() async {
    if (!mounted) return;
    await context.read<ObiettivoProvider>().loadObiettivi();
    if (!mounted) return;
    final refreshed = context
        .read<ObiettivoProvider>()
        .tuttiObiettivi
        .where((o) => o.id == _obiettivo.id)
        .firstOrNull;
    if (refreshed != null) {
      setState(() => _obiettivo = refreshed);
    }
  }

  void _confirmDeleteAttivita(
      BuildContext context, dynamic attivita) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina attività'),
        content: Text(
            'Vuoi eliminare "${attivita.titolo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              context.read<AttivitaProvider>().deleteAttivita(
                  attivita.id, _obiettivo.id);
              Navigator.pop(ctx);
              _refreshObiettivo();
            },
            child: Text('Elimina',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

/// Riga informativa con icona, etichetta e valore allineata a destra.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              )),
        ],
      ),
    );
  }
}
