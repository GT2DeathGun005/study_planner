import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/corso_provider.dart';
import '../../providers/esame_provider.dart';
import '../../providers/obiettivo_provider.dart';
import '../obiettivi/obiettivo_form_screen.dart';

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
    final df = DateFormat('dd MMM yyyy', 'it_IT');

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario'), centerTitle: false),
      body: Consumer3<ObiettivoProvider, EsameProvider, CorsoProvider>(
        builder: (context, obiProv, esameProv, corsoProv, _) {
          final obiettiviGiorno = obiProv.getObiettiviByDate(_selectedDay);
          final esamiGiorno = esameProv.getEsamiByDate(_selectedDay);

          return Column(
            children: [
              // Calendario
              TableCalendar(
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
                calendarStyle: CalendarStyle(
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
                ),
              ),

              const Divider(height: 1),

              // Header giorno selezionato
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(df.format(_selectedDay),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${obiettiviGiorno.length + esamiGiorno.length} elementi',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),

              // Lista attività del giorno
              Expanded(
                child: (obiettiviGiorno.isEmpty && esamiGiorno.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                            const SizedBox(height: 8),
                            Text('Nessuna attività per questo giorno',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 80),
                        children: [
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
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('Esame', style: theme.textTheme.labelSmall?.copyWith(color: Colors.red)),
                              ),
                            );
                          }),
                          // Obiettivi del giorno
                          ...obiettiviGiorno.map((obi) {
                            final corso = obi.corsoId != null ? corsoProv.getCorsoById(obi.corsoId!) : null;
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: obi.completato ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  obi.completato ? Icons.check_circle : Icons.flag,
                                  color: obi.completato ? Colors.green : Colors.blue,
                                  size: 20,
                                ),
                              ),
                              title: Text(obi.titolo, style: TextStyle(decoration: obi.completato ? TextDecoration.lineThrough : null)),
                              subtitle: Text(corso?.nome ?? obi.descrizione),
                              trailing: Text(obi.tempoStimato > 0 ? '${obi.tempoStimato}m' : '', style: theme.textTheme.bodySmall),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ObiettivoFormScreen(obiettivo: obi)));
                              },
                            );
                          }),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ObiettivoFormScreen(dataPianificata: _selectedDay)));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
