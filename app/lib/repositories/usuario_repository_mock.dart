import '../models/movimiento_punto.dart';
import '../models/usuario.dart';
import 'usuario_repository.dart';

/// Usuario de ejemplo para demos sin Supabase configurado y para tests.
// puntosTotales=158 (banda "Pro" según los umbrales de Nivel) para que el
// nivel mostrado y la barra de progreso sean consistentes con el sistema de
// puntos del proyecto.
// Viene con nombre ya completo para que la demo no pase por la bienvenida.
class UsuarioRepositoryMock implements UsuarioRepository {
  String _nombre = 'Usuario Rebin';
  String _alias = 'rebin';

  @override
  Future<Usuario> guardarDatos({
    required String nombre,
    required String alias,
  }) async {
    _nombre = nombre;
    _alias = alias;
    return obtenerOCrear();
  }

  @override
  Future<Usuario> obtenerOCrear() async {
    return Usuario(
      id: 'mock',
      nombre: _nombre,
      alias: _alias,
      fechaRegistro: DateTime(2026, 3, 1),
      puntosTotales: 158,
      objetosEscaneados: 47,
      reportesHechos: 9,
      logrosObtenidos: 2,
      movimientos: [
        MovimientoPunto(
          tipo: 'deposito',
          cantidad: 5,
          fecha: DateTime(2026, 9, 30, 18),
        ),
        MovimientoPunto(
          tipo: 'reporte',
          cantidad: 3,
          fecha: DateTime(2026, 9, 29, 12),
        ),
        MovimientoPunto(
          tipo: 'valoracion',
          cantidad: 2,
          fecha: DateTime(2026, 9, 28, 9),
        ),
      ],
    );
  }
}
