import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/corso_provider.dart';
import 'providers/esame_provider.dart';
import 'providers/obiettivo_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';

/// Entry point dell'applicazione Study Planner & Exam Tracker.
///
/// Inizializza il database SQLite, configura i Provider per la gestione
/// dello stato e avvia l'app con un tema Material 3 moderno.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il database SQLite
  await DatabaseHelper.instance.database;

  // Inizializza le date in italiano per intl/table_calendar
  await initializeDateFormatting('it_IT', null);

  runApp(const StudyPlannerApp());
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CorsoProvider()),
        ChangeNotifierProvider(create: (_) => EsameProvider()),
        ChangeNotifierProvider(create: (_) => ObiettivoProvider()),
      ],
      child: MaterialApp(
        title: 'Study Planner',
        debugShowCheckedModeBanner: false,
        // Tema Material 3 con palette indigo/deep purple
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.light,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          cardTheme: CardThemeData(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.dark,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          cardTheme: CardThemeData(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
