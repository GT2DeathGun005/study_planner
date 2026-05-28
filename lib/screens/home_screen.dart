import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/corso_provider.dart';
import '../providers/esame_provider.dart';
import '../providers/obiettivo_provider.dart';
import 'esami/esami_screen.dart';
import 'obiettivi/obiettivi_screen.dart';
import 'calendario/calendario_screen.dart';
import 'profilo/profilo_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    EsamiScreen(),
    ObiettiviScreen(),
    CalendarioScreen(),
    ProfiloScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          _reloadProviders();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Corsi',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Obiettivi',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }


  void _reloadProviders() {
    context.read<CorsoProvider>().loadCorsi();
    context.read<EsameProvider>().loadEsami();
    context.read<ObiettivoProvider>().loadObiettivi();
  }
}
