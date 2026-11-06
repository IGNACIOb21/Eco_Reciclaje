import 'package:flutter/material.dart';

import '../repositories/puntos_repository.dart';
import 'comunidad_screen.dart';
import 'escanear_placeholder_screen.dart';
import 'inicio_screen.dart';
import 'mapa_screen.dart';
import 'perfil_screen.dart';
import 'servicios_screen.dart';

/// Contenedor con la barra de navegación inferior (Inicio, Escanear, Mapa,
/// Comunidad, Servicios, Perfil) que arma la app real.
class MainShell extends StatefulWidget {
  // Solo para tests: inyecta un repositorio (ej. mock) en vez del Supabase
  // real que usa MapaScreen por defecto.
  final PuntosRepository? puntosRepository;

  const MainShell({super.key, this.puntosRepository});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0;

  void _irA(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      InicioScreen(onIrAMapa: () => _irA(2), onIrAEscanear: () => _irA(1)),
      const EscanearPlaceholderScreen(),
      MapaScreen(repositorio: widget.puntosRepository),
      const ComunidadScreen(),
      const ServiciosScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _indice, children: pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _irA,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Escanear',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Comunidad',
          ),
          NavigationDestination(
            icon: Icon(Icons.miscellaneous_services_outlined),
            selectedIcon: Icon(Icons.miscellaneous_services),
            label: 'Servicios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
