import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/corso.dart';
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

  int _arrotondaVoto(double voto) {
    final roundedDec = double.parse(voto.toStringAsFixed(2));
    final intero = roundedDec.floor();
    final decimale = roundedDec - intero;
    return decimale > 0.5 ? (intero + 1) : intero;
  }

  String _generaAcronimo(String nome) {
    if (nome.trim().isEmpty) return '';
    final parole = nome.trim().split(RegExp(r'\s+'));
    return parole.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join('');
  }

  double _calcolaMediaPonderata(List<Corso> corsi, EsameProvider esameProv) {
    final corsiSuperati = corsi.where((c) => c.stato == 'superato').toList();
    if (corsiSuperati.isEmpty) return 0.0;

    double sommaProdotti = 0.0;
    int sommaCfu = 0;

    for (final corso in corsiSuperati) {
      final votoCalcolato = esameProv.calcolaVotoCorso(corso.id);
      if (votoCalcolato <= 0) continue;

      int votoCorso = _arrotondaVoto(votoCalcolato);
      if (corso.lode) {
        votoCorso = 31;
      }

      sommaProdotti += votoCorso * corso.cfu;
      sommaCfu += corso.cfu;
    }

    if (sommaCfu == 0) return 0.0;
    return sommaProdotti / sommaCfu;
  }

  DateTime _getCompletionDate(Corso corso, EsameProvider esameProv) {
    final esamiCorso = esameProv.getEsamiCorso(corso.id)
        .where((e) => e.stato == 'completato')
        .toList();
    if (esamiCorso.isEmpty) return corso.createdAt;
    return esamiCorso.map((e) => e.data).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  List<Map<String, dynamic>> _preparaDatiGrafico(List<Corso> corsi, EsameProvider esameProv) {
    final corsiSuperati = corsi.where((c) => c.stato == 'superato').toList();
    if (corsiSuperati.isEmpty) return [];

    final list = corsiSuperati.map((corso) {
      final dataCompletamento = _getCompletionDate(corso, esameProv);
      final votoCalcolato = esameProv.calcolaVotoCorso(corso.id);
      int votoCorso = _arrotondaVoto(votoCalcolato);
      if (corso.lode) {
        votoCorso = 31;
      }
      return {
        'corso': corso,
        'data': dataCompletamento,
        'voto': votoCorso,
      };
    }).toList();

    list.sort((a, b) => (a['data'] as DateTime).compareTo(b['data'] as DateTime));

    final List<Map<String, dynamic>> result = [];
    double sommaProdotti = 0.0;
    int sommaCfu = 0;

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      final c = item['corso'] as Corso;
      final voto = item['voto'] as int;

      sommaProdotti += voto * c.cfu;
      sommaCfu += c.cfu;
      final media = sommaProdotti / sommaCfu;

      result.add({
        'index': (i + 1).toDouble(),
        'corsoNome': c.nome,
        'votoCorso': voto,
        'cfu': c.cfu,
        'lode': c.lode,
        'media': media,
      });
    }

    return result;
  }

  Widget _buildAndamentoChart(BuildContext context, ThemeData theme, List<Map<String, dynamic>> dataPoints) {
    if (dataPoints.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(Icons.show_chart, size: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              "Nessun esame completato per tracciare l'andamento",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final double minY = 18.0;
    final double maxY = 31.0;

    final spots = dataPoints.map((dp) {
      return FlSpot(dp['index'] as double, dp['media'] as double);
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 1.0,
                maxX: dataPoints.length == 1 ? 2.0 : dataPoints.length.toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt() - 1;
                        if (idx >= 0 && idx < dataPoints.length) {
                          if (dataPoints.length > 6 && (idx % (dataPoints.length / 5).ceil() != 0) && idx != dataPoints.length - 1) {
                            return const SizedBox.shrink();
                          }
                          final cNome = dataPoints[idx]['corsoNome'] as String;
                          final label = _generaAcronimo(cNome);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        if (value >= 18 && value <= 30) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => theme.colorScheme.surfaceContainerHigh,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final data = dataPoints[spot.x.toInt() - 1];
                        final cNome = data['corsoNome'] as String;
                        final voto = data['votoCorso'] as int;
                        final cfu = data['cfu'] as int;
                        final lode = data['lode'] as bool;
                        final media = data['media'] as double;
                        final votoStr = lode ? '30L' : (voto == 31 ? '30L' : '$voto');
                        return LineTooltipItem(
                          '$cNome\nEsame: $votoStr ($cfu CFU)\nMedia: ${media.toStringAsFixed(2)}',
                          theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: dataPoints.length > 1,
                    curveSmoothness: 0.3,
                    gradient: const LinearGradient(
                      colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.amber,
                        Colors.green,
                        Colors.blue,
                        Colors.indigo,
                        Colors.purple,
                      ],
                    ),
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5.5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: theme.colorScheme.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: dataPoints.length > 1,
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withValues(alpha: 0.35),
                          Colors.orange.withValues(alpha: 0.35),
                          Colors.amber.withValues(alpha: 0.35),
                          Colors.green.withValues(alpha: 0.35),
                          Colors.blue.withValues(alpha: 0.35),
                          Colors.indigo.withValues(alpha: 0.35),
                          Colors.purple.withValues(alpha: 0.35),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo e Statistiche'), centerTitle: false),
      body: Consumer3<CorsoProvider, EsameProvider, ObiettivoProvider>(
        builder: (context, corsoProv, esameProv, obiProv, _) {
          final totCorsi = corsoProv.tuttiCorsi.length;
          final esamiSuperati = esameProv.esamiSuperati.length;
          final totEsami = esameProv.esami.length;
          final obiRaggiunti = obiProv.raggiunti;
          final totObiettivi = obiProv.tuttiObiettivi.length;

          // Calcola medie separate per Triennale e Magistrale (media ponderata dei voti dei corsi)
          final corsiTriennale = corsoProv.tuttiCorsi
              .where((c) => c.tipoLaurea == 'triennale')
              .toList();
          final corsiMagistrale = corsoProv.tuttiCorsi
              .where((c) => c.tipoLaurea == 'magistrale')
              .toList();

          final mediaTriennale = _calcolaMediaPonderata(corsiTriennale, esameProv);
          final mediaMagistrale = _calcolaMediaPonderata(corsiMagistrale, esameProv);

          final corsiSelezionati = _selectedLaurea == 'triennale' ? corsiTriennale : corsiMagistrale;
          final dataPoints = _preparaDatiGrafico(corsiSelezionati, esameProv);

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

              // Grafico dell'Andamento
              Text("Grafico dell'Andamento", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildAndamentoChart(context, theme, dataPoints),
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
