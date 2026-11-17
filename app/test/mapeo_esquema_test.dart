
import 'package:flutter_test/flutter_test.dart';

import 'package:recircula/models/actividad_puntos.dart';
import 'package:recircula/models/estado_punto.dart';
import 'package:recircula/models/material_type.dart';
import 'package:recircula/data/comunas_region_metropolitana.dart';
import 'package:recircula/models/postulacion_servicio.dart';
import 'package:recircula/models/punto_reciclaje.dart';
import 'package:recircula/models/recolector_particular.dart';
import 'package:recircula/utils/horario_texto.dart';
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
  });

  test('sin nombre en user_metadata el nombre queda vacío', () {
    final usuario = Usuario.fromSupabaseRow({
      'id_usuario': '7f3c2a10-0000-4000-8000-000000000001',
      'correo_electronico': 'camila@gmail.com',
      'alias': 'Usuario Rebin',
      'fecha_creacion': '2026-10-07T12:00:00+00:00',
    }, puntosTotales: 0);

    expect(usuario.nombre, isNull);
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
      'ajuste': 'Ajuste de Rebin Points',
    };

    for (final MapEntry(key: tipo, value: texto) in textos.entries) {
      final actividad = ActividadPuntos.desdeMovimiento(
        // Un canje real descuenta puntos; con cantidad positiva sería una devolución.
        MovimientoPunto(
          tipo: tipo,
          cantidad: tipo == 'canje' ? -1 : 1,
          fecha: DateTime(2026),
        ),
      );
      expect(actividad.texto, texto, reason: tipo);
    }
  });
  test('PuntoReciclaje se arma desde una fila de app_puntos_cercanos', () {
    // Forma exacta que devuelve backend/remoto/20261010100000_app_puntos_cercanos.sql
    final punto = PuntoReciclaje.fromSupabaseRow({
      'id': '42',
      'nombre': 'Punto Limpio Plaza',
      'direccion': 'Av. Siempre Viva 123',
      'comuna': 'Santiago',
      'lat': -33.45,
      'lng': -70.66,
      'fuente': 'oficial',
      'estado_actual': 'mal_mantenimiento',
      'calificacion_promedio': 4.5,
      'num_calificaciones': 2,
      'materiales': ['aceite', 'vidrio', 'inexistente'],
      'distancia_km': 0.3,
    });

    expect(punto.id, '42');
    expect(punto.comuna, 'Santiago');
    expect(punto.fuente, FuentePunto.oficial);
    expect(punto.estado, EstadoPunto.malMantenimiento);
    expect(punto.calificacionPromedio, 4.5);
    expect(punto.numCalificaciones, 2);
    // El aceite es una categoría más; un código desconocido se descarta.
    expect(punto.materiales, [TipoMaterial.aceite, TipoMaterial.vidrio]);
  });

  test('todo TipoMaterial tiene un código que vuelve a sí mismo', () {
    for (final m in TipoMaterial.values) {
      expect(MaterialTypeInfo.fromCodigo(m.codigo), m);
    }
  });
  test('RecolectorParticular se arma desde una fila de app_servicios', () {
    // Forma exacta que devuelve backend/remoto/20261011100000_servicios_terceros.sql
    final r = RecolectorParticular.fromSupabaseRow({
      'id': '7',
      'nombre': 'Aceite Circular',
      'descripcion': '',
      'contacto': '+56 9 8123 4567',
      'retira_a_domicilio': true,
      'horario': {'lun-vie': '9:00-18:00', 'sáb': '10:00-14:00'},
      'comunas': ['Ñuñoa', 'Providencia'],
      'materiales': ['aceite', 'plutonio'],
      'puntos': [
        {
          'id': '42',
          'nombre': 'Acopio',
          'direccion': 'Calle 1',
          'lat': -33.4,
          'lng': -70.6,
        },
      ],
    });

    expect(r.id, '7');
    expect(r.materiales, [
      TipoMaterial.aceite,
    ]); // el código desconocido se descarta
    expect(r.comunasTexto, 'Ñuñoa, Providencia');
    expect(r.retiraADomicilio, isTrue);
    expect(r.horario, {'lun-vie': '9:00-18:00', 'sáb': '10:00-14:00'});
    expect(r.puntos.single.nombre, 'Acopio');
    expect(r.puntos.single.lat, -33.4);
  });

  test('un servicio sin horario ni puntos (horario null) se arma igual', () {
    final r = RecolectorParticular.fromSupabaseRow({
      'id': '8',
      'nombre': 'Karla V.',
      'descripcion': 'Tetra Pak limpio',
      'contacto': '@karla',
      'retira_a_domicilio': false,
      'horario': null,
      'comunas': ['Macul'],
      'materiales': ['tetra_pak'],
      'puntos': [],
    });

    expect(r.horario, isEmpty);
    expect(r.puntos, isEmpty);
    expect(r.materiales, [TipoMaterial.tetraPak]);
  });

  test('MiPostulacion se arma desde una fila de app_mis_postulaciones', () {
    final p = MiPostulacion.fromSupabaseRow({
      'id': '9',
      'nombre': 'Mi servicio',
      'estado': 'rechazado',
      'motivo_rechazo': 'Contacto inválido',
      'fecha_registro': '2026-10-08T15:43:29.286215+00:00',
    });

    expect(p.estado, EstadoPostulacion.rechazado);
    expect(p.estado.etiqueta, 'Rechazado');
    expect(p.motivoRechazo, 'Contacto inválido');
    expect(p.fecha.toUtc().year, 2026);
    expect(
      EstadoPostulacionInfo.fromCodigo('activo'),
      EstadoPostulacion.activo,
    );
  });

  test('el horario va y viene entre texto y objeto', () {
    final h = horarioDesdeTexto('lun-vie: 9:00-18:00\n\n  sáb :  10:00-14:00 ');
    expect(h, {'lun-vie': '9:00-18:00', 'sáb': '10:00-14:00'});
    expect(horarioATexto(h), 'lun-vie: 9:00-18:00\nsáb: 10:00-14:00');
    expect(horarioDesdeTexto('   '), isEmpty);
    expect(() => horarioDesdeTexto('sin dos puntos'), throwsFormatException);
    expect(() => horarioDesdeTexto('lun: '), throwsFormatException);
  });

  test('la app ofrece las 52 comunas de la Región Metropolitana', () {
    // En Proyecto_Eco_reciclaje no hay tabla de comunas: la lista vive en la
    // app y la base guarda el nombre tal cual (usuario.comuna,
    // punto_reciclaje.comuna, servicio_tercero.comunas).
    expect(comunasRegionMetropolitana, hasLength(52));
    expect(comunasRegionMetropolitana.toSet(), hasLength(52));
    expect(comunasRegionMetropolitana, containsAll(['Santiago', 'Ñuñoa']));
  });
  test(
    'el horario se ordena por día de la semana (jsonb no guarda el orden)',
    () {
      final orden = ordenarHorario({
        'sáb': '10:00-14:00',
        'dom': 'cerrado',
        'lun-vie': '9:00-18:00',
        'feriados': 'cerrado',
        'mié': '9:00-12:00',
      });

      expect(orden.keys.toList(), ['lun-vie', 'mié', 'sáb', 'dom', 'feriados']);
    },
  );
}
