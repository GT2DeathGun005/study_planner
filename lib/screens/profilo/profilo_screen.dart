import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/obiettivo.dart';
import '../../providers/corso_provider.dart';
import '../../providers/esame_provider.dart';
import '../../providers/obiettivo_provider.dart';
import '../../widgets/stat_card.dart';

/// Schermata Profilo/Analytics.
///
/// Dashboard con KPI, grafici, medie separate per Triennale/Magistrale,
/// e scadenze imminenti.
class ProfiloScreen extends StatefulWidget {
  const ProfiloScreen({super.key});
  @override
  State<ProfiloScreen> createState() => _ProfiloScreenState();
}

class _ProfiloScreenState extends State<ProfiloScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CorsoProvider>().loadCorsi();
      context.read<EsameProvider>().loadEsami();
      context.read<ObiettivoProvider>().loadObiettivi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd MMM', 'it_IT');

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo & Statistiche'), centerTitle: false),
      body: Consumer3<CorsoProvider, EsameProvider, ObiettivoProvider>(
        builder: (context, corsoProv, esameProv, obiProv, _) {
          final totCorsi = corsoProv.tuttiCorsi.length;
          final esamiSuperati = esameProv.esamiSuperati.length;
          final totEsami = esameProv.esami.length;
          final taskCompletati = obiProv.completati;
          final totTask = obiProv.tuttiObiettivi.length;
          final tempoEffettivo = obiProv.totaleTempoEffettivo;
          final tempoStimato = obiProv.totaleTempoStimato;
          final tempoPerCorso = obiProv.tempoPerCorso;
          final scadenze = esameProv.scadenzeImminenti;

          // Calcola medie separate per Triennale e Magistrale
          final corsiTriennale = corsoProv.tuttiCorsi
              .where((c) => c.tipoLaurea == 'triennale')
              .toList();
          final corsiMagistrale = corsoProv.tuttiCorsi
              .where((c) => c.tipoLaurea == 'magistrale')
              .toList();
          final idsTriennale = corsiTriennale.map((c) => c.id).toList();
          final idsMagistrale = corsiMagistrale.map((c) => c.id).toList();
          final mediaTriennale =
              esameProv.mediaVotiPerTipoLaurea('triennale', idsTriennale);
          final mediaMagistrale =
              esameProv.mediaVotiPerTipoLaurea('magistrale', idsMagistrale);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // KPI Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.15,
                children: [
                  StatCard(icon: Icons.school, value: '$totCorsi', label: 'Corsi totali', color: Colors.blue),
                  StatCard(
                    icon: Icons.grade,
                    value: esameProv.mediaVoti > 0
                        ? esameProv.mediaVoti.toStringAsFixed(1)
                        : '-',
                    label: 'Media generale',
                    color: Colors.amber,
                  ),
                  StatCard(icon: Icons.emoji_events, value: '$esamiSuperati/$totEsami', label: 'Esami superati', color: Colors.green),
                  StatCard(icon: Icons.check_circle, value: '$taskCompletati/$totTask', label: 'Task completati', color: Colors.purple),
                ],
              ),
              const SizedBox(height: 24),

              // Medie per tipo di laurea
              Text('Medie per Tipo di Laurea',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MediaCard(
                      title: 'Triennale',
                      icon: Icons.school,
                      media: mediaTriennale,
                      corsiCount: corsiTriennale.length,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MediaCard(
                      title: 'Magistrale',
                      icon: Icons.workspace_premium,
                      media: mediaMagistrale,
                      corsiCount: corsiMagistrale.length,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ore studio: effettive vs pianificate
              Text('Ore di Studio', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _LegendItem(color: theme.colorScheme.primary, label: 'Effettive: ${Obiettivo.formatMinuti(tempoEffettivo)}'),
                      _LegendItem(color: Colors.orange, label: 'Pianificate: ${Obiettivo.formatMinuti(tempoStimato)}'),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 30,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: tempoStimato > 0 ? (tempoEffettivo / tempoStimato).clamp(0.0, 1.0) : 0,
                          backgroundColor: Colors.orange.withValues(alpha: 0.3),
                          color: theme.colorScheme.primary,
                          minHeight: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Distribuzione tempo per corso (Pie chart)
              if (tempoPerCorso.isNotEmpty) ...[
                Text('Distribuzione per Corso', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildPieChart(tempoPerCorso, corsoProv, theme),
                ),
                const SizedBox(height: 24),
              ],

              // Scadenze imminenti
              Text('Scadenze Imminenti', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (scadenze.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Nessuna scadenza nei prossimi 7 giorni 🎉',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      textAlign: TextAlign.center),
                )
              else
                ...scadenze.map((esame) {
                  final corso = corsoProv.getCorsoById(esame.corsoId);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.withValues(alpha: 0.2))),
                    child: ListTile(
                      leading: const Icon(Icons.alarm, color: Colors.red),
                      title: Text(esame.titolo),
                      subtitle: Text(corso?.nome ?? ''),
                      trailing: Text(df.format(esame.data), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.red)),
                    ),
                  );
                }),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> tempoPerCorso, CorsoProvider corsoProv, ThemeData theme) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.pink, Colors.amber];
    final entries = tempoPerCorso.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                final pct = total > 0 ? (entry.value / total * 100) : 0.0;
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  color: colors[idx % colors.length],
                  title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  radius: 60,
                );
              }).toList(),
              centerSpaceRadius: 20,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((e) {
            final idx = e.key;
            final entry = e.value;
            final corso = corsoProv.getCorsoById(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[idx % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 100,
                  child: Text(corso?.nome ?? '?', style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Card per mostrare la media voti di un tipo di laurea.
class _MediaCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double media;
  final int corsiCount;
  final Color color;

  const _MediaCard({
    required this.title,
    required this.icon,
    required this.media,
    required this.corsiCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              media > 0 ? media.toStringAsFixed(1) : '—',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$corsiCount cors${corsiCount == 1 ? 'o' : 'i'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
