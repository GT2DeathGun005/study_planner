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
  late final PageController _pageController;

  final List<Widget> _screens = const [
    EsamiScreen(),
    ObiettiviScreen(),
    CalendarioScreen(),
    ProfiloScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _reloadProviders();
        },
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Corsi',
            tooltip: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Obiettivi',
            tooltip: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
            tooltip: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Profilo',
            tooltip: '',
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
