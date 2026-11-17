import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/material_type.dart';
import '../models/mi_reporte.dart';
import '../models/opiniones_punto.dart';
import '../models/sugerencia_cercana.dart';
import '../models/tipo_reporte.dart';
import '../services/supabase_service.dart';
import 'acciones_repository.dart';

/// Usa las funciones `app_reportar_estado`, `app_calificar` y
/// `app_mis_reportes` (backend/remoto/20261012100000_acciones_ciudadano.sql).
///
/// La foto del reporte se sube al bucket privado `reportes`
/// (`<auth.uid()>/<milisegundos>.jpg`) y su ruta va en `p_foto_ruta`
/// (backend/remoto/20261015110000_reporte_foto.sql). La foto es obligatoria:
/// si no se puede subir, el reporte no se envía (`fotoNoSubida`).
///
/// La foto se sube antes de llamar a la RPC; si la RPC rechaza el reporte
/// (repetido, tope diario…), la ruta subida se guarda y un nuevo intento con
/// la MISMA foto la reutiliza en vez de subir otra. Las que igual quedan sin
/// reporte las borra el script limpiar-fotos-reportes.js de la Web API.
class AccionesRepositorySupabase implements AccionesRepository {
  static const bucketReportes = 'reportes';

  // Solo para tests: el cliente, la subida a Storage, la llamada a la RPC y
  // el usuario de la sesión. Sin ellos se usa el Supabase real.
  final SupabaseClient? cliente;
  final Future<void> Function(String ruta, File foto)? subir;
  final Future<dynamic> Function(String funcion, Map<String, dynamic> params)?
  rpc;
  final String? Function()? uid;

  late final SupabaseClient _cliente = cliente ?? SupabaseService.cliente;

  /// Foto ya subida cuyo reporte todavía no se aceptó: ruta del archivo en
  /// el teléfono → ruta en el bucket.
  ({String archivo, String ruta})? _subida;

  AccionesRepositorySupabase({this.cliente, this.subir, this.rpc, this.uid});

  @override
  Future<ResultadoAccion> reportarEstado({
    required String idPunto,
    required TipoReporte tipo,
    String? comentario,
    File? foto,
    Position? ubicacion,
  }) async {
    final params = <String, dynamic>{
      'p_id_punto': int.parse(idPunto),
      'p_tipo': tipo.codigo,
      'p_comentario': (comentario?.trim().isEmpty ?? true)
          ? null
          : comentario!.trim(),
      if (ubicacion != null) ...{
        'p_lat': ubicacion.latitude,
        'p_lng': ubicacion.longitude,
        'p_precision_gps': ubicacion.accuracy,
        'p_ubicacion_simulada': ubicacion.isMocked,
      },
    };
    if (foto == null) {
      throw const AccionException(MotivoErrorAccion.fotoObligatoria);
    }
    final ruta = await _subirFoto(foto);
    try {
      final resultado = await _ejecutar('app_reportar_estado', {
        ...params,
        'p_foto_ruta': ruta,
      });
      _subida = null;
      return resultado;
    } on AccionException catch (e) {
      // La base no aceptó esa ruta (no existe o ya se usó): no reutilizarla.
      if (e.motivo == MotivoErrorAccion.fotoInvalida) _subida = null;
      rethrow;
    }
  }

  /// Sube la foto y devuelve su ruta en el bucket. Si esta misma foto ya se
  /// subió en un intento anterior que la base rechazó, devuelve esa ruta sin
  /// volver a subirla. Si no se puede subir, lanza [AccionException]: el
  /// reporte no se envía sin foto.
  Future<String> _subirFoto(File foto) async {
    final previa = _subida;
    if (previa != null && previa.archivo == foto.path) return previa.ruta;

    final leerUid = this.uid;
    final uid = leerUid != null ? leerUid() : _cliente.auth.currentUser?.id;
    if (uid == null) {
      throw const AccionException(MotivoErrorAccion.sinSesion);
    }
    final ruta = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      final subir = this.subir;
      if (subir != null) {
        await subir(ruta, foto);
      } else {
        await _cliente.storage
            .from(bucketReportes)
            .uploadBinary(
              ruta,
              await foto.readAsBytes(),
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      }
    } on SocketException catch (e) {
      throw AccionException(MotivoErrorAccion.sinConexion, e);
    } catch (e) {
      debugPrint('Reportar: no se pudo subir la foto ($e)');
      throw AccionException(MotivoErrorAccion.fotoNoSubida, e);
    }
    _subida = (archivo: foto.path, ruta: ruta);
    return ruta;
  }

  @override
  Future<ResultadoAccion> calificar({
    required String idPunto,
    required int puntuacion,
    List<String> etiquetas = const [],
    String? comentario,
  }) => _ejecutar('app_calificar', {
    'p_id_punto': int.parse(idPunto),
    'p_puntuacion': puntuacion,
    'p_etiquetas': etiquetas.isEmpty ? null : etiquetas,
    'p_comentario': (comentario?.trim().isEmpty ?? true)
        ? null
        : comentario!.trim(),
  });

  @override
  Future<OpinionesPunto> opiniones(String idPunto) async {
    final r = await _cliente.rpc(
      'app_opiniones_punto',
      params: {'p_id_punto': int.parse(idPunto)},
    );
    return OpinionesPunto.fromSupabase(r as Map<String, dynamic>);
  }

