import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/corso.dart';
import '../../providers/corso_provider.dart';
import '../../providers/esame_provider.dart';
import '../../widgets/esame_card.dart';
import 'corso_form_screen.dart';
import 'esame_form_screen.dart';

/// Schermata di dettaglio di un Corso.
///
/// Mostra tutte le informazioni del corso e la lista degli esami associati.
/// Permette di modificare il corso e aggiungere nuovi esami.
class CorsoDetailScreen extends StatefulWidget {
  final String corsoId;

  const CorsoDetailScreen({super.key, required this.corsoId});

  @override
  State<CorsoDetailScreen> createState() => _CorsoDetailScreenState();
}

class _CorsoDetailScreenState extends State<CorsoDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EsameProvider>().loadEsami();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<CorsoProvider, EsameProvider>(
      builder: (context, corsoProvider, esameProvider, _) {
        final corso = corsoProvider.getCorsoById(widget.corsoId);
        if (corso == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Corso non trovato')),
          );
        }

        final esamiCorso = esameProvider.getEsamiByDate(DateTime(1900)) 
            .isEmpty
            ? esameProvider.esami
                .where((e) => e.corsoId == corso.id)
                .toList()
            : esameProvider.esami
                .where((e) => e.corsoId == corso.id)
                .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(corso.nome),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CorsoFormScreen(corso: corso),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Info corso
              _buildInfoSection(context, corso, theme),
              const SizedBox(height: 16),

              // Sezione esami
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Esami e Scadenze',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${esamiCorso.length} elementi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (esamiCorso.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.quiz_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(
                          'Nessun esame per questo corso',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...esamiCorso.map((esame) => EsameCard(
                      esame: esame,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EsameFormScreen(
                              esame: esame,
                              corsoId: corso.id,
                            ),
                          ),
                        );
                      },
                      onDelete: () => _confirmDeleteEsame(context, esame.id),
                    )),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EsameFormScreen(corsoId: corso.id),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Esame'),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, Corso corso, ThemeData theme) {
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
                icon: Icons.person, label: 'Docente', value: corso.docente),
            _DetailRow(
                icon: Icons.school,
                label: 'CFU',
                value: corso.cfu.toString()),
            _DetailRow(
                icon: Icons.calendar_today,
                label: 'Semestre',
                value: '${corso.semestre}° Semestre'),
            _DetailRow(
                icon: Icons.flag,
                label: 'Stato',
                value: Corso.statoLabel(corso.stato)),
            if (corso.votoPrevisto != null)
              _DetailRow(
                  icon: Icons.trending_up,
                  label: 'Voto previsto',
                  value: '${corso.votoPrevisto}/30'),
            if (corso.votoOttenuto != null)
              _DetailRow(
                  icon: Icons.grade,
                  label: 'Voto ottenuto',
                  value: '${corso.votoOttenuto}/30'),
            if (corso.descrizione.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Descrizione',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  )),
              const SizedBox(height: 4),
              Text(corso.descrizione, style: theme.textTheme.bodyMedium),
            ],
            if (corso.materiali.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Materiali',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  )),
              const SizedBox(height: 4),
              Text(corso.materiali, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEsame(BuildContext context, String esameId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina esame'),
        content: const Text('Vuoi eliminare questo esame?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              context.read<EsameProvider>().deleteEsame(esameId);
              Navigator.pop(ctx);
            },
            child: Text('Elimina',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
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
              )),
        ],
      ),
    );
  }
}
