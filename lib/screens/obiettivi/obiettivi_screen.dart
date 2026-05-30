import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/obiettivo.dart';
import '../../providers/attivita_provider.dart';
import '../../providers/corso_provider.dart';
import '../../providers/obiettivo_provider.dart';
import '../../widgets/obiettivo_card.dart';
import 'obiettivo_detail_screen.dart';
import 'obiettivo_form_screen.dart';

/// Schermata principale della sezione Obiettivi.
///
/// Mostra la lista degli obiettivi con barra di ricerca e bottone filtro
/// (come nella schermata Corsi). FAB per aggiungere un nuovo obiettivo.
class ObiettiviScreen extends StatefulWidget {
  const ObiettiviScreen({super.key});

  @override
  State<ObiettiviScreen> createState() => _ObiettiviScreenState();
}

class _ObiettiviScreenState extends State<ObiettiviScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObiettivoProvider>().loadObiettivi();
      context.read<AttivitaProvider>().loadTutteAttivita();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obiettivi di Studio'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Barra di ricerca con bottone filtro
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cerca obiettivo...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<ObiettivoProvider>()
                                    .setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      context
                          .read<ObiettivoProvider>()
                          .setSearchQuery(value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Bottone filtro
                Consumer<ObiettivoProvider>(
                  builder: (context, provider, _) {
                    final filtriAttivi = _countFiltriAttivi(provider);
                    return Badge(
                      isLabelVisible: filtriAttivi > 0,
                      label: Text('$filtriAttivi'),
                      child: IconButton.filledTonal(
                        onPressed: () =>
                            _showFilterBottomSheet(context, provider),
                        icon: const Icon(Icons.filter_list),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Lista obiettivi
          Expanded(
            child: Consumer2<ObiettivoProvider, AttivitaProvider>(
              builder: (context, obiettivoProvider, attivitaProvider, _) {
                if (obiettivoProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final obiettivi = obiettivoProvider.obiettivi;
                final corsoProvider = context.read<CorsoProvider>();

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
                          'Nessun obiettivo trovato',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _countFiltriAttivi(obiettivoProvider) > 0
                              ? 'Prova a modificare i filtri'
                              : 'Crea il tuo primo obiettivo di studio!',
                          style: theme.textTheme.bodySmall?.copyWith(
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
                  itemCount: obiettivi.length,
                  itemBuilder: (context, index) {
                    final obiettivo = obiettivi[index];
                    final nomeCorso = obiettivo.corsoId != null
                        ? corsoProvider
                            .getCorsoById(obiettivo.corsoId!)
                            ?.nome
                        : null;
                    final pomCompletati = attivitaProvider
                        .pomodoroCompletatiPerObiettivo(obiettivo.id);
                    final pomTotali = attivitaProvider
                        .pomodoroTotaliPerObiettivo(obiettivo.id);

                    return ObiettivoCard(
                      obiettivo: obiettivo,
                      nomeCorso: nomeCorso,
                      pomodoroCompletati: pomCompletati,
                      pomodoroTotali: pomTotali,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ObiettivoDetailScreen(obiettivo: obiettivo),
                          ),
                        );
                        // Ricarica dopo il ritorno dal dettaglio
                        if (context.mounted) {
                          context
                              .read<ObiettivoProvider>()
                              .loadObiettivi();
                          context
                              .read<AttivitaProvider>()
                              .loadTutteAttivita();
                        }
                      },
                      onDelete: () =>
                          _confirmDelete(context, obiettivo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ObiettivoFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Obiettivo'),
      ),
    );
  }

  int _countFiltriAttivi(ObiettivoProvider provider) {
    int count = 0;
    if (provider.filtroStato.isNotEmpty) count++;
    if (provider.filtroPriorita.isNotEmpty) count++;
    return count;
  }

  void _showFilterBottomSheet(
      BuildContext context, ObiettivoProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterBottomSheet(provider: provider),
    );
  }

  void _confirmDelete(BuildContext context, Obiettivo obiettivo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina obiettivo'),
        content: Text(
            'Vuoi eliminare "${obiettivo.titolo}"?\nTutte le attività associate verranno eliminate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<ObiettivoProvider>()
                  .deleteObiettivo(obiettivo.id);
              context
                  .read<AttivitaProvider>()
                  .loadTutteAttivita();
              Navigator.pop(ctx);
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

/// Bottom sheet per i filtri degli obiettivi.
class _FilterBottomSheet extends StatefulWidget {
  final ObiettivoProvider provider;

  const _FilterBottomSheet({required this.provider});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late List<String> _stato;
  late List<String> _priorita;
  bool _isSortMode = false;
  late String _sortBy;
  late bool _sortAscending;

  @override
  void initState() {
    super.initState();
    _stato = List.from(widget.provider.filtroStato);
    _priorita = List.from(widget.provider.filtroPriorita);
    _sortBy = widget.provider.sortBy;
    _sortAscending = widget.provider.sortAscending;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isSortMode = !_isSortMode),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSortMode ? 'Ordina' : 'Filtra',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      ' Obiettivi',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_isSortMode) {
                      _sortBy = 'default';
                      _sortAscending = true;
                    } else {
                      _stato = [];
                      _priorita = [];
                    }
                  });
                },
                child: const Text('Resetta'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isSortMode) ...[
            Text('Ordina per',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildFilterChip(
                  label: 'Titolo',
                  selected: _sortBy == 'titolo',
                  onSelected: () => setState(() =>
                      _sortBy = _sortBy == 'titolo' ? 'default' : 'titolo'),
                ),
                _buildFilterChip(
                  label: 'Data pianificata',
                  selected: _sortBy == 'data',
                  onSelected: () => setState(() =>
                      _sortBy = _sortBy == 'data' ? 'default' : 'data'),
                ),
                _buildFilterChip(
                  label: 'Pomodori svolti',
                  selected: _sortBy == 'pomodori',
                  onSelected: () => setState(() =>
                      _sortBy = _sortBy == 'pomodori' ? 'default' : 'pomodori'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Direzione',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Crescente'),
                        icon: Icon(Icons.arrow_upward, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Decrescente'),
                        icon: Icon(Icons.arrow_downward, size: 18),
                      ),
                    ],
                    selected: {_sortAscending},
                    onSelectionChanged: (set) {
                      setState(() {
                        _sortAscending = set.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ] else ...[
            // Filtro stato
            Text('Stato',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(
                  label: 'Prefissati',
                  selected: _stato.contains('prefissato'),
                  onSelected: () => setState(() {
                    if (_stato.contains('prefissato')) {
                      _stato.remove('prefissato');
                    } else {
                      _stato.add('prefissato');
                    }
                  }),
                ),
                _buildFilterChip(
                  label: 'Raggiunti',
                  selected: _stato.contains('raggiunto'),
                  onSelected: () => setState(() {
                    if (_stato.contains('raggiunto')) {
                      _stato.remove('raggiunto');
                    } else {
                      _stato.add('raggiunto');
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filtro priorità
            Text('Priorità',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ...Obiettivo.prioritaDisponibili.map((p) =>
                    _buildFilterChip(
                      label: Obiettivo.prioritaLabel(p),
                      selected: _priorita.contains(p),
                      onSelected: () => setState(() {
                        if (_priorita.contains(p)) {
                          _priorita.remove(p);
                        } else {
                          _priorita.add(p);
                        }
                      }),
                    )),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Pulsante applica
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.provider.setFiltroStato(_stato);
                widget.provider.setFiltroPriorita(_priorita);
                widget.provider.setOrdinamento(_sortBy, _sortAscending);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Applica filtri'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}
