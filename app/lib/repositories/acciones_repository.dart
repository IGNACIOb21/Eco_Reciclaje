import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../models/material_type.dart';
import '../models/mi_reporte.dart';
import '../models/opiniones_punto.dart';
import '../models/sugerencia_cercana.dart';
import '../models/tipo_reporte.dart';

/// Resultado de una acción que puede dar puntos.
class ResultadoAccion {
  final int puntos;
  const ResultadoAccion(this.puntos);
}

enum MotivoErrorAccion {
  reporteRepetido,
  comentarioObligatorio,
  comentarioInvalido,
  limiteDiarioReportes,
  puntoNoEncontrado,
  puntuacionInvalida,
  etiquetasInvalidas,
  calificacionRepetida,
  calificacionesBloqueadas,
  nombreInvalido,
  direccionInvalida,
  ubicacionInvalida,
  ubicacionLejana,
  comunaInvalida,
  materialesInvalidos,
  limiteSugerencias,
  puntoCercano,
  sugerenciaCercana,
  sugerenciaNoEncontrada,
  sugerenciaPropia,
  lejosDeLaSugerencia,
  yaConfirmada,
  fotoInvalida,
  fotoObligatoria,
  fotoNoSubida,
  sinSesion,
  sinConexion,
  desconocido,
}

class AccionException implements Exception {
  final MotivoErrorAccion motivo;
  final Object? causa;

  const AccionException(this.motivo, [this.causa]);

  String get mensaje => switch (motivo) {
    MotivoErrorAccion.reporteRepetido =>
      'Ya reportaste esto en este punto hoy. Gracias, ya lo tenemos.',
    MotivoErrorAccion.comentarioObligatorio =>
      'Falta el comentario o es muy corto. Cuéntanos qué pasa.',
    MotivoErrorAccion.comentarioInvalido =>
      'El comentario no puede superar los 500 caracteres.',
    MotivoErrorAccion.limiteDiarioReportes =>
      'Llegaste al máximo de reportes de hoy. Vuelve mañana.',
    MotivoErrorAccion.puntoNoEncontrado => 'Este punto ya no está disponible.',
    MotivoErrorAccion.puntuacionInvalida => 'Elige entre 1 y 5 estrellas.',
    MotivoErrorAccion.calificacionRepetida =>
      'Ya calificaste este punto hoy. Vuelve mañana.',
    MotivoErrorAccion.calificacionesBloqueadas => 'Detectamos muchas calificaciones seguidas. Podrás volver a calificar mañana.',
    MotivoErrorAccion.etiquetasInvalidas => 'Elige solo una etiqueta de cada par: Limpio o Sucio, Seguro o Poco seguro.',
    MotivoErrorAccion.nombreInvalido =>
      'El nombre debe tener entre 3 y 100 caracteres.',
    MotivoErrorAccion.direccionInvalida =>
      'La dirección no puede superar los 200 caracteres.',
    MotivoErrorAccion.ubicacionInvalida =>
      'La ubicación no es válida. Revisa dónde está el punto.',
    MotivoErrorAccion.ubicacionLejana => 'Estás a más de 500 m del punto. Si está en otro lugar, usa "Sugerir un punto".',
    MotivoErrorAccion.comunaInvalida => 'Elige una comuna de la lista.',
    MotivoErrorAccion.materialesInvalidos =>
      'Elige al menos un material que reciba el punto.',
    MotivoErrorAccion.limiteSugerencias =>
      'Ya tienes 3 sugerencias en revisión. Espera a que se resuelvan.',
    MotivoErrorAccion.puntoCercano =>
      'Ya existe un punto a menos de 30 metros de ahí. Búscalo en el mapa.',
    MotivoErrorAccion.sugerenciaCercana => 'Alguien ya sugirió un punto ahí. Puedes confirmarlo en "Puntos por confirmar".',
    MotivoErrorAccion.sugerenciaNoEncontrada =>
      'Esa sugerencia ya fue revisada.',
    MotivoErrorAccion.sugerenciaPropia =>
      'No puedes confirmar tu propia sugerencia.',
    MotivoErrorAccion.lejosDeLaSugerencia =>
      'Debes estar a menos de 300 metros del lugar para confirmarlo.',
    MotivoErrorAccion.yaConfirmada => 'Ya confirmaste este punto.',
    MotivoErrorAccion.fotoInvalida =>
      'No pudimos usar la foto. Tómala de nuevo e inténtalo otra vez.',
    MotivoErrorAccion.fotoObligatoria =>
      'Toma una foto del punto para enviar el reporte.',
    MotivoErrorAccion.fotoNoSubida =>
      'No pudimos subir la foto. Revisa tu conexión e inténtalo de nuevo.',
    MotivoErrorAccion.sinSesion =>
      'No pudimos identificar tu sesión. Reinicia la app e inténtalo de nuevo.',
    MotivoErrorAccion.sinConexion =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
    MotivoErrorAccion.desconocido =>
      'No se pudo completar. Inténtalo de nuevo en un momento.',
  };

  @override
  String toString() => 'AccionException($motivo, $causa)';
}

/// Acciones del ciudadano sobre un punto (reportar, calificar). Las pantallas
/// dependen solo de esta interfaz (ver regla de repositorios en CLAUDE.md).
abstract class AccionesRepository {
  /// Lanza [AccionException] si el servidor rechaza la acción. [foto] es la
  /// foto del punto que la pantalla exige antes de enviar. [ubicacion] es la
  /// posición GPS que se propone como ubicación real del punto (solo en
  /// "Ubicación incorrecta", opcional).
  Future<ResultadoAccion> reportarEstado({
    required String idPunto,
    required TipoReporte tipo,
    String? comentario,
    File? foto,
    Position? ubicacion,
  });

  Future<ResultadoAccion> calificar({
    required String idPunto,
    required int puntuacion,
    List<String> etiquetas = const [],
    String? comentario,
  });

  /// Etiquetas más votadas y comentarios de los últimos 12 meses.
  Future<OpinionesPunto> opiniones(String idPunto);

  /// Reportes propios, el más reciente primero.
  Future<List<MiReporte>> misReportes();

  /// Sugiere un punto nuevo; queda en revisión. Devuelve el id de la sugerencia.
  Future<int> sugerirPunto({
    required String nombre,
    required double lat,
    required double lng,
    required String comuna,
    required List<TipoMaterial> materiales,
    String? direccion,
  });

  /// Sugerencias pendientes de otras personas cerca de [lat], [lng].
  Future<List<SugerenciaCercana>> sugerenciasCercanas({
    required double lat,
    required double lng,
  });

  /// Confirma que el punto sugerido existe (debes estar a 300 m o menos).
  /// Devuelve el total de confirmaciones. No da puntos: solo prioriza.
  Future<int> confirmarSugerencia({
    required int idSugerencia,
    required double lat,
    required double lng,
  });
}
