import 'package:flutter/material.dart';

import '../models/reto.dart';
import 'retos_repository.dart';

/// Datos de ejemplo del diseño, para la demo sin Supabase. Los reales salen
/// de `RetosRepositorySupabase`.
class RetosRepositoryMock implements RetosRepository {
  final List<Mision> _misiones = [
    const Mision(
      id: 'm1',
      titulo: 'Recicla 3 materiales distintos',
      detalle: 'Vidrio, papel, lata… lo que tengas a mano.',
      icono: Icons.layers_outlined,
      color: Color(0xFF1F7A72),
      actual: 3,
      meta: 3,
      puntos: 10,
    ),
    const Mision(
      id: 'm2',
      titulo: 'Escanea 5 objetos',
      detalle: 'Sirve cualquier envase de tu casa.',
      icono: Icons.qr_code_scanner,
      color: Color(0xFF0C872B),
      actual: 3,
      meta: 5,
      puntos: 10,
    ),
    const Mision(
      id: 'm3',
      titulo: 'Reporta el estado de 2 puntos',
      detalle: 'Solo cuenta si estás cerca del punto (GPS).',
      icono: Icons.flag_outlined,
      color: Color(0xFF2F6DB5),
      actual: 1,
      meta: 2,
      puntos: 6,
    ),
    const Mision(
      id: 'm4',
      titulo: 'Sugiere un punto en una zona sin ninguno',
      detalle: 'Ayúdanos a llenar el mapa donde no hay puntos.',
      icono: Icons.place_outlined,
      color: Color(0xFFE2B85C),
      actual: 0,
      meta: 1,
      puntos: 15,
      bonus: true,
    ),
    const Mision(
      id: 'm5',
      titulo: 'Califica un punto',
      detalle: 'Un toque y, si quieres, un comentario.',
      icono: Icons.star_outline,
      color: Color(0xFF7E5AA6),
      actual: 1,
      meta: 1,
      puntos: 4,
      reclamada: true,
    ),
  ];

  final List<Logro> _logros = [
    Logro(
      id: 'l1',
      nombre: 'Vidriero',
      descripcion: 'Recicla objetos de vidrio. Cada nivel pide más.',
      icono: Icons.wine_bar_outlined,
      color: Color(0xFF1F7A72),
      actual: 20,
      escalones: [
        EscalonLogro(10, 5),
        EscalonLogro(20, 10),
        EscalonLogro(50, 20),
      ],
      // Alcanzó el II y aún no lo reclama.
      nivelReclamado: 1,
    ),
    Logro(
      id: 'l2',
      nombre: 'Papelero',
      descripcion: 'Recicla papel y cartón.',
      icono: Icons.description_outlined,
      color: Color(0xFF2F6DB5),
      actual: 10,
      escalones: [
        EscalonLogro(10, 10),
        EscalonLogro(30, 15),
        EscalonLogro(60, 25),
      ],
      nivelReclamado: 1,
    ),
    Logro(
      id: 'l3',
      nombre: 'Racha de 7 días',
      descripcion: 'Recicla algo 7 días seguidos.',
      icono: Icons.local_fire_department_outlined,
      color: Color(0xFF0C872B),
      actual: 7,
      escalones: [EscalonLogro(7, 5), EscalonLogro(30, 20)],
      nivelReclamado: 1,
    ),
    Logro(
      id: 'l4',
      nombre: 'Guardián',
      descripcion: 'Reporta el estado de puntos cerca de ti.',
      icono: Icons.flag_outlined,
      color: Color(0xFF2F6DB5),
      actual: 7,
      escalones: [EscalonLogro(10, 10), EscalonLogro(30, 25)],
      nivelReclamado: 0,
    ),
    Logro(
      id: 'l5',
      nombre: 'Vecino',
      descripcion: 'Califica puntos de reciclaje.',
      icono: Icons.star_outline,
      color: Color(0xFF7E5AA6),
      actual: 4,
      escalones: [EscalonLogro(10, 8), EscalonLogro(30, 20)],
      nivelReclamado: 0,
    ),
  ];

  @override
  Future<Retos> retos() async =>
      Retos(misiones: List.of(_misiones), logros: List.of(_logros));

  @override
  Future<int> reclamarMision(String idMision) async {
    final i = _misiones.indexWhere((m) => m.id == idMision);
    if (i < 0 || !_misiones[i].lista) return 0;
    _misiones[i] = _misiones[i].copyWith(reclamada: true);
    return _misiones[i].puntos;
  }

  @override
  Future<int> reclamarLogro(String idLogro) async {
    final i = _logros.indexWhere((l) => l.id == idLogro);
    if (i < 0 || !_logros[i].reclamable) return 0;
    final puntos = _logros[i].puntosSiguiente;
    _logros[i] = _logros[i].copyWith(nivelReclamado: _logros[i].nivel + 1);
    return puntos;
  }
}
