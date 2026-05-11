import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/corso.dart';
import '../../providers/corso_provider.dart';
import '../../widgets/corso_card.dart';
import 'corso_form_screen.dart';
import 'corso_detail_screen.dart';

/// Schermata principale della sezione Esami.
///
/// Mostra la lista dei corsi con barra di ricerca, filtri per stato
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
          // Barra di ricerca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                          context.read<CorsoProvider>().setSearchQuery('');
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                context.read<CorsoProvider>().setSearchQuery(value);
                setState(() {}); // Aggiorna l'icona clear
              },
            ),
          ),

          // Filtri per stato
          SizedBox(
            height: 42,
            child: Consumer<CorsoProvider>(
              builder: (context, provider, _) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _FilterChip(
                      label: 'Tutti',
                      selected: provider.filtroStato == null,
                      onSelected: () => provider.setFiltroStato(null),
                    ),
                    ...Corso.statiDisponibili.map(
                      (stato) => _FilterChip(
                        label: Corso.statoLabel(stato),
                        selected: provider.filtroStato == stato,
                        onSelected: () => provider.setFiltroStato(stato),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 8),

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
                          'Aggiungi il tuo primo corso!',
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
                    return CorsoCard(
                      corso: corso,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
