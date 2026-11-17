import 'package:flutter/foundation.dart';

import '../models/reto.dart';
import 'gamificacion_repository.dart';
import 'retos_repository.dart';

/// Lo que la persona puede cobrar ahora: niveles de logro alcanzados,
/// misiones listas y la sorpresa de hoy. Junta lo que ya calcula la base; la
/// app no decide qué se puede reclamar.
class ParaReclamar {
  final Retos retos;
  final SorpresaHoy sorpresa;

  const ParaReclamar({required this.retos, required this.sorpresa});

  List<Logro> get logros => [
    for (final l in retos.logros)
      if (l.reclamable) l,
  ];

  List<Mision> get misiones => [
    for (final m in retos.misiones)
      if (m.lista) m,
  ];

  /// Cuántas cosas hay para reclamar (la sorpresa cuenta si no se ha abierto).
  int get total =>
      logros.length + misiones.length + (sorpresa.porAbrir ? 1 : 0);

  /// Lee retos y sorpresa. Si la sorpresa falla, se omite: no debe impedir
  /// reclamar lo demás.
  static Future<ParaReclamar> cargar(
    RetosRepository retos,
    GamificacionRepository gamificacion,
  ) async {
    final (r, s) = await (retos.retos(), _sorpresa(gamificacion)).wait;
    return ParaReclamar(retos: r, sorpresa: s);
  }

  static Future<SorpresaHoy> _sorpresa(GamificacionRepository g) async {
    try {
      return await g.sorpresaHoy();
    } catch (e) {
      debugPrint('ParaReclamar: no se pudo leer la sorpresa de hoy ($e)');
      return const SorpresaHoy(disponible: false, abierta: false, puntos: 0);
    }
  }
}