  @override
  Future<List<MiReporte>> misReportes() async {
    final filas = await _cliente.rpc('app_mis_reportes');
    return (filas as List)
        .map((f) => MiReporte.fromSupabaseRow(f as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> sugerirPunto({
    required String nombre,
    required double lat,
    required double lng,
    required String comuna,
    required List<TipoMaterial> materiales,
    String? direccion,
  }) async {
    try {
      final id = await _cliente.rpc(
        'app_sugerir_punto',
        params: {
          'p_nombre': nombre.trim(),
          'p_lat': lat,
          'p_lng': lng,
          'p_comuna': comuna,
          'p_materiales': materiales.map((m) => m.codigo).toList(),
          'p_direccion': (direccion?.trim().isEmpty ?? true)
              ? null
              : direccion!.trim(),
        },
      );
      return (id as num).toInt();
    } on PostgrestException catch (e) {
      throw AccionException(_motivo(e), e);
    } on SocketException catch (e) {
      throw AccionException(MotivoErrorAccion.sinConexion, e);
    }
  }

  @override
  Future<List<SugerenciaCercana>> sugerenciasCercanas({
    required double lat,
    required double lng,
  }) async {
    final filas = await _cliente.rpc(
      'app_sugerencias_cercanas',
      params: {'p_lat': lat, 'p_lng': lng, 'p_radio_km': 1},
    );
    return (filas as List)
        .map(
          (f) => SugerenciaCercana.fromSupabaseRow(f as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<int> confirmarSugerencia({
    required int idSugerencia,
    required double lat,
    required double lng,
  }) async {
    try {
      final total = await _cliente.rpc(
        'app_confirmar_sugerencia',
        params: {'p_id_sugerencia': idSugerencia, 'p_lat': lat, 'p_lng': lng},
      );
      return (total as num).toInt();
    } on PostgrestException catch (e) {
      throw AccionException(_motivo(e), e);
    } on SocketException catch (e) {
      throw AccionException(MotivoErrorAccion.sinConexion, e);
    }
  }

  Future<ResultadoAccion> _ejecutar(
    String funcion,
    Map<String, dynamic> params,
  ) async {
    try {
      final rpc = this.rpc;
      final r = rpc != null
          ? await rpc(funcion, params)
          : await _cliente.rpc(funcion, params: params);
      return ResultadoAccion(((r as Map)['puntos'] as num?)?.toInt() ?? 0);
    } on PostgrestException catch (e) {
      throw AccionException(_motivo(e), e);
    } on SocketException catch (e) {
      throw AccionException(MotivoErrorAccion.sinConexion, e);
    }
  }

  /// Las funciones avisan con `raise exception '<codigo>'` (P0001); sin
  /// permiso de ejecución responde 42501.
  MotivoErrorAccion _motivo(PostgrestException e) {
    switch (e.message) {
      case 'reporte_repetido':
        return MotivoErrorAccion.reporteRepetido;
      case 'comentario_obligatorio':
        return MotivoErrorAccion.comentarioObligatorio;
      case 'comentario_invalido':
        return MotivoErrorAccion.comentarioInvalido;
      case 'limite_diario_reportes':
        return MotivoErrorAccion.limiteDiarioReportes;
      case 'punto_no_encontrado':
        return MotivoErrorAccion.puntoNoEncontrado;
      case 'puntuacion_invalida':
        return MotivoErrorAccion.puntuacionInvalida;
      case 'calificacion_repetida':
        return MotivoErrorAccion.calificacionRepetida;
      case 'calificaciones_bloqueadas':
        return MotivoErrorAccion.calificacionesBloqueadas;
      case 'etiquetas_invalidas':
        return MotivoErrorAccion.etiquetasInvalidas;
      case 'nombre_invalido':
        return MotivoErrorAccion.nombreInvalido;
      case 'direccion_invalida':
        return MotivoErrorAccion.direccionInvalida;
      case 'ubicacion_invalida':
        return MotivoErrorAccion.ubicacionInvalida;
      case 'ubicacion_lejana':
        return MotivoErrorAccion.ubicacionLejana;
      case 'comuna_invalida':
        return MotivoErrorAccion.comunaInvalida;
      case 'materiales_invalidos':
        return MotivoErrorAccion.materialesInvalidos;
      case 'limite_sugerencias':
        return MotivoErrorAccion.limiteSugerencias;
      case 'punto_cercano':
        return MotivoErrorAccion.puntoCercano;
      case 'sugerencia_cercana':
        return MotivoErrorAccion.sugerenciaCercana;
      case 'sugerencia_no_encontrada':
        return MotivoErrorAccion.sugerenciaNoEncontrada;
      case 'sugerencia_propia':
        return MotivoErrorAccion.sugerenciaPropia;
      case 'lejos_de_la_sugerencia':
        return MotivoErrorAccion.lejosDeLaSugerencia;
      case 'ya_confirmada':
        return MotivoErrorAccion.yaConfirmada;
      case 'foto_invalida':
        return MotivoErrorAccion.fotoInvalida;
      case 'foto_obligatoria':
        return MotivoErrorAccion.fotoObligatoria;
      case 'sesion_requerida':
      case 'usuario_no_registrado':
        return MotivoErrorAccion.sinSesion;
    }
    if (e.code == '42501') return MotivoErrorAccion.sinSesion;
    // Índice único de reporte_punto.foto_ruta: dos reportes a la vez con la
    // misma foto (solo pasa con un cliente modificado).
    if (e.code == '23505') return MotivoErrorAccion.fotoInvalida;
    return MotivoErrorAccion.desconocido;
  }
}
