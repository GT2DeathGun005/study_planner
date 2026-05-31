import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/corso.dart';
import '../../providers/corso_provider.dart';
import '../../providers/esame_provider.dart';
import '../../providers/obiettivo_provider.dart';
import '../../widgets/corso_card.dart';
import 'corso_form_screen.dart';
import 'corso_detail_screen.dart';

/// Schermata principale della sezione Corsi.
///
/// Mostra la lista dei corsi con barra di ricerca, bottone filtro avanzato
/// e FAB per aggiungere un nuovo corso.
class EsamiScreen extends StatefulWidget {
  const EsamiScreen({super.key});

  @override
  State<EsamiScreen> createState() => _EsamiScreenState();
}

class _EsamiScreenState extends State<EsamiScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carica i corsi al primo avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CorsoProvider>().loadCorsi();
      context.read<EsameProvider>().loadEsami();
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
        title: const Text('I miei Corsi'),
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
                      hintText: 'Cerca corso...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<CorsoProvider>()
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
                      context.read<CorsoProvider>().setSearchQuery(value);
                      setState(() {}); // Aggiorna l'icona clear
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Bottone filtro
                Consumer<CorsoProvider>(
                  builder: (context, provider, _) {
                    final filtriAttivi = provider.filtriAttiviCount;
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

          // Lista corsi
          Expanded(
            child: Consumer<CorsoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final corsi = provider.corsi;
                if (corsi.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Nessun corso trovato',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.filtriAttiviCount > 0
                              ? 'Prova a modificare i filtri'
                              : 'Aggiungi il tuo primo corso!',
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
                  itemCount: corsi.length,
                  itemBuilder: (context, index) {
                    final corso = corsi[index];
                    final esameProv = context.read<EsameProvider>();
                    final votoCalc = corso.stato == 'superato'
                        ? esameProv.calcolaVotoCorso(corso.id)
                        : null;
                    return CorsoCard(
                      corso: corso,
                      votoCalcolato: votoCalc,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CorsoDetailScreen(corsoId: corso.id),
                          ),
                        );
                      },
                      onDelete: () => _confirmDelete(context, corso),
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
            MaterialPageRoute(builder: (_) => const CorsoFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Corso'),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, CorsoProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterBottomSheet(provider: provider),
    );
  }

  void _confirmDelete(BuildContext context, Corso corso) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina corso'),
        content: Text('Vuoi eliminare "${corso.nome}"?\n'
            'Tutti gli esami associati verranno eliminati.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              final esameProv = context.read<EsameProvider>();
              final obiProv = context.read<ObiettivoProvider>();

              // 1. Elimina obiettivi associati al corso
              obiProv.deleteObiettiviByCorso(corso.id);

              // 2. Per ogni esame del corso, elimina l'esame
              final esamiCorso = esameProv.getEsamiCorso(corso.id);
              for (final esame in esamiCorso) {
                esameProv.deleteEsame(esame.id);
              }

              // 3. Elimina il corso
              context.read<CorsoProvider>().deleteCorso(corso.id);
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

/// Bottom sheet per i filtri avanzati dei corsi.
class _FilterBottomSheet extends StatefulWidget {
  final CorsoProvider provider;

  const _FilterBottomSheet({required this.provider});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late List<String> _stato;
  late List<int> _semestre;
  late List<String> _tipoLaurea;
  late List<int> _anno;
  late RangeValues _cfuRange;
  late bool _cfuFilterActive;
  bool _isSortMode = false;
  late String _sortBy;
  late bool _sortAscending;

  @override
  void initState() {
    super.initState();
    _stato = List.from(widget.provider.filtroStato);
    _semestre = List.from(widget.provider.filtroSemestre);
    _tipoLaurea = List.from(widget.provider.filtroTipoLaurea);
    _anno = List.from(widget.provider.filtroAnno);
    _sortBy = widget.provider.sortBy;
    _sortAscending = widget.provider.sortAscending;
    final cfuMin = widget.provider.filtroCfuMin;
    final cfuMax = widget.provider.filtroCfuMax;
    _cfuFilterActive = cfuMin != null || cfuMax != null;
    _cfuRange = RangeValues(
      (cfuMin ?? 1).toDouble(),
      (cfuMax ?? 30).toDouble(),
    );
  }

  void _syncAnniFiltro() {
    if (_tipoLaurea.isNotEmpty && _anno.isNotEmpty) {
      final allAnniValidi =
          _tipoLaurea.expand((tl) => Corso.anniPerTipo(tl)).toSet();
      _anno.removeWhere((a) => !allAnniValidi.contains(a));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                      ' Corsi',
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
                      _semestre = [];
                      _tipoLaurea = [];
                      _anno = [];
                      _cfuFilterActive = false;
                      _cfuRange = const RangeValues(1, 30);
                    }
                  });
                },
                child: const Text('Resetta'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isSortMode) ...[
            Text('Ordina per',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
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
                  label: 'Anno e Semestre',
                  selected: _sortBy == 'anno_semestre',
                  onSelected: () => setState(() => _sortBy =
                      _sortBy == 'anno_semestre' ? 'default' : 'anno_semestre'),
                ),
                _buildFilterChip(
                  label: 'Stato',
                  selected: _sortBy == 'stato',
                  onSelected: () => setState(() =>
                      _sortBy = _sortBy == 'stato' ? 'default' : 'stato'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Direzione',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
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
            // Stato
            Text('Stato',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...Corso.statiDisponibili.map(
                  (stato) => _buildFilterChip(
                    label: Corso.statoLabel(stato),
                    selected: _stato.contains(stato),
                    onSelected: () => setState(() {
                      if (_stato.contains(stato)) {
                        _stato.remove(stato);
                      } else {
                        _stato.add(stato);
                      }
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Semestre
            Text('Semestre',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(
                  label: '1° Semestre',
                  selected: _semestre.contains(1),
                  onSelected: () => setState(() {
                    if (_semestre.contains(1)) {
                      _semestre.remove(1);
                    } else {
                      _semestre.add(1);
                    }
                  }),
                ),
                _buildFilterChip(
                  label: '2° Semestre',
                  selected: _semestre.contains(2),
                  onSelected: () => setState(() {
                    if (_semestre.contains(2)) {
                      _semestre.remove(2);
                    } else {
                      _semestre.add(2);
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tipo Laurea
            Text('Tipo Laurea',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildFilterChip(
                  label: 'Triennale',
                  selected: _tipoLaurea.contains('triennale'),
                  onSelected: () => setState(() {
                    if (_tipoLaurea.contains('triennale')) {
                      _tipoLaurea.remove('triennale');
                    } else {
                      _tipoLaurea.add('triennale');
                    }
                    _syncAnniFiltro();
                  }),
                ),
                _buildFilterChip(
                  label: 'Magistrale',
                  selected: _tipoLaurea.contains('magistrale'),
                  onSelected: () => setState(() {
                    if (_tipoLaurea.contains('magistrale')) {
                      _tipoLaurea.remove('magistrale');
                    } else {
                      _tipoLaurea.add('magistrale');
                    }
                    _syncAnniFiltro();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Anno
            Text('Anno',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (_tipoLaurea.isNotEmpty)
                  ..._tipoLaurea
                      .expand((tl) => Corso.anniPerTipo(tl))
                      .toSet()
                      .map(
                        (a) => _buildFilterChip(
                          label: '$a° Anno',
                          selected: _anno.contains(a),
                          onSelected: () => setState(() {
                            if (_anno.contains(a)) {
                              _anno.remove(a);
                            } else {
                              _anno.add(a);
                            }
                          }),
                        ),
                      )
                else
                  ...[1, 2, 3].map(
                    (a) => _buildFilterChip(
                      label: '$a° Anno',
                      selected: _anno.contains(a),
                      onSelected: () => setState(() {
                        if (_anno.contains(a)) {
                          _anno.remove(a);
                        } else {
                          _anno.add(a);
                        }
                      }),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // CFU
            Row(
              children: [
                Text('CFU',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Switch(
                  value: _cfuFilterActive,
                  onChanged: (v) => setState(() => _cfuFilterActive = v),
                ),
                if (_cfuFilterActive)
                  Text(
                    '${_cfuRange.start.round()} – ${_cfuRange.end.round()}',
                    style: theme.textTheme.bodyMedium,
                  ),
              ],
            ),
            if (_cfuFilterActive)
              RangeSlider(
                values: _cfuRange,
                min: 1,
                max: 30,
                divisions: 29,
                labels: RangeLabels(
                  '${_cfuRange.start.round()}',
                  '${_cfuRange.end.round()}',
                ),
                onChanged: (values) => setState(() => _cfuRange = values),
              ),
            const SizedBox(height: 24),
          ],

          // Pulsante applica
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _applyFilters,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Applica filtri'),
            ),
          ),
          const SizedBox(height: 8),
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

  void _applyFilters() {
    final provider = widget.provider;
    provider.setFiltroStato(_stato);
    provider.setFiltroSemestre(_semestre);
    provider.setFiltroTipoLaurea(_tipoLaurea);
    provider.setFiltroAnno(_anno);
    if (_cfuFilterActive) {
      provider.setFiltroCfu(
        min: _cfuRange.start.round(),
        max: _cfuRange.end.round(),
      );
    } else {
      provider.setFiltroCfu(min: null, max: null);
    }
    provider.setOrdinamento(_sortBy, _sortAscending);
    Navigator.pop(context);
  }
}
