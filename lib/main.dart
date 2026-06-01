import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/attivita_provider.dart';
import 'providers/corso_provider.dart';
import 'providers/esame_provider.dart';
import 'providers/obiettivo_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';


/// Entry point dell'applicazione Pantone Planner.
///
/// Inizializza il database SQLite (con FFI su desktop),
/// configura i Provider e avvia l'app con tema Material 3.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza sqflite FFI solo su piattaforme desktop (Windows/Linux/macOS).
  // Su Android/iOS sqflite funziona nativamente senza FFI.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inizializza il database SQLite
  await DatabaseHelper.instance.database;

  // Inizializza le date in italiano per intl/table_calendar
  await initializeDateFormatting('it_IT', null);

  runApp(const PantonePlannerApp());
}

class PantonePlannerApp extends StatelessWidget {
  const PantonePlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CorsoProvider()),
        ChangeNotifierProvider(create: (_) => EsameProvider()),
        ChangeNotifierProvider(create: (_) => ObiettivoProvider()),
        ChangeNotifierProvider(create: (_) => AttivitaProvider()),
      ],
      child: MaterialApp(
        title: 'Pantone Planner',
        debugShowCheckedModeBanner: false,
        // Localizzazione in italiano
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('it', 'IT'),
          Locale('en', 'US'),
        ],
        locale: const Locale('it', 'IT'),
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
