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
                        tooltip: 'Filtra corsi',
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
                    final votoCalc = esameProv.calcolaVotoCorso(corso.id);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CorsoFormScreen()),
          );
        },
        child: const Icon(Icons.add),
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

              // 2. Per ogni esame del corso, elimina i suoi obiettivi e poi l'esame
              final esamiCorso = esameProv.getEsamiCorso(corso.id);
              for (final esame in esamiCorso) {
                obiProv.deleteObiettiviByEsame(esame.id);
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
  late String? _stato;
  late int? _semestre;
  late String? _tipoLaurea;
  late int? _anno;
  late RangeValues _cfuRange;
  late bool _cfuFilterActive;

  @override
  void initState() {
    super.initState();
    _stato = widget.provider.filtroStato;
    _semestre = widget.provider.filtroSemestre;
    _tipoLaurea = widget.provider.filtroTipoLaurea;
    _anno = widget.provider.filtroAnno;
    final cfuMin = widget.provider.filtroCfuMin;
    final cfuMax = widget.provider.filtroCfuMax;
    _cfuFilterActive = cfuMin != null || cfuMax != null;
    _cfuRange = RangeValues(
      (cfuMin ?? 1).toDouble(),
      (cfuMax ?? 30).toDouble(),
    );
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
              Text('Filtra Corsi',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _stato = null;
                    _semestre = null;
                    _tipoLaurea = null;
                    _anno = null;
                    _cfuFilterActive = false;
                    _cfuRange = const RangeValues(1, 30);
                  });
                },
                child: const Text('Resetta'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stato
          Text('Stato',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildFilterChip(
                label: 'Tutti',
                selected: _stato == null,
                onSelected: () => setState(() => _stato = null),
              ),
              ...Corso.statiDisponibili.map(
                (stato) => _buildFilterChip(
                  label: Corso.statoLabel(stato),
                  selected: _stato == stato,
                  onSelected: () => setState(() => _stato = stato),
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
                label: 'Tutti',
                selected: _semestre == null,
                onSelected: () => setState(() => _semestre = null),
              ),
              _buildFilterChip(
                label: '1° Semestre',
                selected: _semestre == 1,
                onSelected: () => setState(() => _semestre = 1),
              ),
              _buildFilterChip(
                label: '2° Semestre',
                selected: _semestre == 2,
                onSelected: () => setState(() => _semestre = 2),
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
                label: 'Tutti',
                selected: _tipoLaurea == null,
                onSelected: () => setState(() {
                  _tipoLaurea = null;
                  _anno = null;
                }),
              ),
              _buildFilterChip(
                label: 'Triennale',
                selected: _tipoLaurea == 'triennale',
                onSelected: () => setState(() {
                  _tipoLaurea = 'triennale';
                  if (_anno != null && _anno! > 3) _anno = null;
                }),
              ),
              _buildFilterChip(
                label: 'Magistrale',
                selected: _tipoLaurea == 'magistrale',
                onSelected: () => setState(() {
                  _tipoLaurea = 'magistrale';
                  if (_anno != null && _anno! > 2) _anno = null;
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
              _buildFilterChip(
                label: 'Tutti',
                selected: _anno == null,
                onSelected: () => setState(() => _anno = null),
              ),
              if (_tipoLaurea != null)
                ...Corso.anniPerTipo(_tipoLaurea!).map(
                  (a) => _buildFilterChip(
                    label: '$a° Anno',
                    selected: _anno == a,
                    onSelected: () => setState(() => _anno = a),
                  ),
                )
              else
                ...[1, 2, 3].map(
                  (a) => _buildFilterChip(
                    label: '$a° Anno',
                    selected: _anno == a,
                    onSelected: () => setState(() => _anno = a),
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
              onChanged: (values) =>
                  setState(() => _cfuRange = values),
            ),
          const SizedBox(height: 24),

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
    Navigator.pop(context);
  }
}
