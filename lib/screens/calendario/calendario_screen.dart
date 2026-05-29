import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/corso_provider.dart';
import '../../providers/esame_provider.dart';
import '../../providers/obiettivo_provider.dart';
import '../obiettivi/obiettivo_detail_screen.dart';
import '../esami/esame_form_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Schermata Calendario (Feature Avanzata 1).
///
/// Mostra un calendario mensile/settimanale con marker per task ed esami.
/// Tap su un giorno mostra le attività pianificate e le scadenze.
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});
  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObiettivoProvider>().loadObiettivi();
      context.read<EsameProvider>().loadEsami();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario'), centerTitle: false),
      body: Consumer3<ObiettivoProvider, EsameProvider, CorsoProvider>(
        builder: (context, obiProv, esameProv, corsoProv, _) {
          final obiettiviGiorno = obiProv.getObiettiviByDate(_selectedDay);
          final esamiGiorno = esameProv.getEsamiByDate(_selectedDay);

          // Formattazione data giorno selezionato con mese in maiuscolo (es: 28 Mag 2026)
          final dayStr = DateFormat('dd', 'it_IT').format(_selectedDay);
          final monthStr = DateFormat('MMM', 'it_IT').format(_selectedDay);
          final yearStr = DateFormat('yyyy', 'it_IT').format(_selectedDay);
          final capitalizedMonth = monthStr.isEmpty
              ? ''
              : (monthStr[0].toUpperCase() + monthStr.substring(1));
          final formattedDate = '$dayStr $capitalizedMonth $yearStr';

          final df = DateFormat('dd MMM', 'it_IT');
          final scadenze = esameProv.scadenzeImminenti;

          return Column(
            children: [
              // Calendario
              TableCalendar(
                locale: 'it_IT',
                startingDayOfWeek: StartingDayOfWeek.monday,
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focused) => _focusedDay = focused,
                eventLoader: (day) {
                  final obi = obiProv.getObiettiviByDate(day);
                  final esa = esameProv.getEsamiByDate(day);
                  return [...obi, ...esa];
                },
                daysOfWeekHeight: 28.0,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mese',
                  CalendarFormat.week: 'Settimana',
                },
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    final text = DateFormat.E('it_IT').format(day);
                    final formatted = text.replaceAll('.', '').toUpperCase();
                    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                    return Center(
                      child: Text(
                        formatted,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isWeekend ? Colors.red[400] : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox.shrink();
                    final eventList = events.take(3).toList();
                    return Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: eventList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final rainbowColors = [
                            Colors.purple,
                            Colors.red,
                            Colors.green,
                            Colors.blue,
                            Colors.amber,
                          ];
                          final color = rainbowColors[index % rainbowColors.length];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  cellMargin: const EdgeInsets.all(11.0),
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 6,
                  markersMaxCount: 3,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  titleTextFormatter: (date, locale) {
                    final formatted = DateFormat.yMMMM(locale).format(date);
                    if (formatted.isEmpty) return formatted;
                    return formatted[0].toUpperCase() + formatted.substring(1);
                  },
                ),
              ),

              const Divider(height: 1),

              // Lista attività del giorno + Scadenze imminenti in una unica area scrollabile
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    // Header giorno selezionato
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text(formattedDate,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${obiettiviGiorno.length + esamiGiorno.length} elementi',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                    if (obiettiviGiorno.isEmpty && esamiGiorno.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.event_available, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                            const SizedBox(height: 8),
                            Text('Nessuna attività per questo giorno',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      )
                    else ...[
                      // Esami del giorno
                      ...esamiGiorno.map((esame) {
                        final corso = corsoProv.getCorsoById(esame.corsoId);
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.quiz, color: Colors.red, size: 20),
                          ),
                          title: Text(esame.titolo),
                          subtitle: Text(corso?.nome ?? 'Corso non trovato'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EsameFormScreen(
                                  esame: esame,
                                  corsoId: esame.corsoId,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      // Obiettivi del giorno
                      ...obiettiviGiorno.map((obi) {
                        final corso = obi.corsoId != null ? corsoProv.getCorsoById(obi.corsoId!) : null;
                        final isRaggiunto = obi.stato == 'raggiunto';
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Symbols.file_map_stack,  color: Colors.amber[700], size: 20,),
                          ),
                          title: Text(obi.titolo, style: TextStyle(decoration: isRaggiunto ? TextDecoration.lineThrough : null)),
                          subtitle: Text(corso?.nome ?? (obi.descrizione != '' ? obi.descrizione : 'Nessuna descrizione')),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ObiettivoDetailScreen(obiettivo: obi)));
                          },
                        );
                      }),
                    ],

                    // Scadenze imminenti
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text('Scadenze Imminenti', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (scadenze.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text('Nessuna scadenza nei prossimi 7 giorni',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            textAlign: TextAlign.center),
                      )
                    else
                      ...scadenze.map((esame) {
                        final corso = corsoProv.getCorsoById(esame.corsoId);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.withValues(alpha: 0.2))),
                            child: ListTile(
                              leading: const Icon(Icons.alarm, color: Colors.red),
                              title: Text(esame.titolo),
                              subtitle: Text(corso?.nome ?? ''),
                              trailing: Text(df.format(esame.data), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.red)),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
