import 'package:flutter_test/flutter_test.dart';

import 'package:recircula/models/actividad_puntos.dart';
import 'package:recircula/models/movimiento_punto.dart';
import 'package:recircula/models/usuario.dart';

// Filas con los nombres de columna del esquema remoto real
// (docs/esquema-remoto.md del repo rebin). Si alguien cambia un nombre en el
// modelo y deja de coincidir con la base, estos tests fallan aquí y no en el
// teléfono.

void main() {
  test('Usuario se arma desde una fila de usuarios', () {
    final usuario = Usuario.fromSupabaseRow(
      {
        'id_usuario': '7f3c2a10-0000-4000-8000-000000000001',
        'correo_electronico': null,
        'alias': 'reciclador',
        'fecha_creacion': '2026-10-07T12:00:00+00:00',
      },
      puntosTotales: 12,
      nombre: 'Camila',
    );

    expect(usuario.id, '7f3c2a10-0000-4000-8000-000000000001');
    expect(usuario.alias, 'reciclador');
    expect(usuario.correo, isNull);
    expect(usuario.esInvitado, isTrue);
    expect(usuario.fechaRegistro, DateTime.utc(2026, 10, 7, 12));
    expect(usuario.nombre, 'Camila');
    expect(usuario.faltanDatos, isFalse);
  });

  test('sin nombre en user_metadata la bienvenida sigue pendiente', () {
    final usuario = Usuario.fromSupabaseRow({
      'id_usuario': '7f3c2a10-0000-4000-8000-000000000001',
      'correo_electronico': 'camila@gmail.com',
      'alias': 'Usuario Rebin',
      'fecha_creacion': '2026-10-07T12:00:00+00:00',
    }, puntosTotales: 0);

    expect(usuario.faltanDatos, isTrue);
    expect(usuario.esInvitado, isFalse);
  });

  test('una fila del esquema anterior ya no se acepta', () {
    expect(
      () => Usuario.fromSupabaseRow({
        'usuario_id': 1,
        'auth_user_id': '7f3c2a10-0000-4000-8000-000000000001',
        'nombre_usuario': 'reciclador',
        'fecha_registro': '2026-10-07T12:00:00+00:00',
      }, puntosTotales: 0),
      throwsA(isA<TypeError>()),
    );
  });

  test('MovimientoPunto se arma desde una fila de movimientos_puntos', () {
    final movimiento = MovimientoPunto.fromSupabaseRow({
      'tipo_referencia': 'canje',
      'cantidad': -20,
      'fecha': '2026-10-07T12:00:00+00:00',
    });

    expect(movimiento.tipo, 'canje');
    expect(movimiento.cantidad, -20);
    expect(movimiento.fecha, DateTime.utc(2026, 10, 7, 12));
  });

  test('cada valor de tipo_referencia_movimiento tiene su texto', () {
    // Enum tipo_referencia_movimiento del esquema remoto.
    const textos = {
      'deposito': 'Reciclaste un objeto',
      'escaneo': 'Escaneaste un objeto',
      'reporte': 'Reportaste el estado de un punto',
      'valoracion': 'Calificaste un punto',
      'sugerencia': 'Sugeriste un punto nuevo',
      'racha': 'Mantuviste tu racha diaria',
      'canje': 'Canjeaste un beneficio',
      'ajuste': 'Ajuste de puntos',
    };

    for (final MapEntry(key: tipo, value: texto) in textos.entries) {
      final actividad = ActividadPuntos.desdeMovimiento(
        MovimientoPunto(tipo: tipo, cantidad: 1, fecha: DateTime(2026)),
      );
      expect(actividad.texto, texto, reason: tipo);
    }
  });
}
