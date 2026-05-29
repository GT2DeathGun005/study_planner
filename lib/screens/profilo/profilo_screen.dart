import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/obiettivo.dart';
import '../../providers/attivita_provider.dart';
import '../../providers/corso_provider.dart';
import '../../providers/esame_provider.dart';
import '../../providers/obiettivo_provider.dart';
import '../../widgets/stat_card.dart';

/// Schermata Profilo/Analytics.
///
/// Dashboard con KPI, grafici, medie separate per Triennale/Magistrale,
/// statistiche pomodori per tipologia e scadenze imminenti.
class ProfiloScreen extends StatefulWidget {
  const ProfiloScreen({super.key});
  @override
  State<ProfiloScreen> createState() => _ProfiloScreenState();
}

class _ProfiloScreenState extends State<ProfiloScreen> {
  String _selectedLaurea = 'triennale';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CorsoProvider>().loadCorsi();
      context.read<EsameProvider>().loadEsami();
      context.read<ObiettivoProvider>().loadObiettivi();
      context.read<AttivitaProvider>().loadTutteAttivita();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd MMM', 'it_IT');

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo e Statistiche'), centerTitle: false),
      body: Consumer3<CorsoProvider, EsameProvider, ObiettivoProvider>(
        builder: (context, corsoProv, esameProv, obiProv, _) {
          final totCorsi = corsoProv.tuttiCorsi.length;
          final esamiSuperati = esameProv.esamiSuperati.length;
          final totEsami = esameProv.esami.length;
          final obiRaggiunti = obiProv.raggiunti;
          final totObiettivi = obiProv.tuttiObiettivi.length;
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
                  // Card con tendina per Media Triennale / Magistrale
                  Builder(
                    builder: (context) {
                      final selectedColor = _selectedLaurea == 'triennale'
                          ? Colors.indigo
                          : Colors.purple.shade300;
                      final mediaValue = _selectedLaurea == 'triennale'
                          ? mediaTriennale
                          : mediaMagistrale;
                      final valueStr = mediaValue > 0
                          ? mediaValue.toStringAsFixed(1)
                          : '-';

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: selectedColor.withValues(alpha: 0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedLaurea = _selectedLaurea == 'triennale' ? 'magistrale' : 'triennale';
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _selectedLaurea == 'triennale'
                                        ? Icons.looks_one
                                        : Icons.looks_two,
                                    color: selectedColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                valueStr,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedLaurea == 'triennale'
                                    ? 'Media Triennale'
                                    : 'Media Magistrale',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  StatCard(icon: Icons.emoji_events, value: '$esamiSuperati/$totEsami', label: 'Esami superati', color: Colors.green),
                  StatCard(icon: Icons.flag, value: '$obiRaggiunti/$totObiettivi', label: 'Obiettivi raggiunti', color: Colors.purple),
                ],
              ),
              const SizedBox(height: 24),

              // Statistiche Studio (Pomodori)
              Text('Studio e Pomodori', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Consumer<AttivitaProvider>(
                builder: (context, attProv, _) {
                  final minutiTotali = attProv.minutiStudioTotali;
                  final datterino = attProv.totaleDatterino;
                  final sanMarzano = attProv.totaleSanMarzano;
                  final cuoreDiBue = attProv.totaleCuoreDiBue;
                  final pomodoroTotali = datterino + sanMarzano + cuoreDiBue;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.timer, color: theme.colorScheme.primary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Obiettivo.formatMinuti(minutiTotali),
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Tempo di studio',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('🍅', style: TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$pomodoroTotali',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Pomodori totali',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        // Pomodori per tipologia
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _PomodoroTypeStat(
                              label: 'Datterino',
                              subLabel: '25 min',
                              count: datterino,
                              color: Colors.red.shade400,
                            ),
                            _PomodoroTypeStat(
                              label: 'San Marzano',
                              subLabel: '50 min',
                              count: sanMarzano,
                              color: Colors.deepOrange,
                            ),
                            _PomodoroTypeStat(
                              label: 'Cuore di Bue',
                              subLabel: '100 min',
                              count: cuoreDiBue,
                              color: Colors.red.shade800,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

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
}

/// Statistica per singolo tipo di pomodoro.
class _PomodoroTypeStat extends StatelessWidget {
  final String label;
  final String subLabel;
  final int count;
  final Color color;

  const _PomodoroTypeStat({
    required this.label,
    required this.subLabel,
    required this.count,
    required this.color,
  });

  String get assetPath {
    switch (label) {
      case 'Datterino':
        return 'assets/Datterino.png';
      case 'San Marzano':
        return 'assets/San_Marzano.png';
      case 'Cuore di Bue':
        return 'assets/Cuore_di_Bue.png';
      default:
        return 'assets/Datterino.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(
            assetPath,
            width: 24,
            height: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        Text(
          subLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
