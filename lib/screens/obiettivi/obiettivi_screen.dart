import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/corso_provider.dart';
import '../../providers/obiettivo_provider.dart';
import '../../widgets/obiettivo_card.dart';
import 'obiettivo_form_screen.dart';
import 'pomodoro_screen.dart';

/// Schermata principale della sezione Obiettivi.
///
/// Mostra la lista dei task/obiettivi con filtri per completamento e priorità,
/// pulsante Pomodoro per ogni task e FAB per aggiungere.
class ObiettiviScreen extends StatefulWidget {
  const ObiettiviScreen({super.key});

  @override
  State<ObiettiviScreen> createState() => _ObiettiviScreenState();
}

class _ObiettiviScreenState extends State<ObiettiviScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObiettivoProvider>().loadObiettivi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obiettivi di Studio'),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              final provider = context.read<ObiettivoProvider>();
              switch (value) {
                case 'tutti':
                  provider.resetFiltri();
                  break;
                case 'da_completare':
                  provider.setFiltroCompletato(false);
                  break;
                case 'completati':
                  provider.setFiltroCompletato(true);
                  break;
                case 'alta':
                case 'media':
                case 'bassa':
                  provider.setFiltroPriorita(value);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'tutti', child: Text('Mostra tutti')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'da_completare', child: Text('Da completare')),
              const PopupMenuItem(
                  value: 'completati', child: Text('Completati')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'alta', child: Text('Priorità alta')),
              const PopupMenuItem(
                  value: 'media', child: Text('Priorità media')),
              const PopupMenuItem(
                  value: 'bassa', child: Text('Priorità bassa')),
            ],
          ),
        ],
      ),
      body: Consumer2<ObiettivoProvider, CorsoProvider>(
        builder: (context, obiettivoProvider, corsoProvider, _) {
          if (obiettivoProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final obiettivi = obiettivoProvider.obiettivi;

          if (obiettivi.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Nessun obiettivo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea il tuo primo obiettivo di studio!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          // Riepilogo rapido
          final totale = obiettivoProvider.tuttiObiettivi.length;
          final completati = obiettivoProvider.completati;

          return Column(
            children: [
              // Riepilogo top
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(
                      value: '$completati/$totale',
                      label: 'Completati',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _MiniStat(
                      value: _formatMinutes(
                          obiettivoProvider.totaleTempoEffettivo),
                      label: 'Studiato',
                      icon: Icons.timer,
                      color: Colors.blue,
                    ),
                    _MiniStat(
                      value: _formatMinutes(
                          obiettivoProvider.totaleTempoStimato),
                      label: 'Pianificato',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),

              // Lista obiettivi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: obiettivi.length,
                  itemBuilder: (context, index) {
                    final obiettivo = obiettivi[index];
                    final nomeCorso = obiettivo.corsoId != null
                        ? corsoProvider
                            .getCorsoById(obiettivo.corsoId!)
                            ?.nome
                        : null;

                    return ObiettivoCard(
                      obiettivo: obiettivo,
                      nomeCorso: nomeCorso,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ObiettivoFormScreen(obiettivo: obiettivo),
                          ),
                        );
                      },
                      onToggle: () {
                        obiettivoProvider.toggleCompletato(obiettivo.id);
                      },
                      onPomodoro: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PomodoroScreen(obiettivo: obiettivo),
                          ),
                        );
                      },
                      onDelete: () =>
                          _confirmDelete(context, obiettivo.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ObiettivoFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina obiettivo'),
        content: const Text('Vuoi eliminare questo obiettivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              context.read<ObiettivoProvider>().deleteObiettivo(id);
              Navigator.pop(ctx);
            },
            child: Text('Elimina',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            )),
      ],
    );
  }
}
