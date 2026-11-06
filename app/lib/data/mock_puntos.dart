import 'dart:math';

import '../models/estado_punto.dart';
import '../models/material_type.dart';
import '../models/punto_reciclaje.dart';
import 'comunas_demo.dart';

/// Genera datos de demostración: al menos 7 puntos de reciclaje por comuna,
/// con materiales variados, espejando el seed SQL en
/// backend/supabase/seed.sql (misma idea, generador independiente — no hay
/// backend conectado todavía).
List<PuntoReciclaje> _generarMockPuntos() {
  final random = Random(42);

  const combos = [
    [TipoMaterial.vidrio, TipoMaterial.papel, TipoMaterial.plastico],
    [TipoMaterial.metal, TipoMaterial.pilas],
    [TipoMaterial.plastico],
    [TipoMaterial.papel, TipoMaterial.tetraPak],
    [
      TipoMaterial.vidrio,
      TipoMaterial.papel,
      TipoMaterial.plastico,
      TipoMaterial.metal,
    ],
    [TipoMaterial.pilas],
    [TipoMaterial.latas, TipoMaterial.tetraPak],
    [TipoMaterial.vidrio],
    [TipoMaterial.plastico, TipoMaterial.latas],
    [TipoMaterial.papel],
    [TipoMaterial.vidrio, TipoMaterial.metal],
    [TipoMaterial.plastico, TipoMaterial.papel, TipoMaterial.tetraPak],
  ];

  const nombresTpl = [
    'Punto Limpio {calle}',
    'Reciclaje {calle}',
    'Punto comunitario {comuna}',
    'Contenedor {calle}',
    'Punto Limpio Municipal {comuna}',
    'Reciclaje Vecinal {comuna}',
    'Estación de Reciclaje {calle}',
  ];

  const estados = [
    EstadoPunto.disponible,
    EstadoPunto.disponible,
    EstadoPunto.disponible,
    EstadoPunto.lleno,
    EstadoPunto.sinSenalizacion,
    EstadoPunto.danado,
    EstadoPunto.malMantenimiento,
    EstadoPunto.fueraDeUso,
  ];

  const fuentes = [
    FuentePunto.oficial,
    FuentePunto.oficial,
    FuentePunto.comunidad,
  ];

  double jitter() => (random.nextDouble() * 2 - 1) * 0.012;
  T elegir<T>(List<T> opciones) => opciones[random.nextInt(opciones.length)];

  final puntos = <PuntoReciclaje>[];
  var comboIndex = 0;
  var contador = 0;

  for (final comuna in comunasDemo) {
    for (var i = 0; i < 7; i++) {
      final lat = comuna.lat + jitter();
      final lng = comuna.lng + jitter();
      final numero = 100 + random.nextInt(6400);
      final nombre = elegir(nombresTpl)
          .replaceAll('{calle}', comuna.calleReferencia)
          .replaceAll('{comuna}', comuna.nombre);

      puntos.add(
        PuntoReciclaje(
          id: 'p${++contador}',
          nombre: nombre,
          comuna: comuna.nombre,
          direccion: '${comuna.calleReferencia} $numero',
          lat: lat,
          lng: lng,
          fuente: elegir(fuentes),
          materiales: combos[comboIndex++ % combos.length],
          estado: elegir(estados),
          calificacionPromedio: double.parse(
            (2.5 + random.nextDouble() * 2.5).toStringAsFixed(1),
          ),
          numCalificaciones: 3 + random.nextInt(58),
        ),
      );
    }
  }

  return puntos;
}

final mockPuntos = _generarMockPuntos();
