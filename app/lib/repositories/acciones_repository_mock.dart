import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../models/material_type.dart';
import '../models/mi_reporte.dart';
import '../models/opiniones_punto.dart';
import '../models/sugerencia_cercana.dart';
import '../models/tipo_reporte.dart';
import 'acciones_repository.dart';

/// Para demos sin conexión y tests: acepta todo sin guardar nada. Con
/// [error] lanza esa excepción en cada acción.
class AccionesRepositoryMock implements AccionesRepository {
  final AccionException? error;
  final List<MiReporte> reportes;
  final List<SugerenciaCercana> sugerencias;

  /// Último reporte enviado, para comprobarlo en tests.
  TipoReporte? ultimoTipo;
  String? ultimoComentario;
  File? ultimaFoto;
  Position? ultimaUbicacion;
  int? ultimaPuntuacion;
  List<String>? ultimasEtiquetas;
  String? ultimoComentarioCalificacion;
  String? ultimaSugerencia;
  List<TipoMaterial>? ultimosMateriales;
  double? ultimaLat;
  int? ultimaConfirmada;

  /// Lo que devuelve [opiniones].
  final OpinionesPunto opinionesDelPunto;

  AccionesRepositoryMock({
    this.error,
    this.reportes = const [],
    this.sugerencias = const [],
    this.opinionesDelPunto = OpinionesPunto.vacio,
  });

  @override
  Future<ResultadoAccion> reportarEstado({
    required String idPunto,
    required TipoReporte tipo,
    String? comentario,
    File? foto,
    Position? ubicacion,
  }) async {
    if (error != null) throw error!;
    ultimoTipo = tipo;
    ultimoComentario = comentario;
    ultimaFoto = foto;
    ultimaUbicacion = ubicacion;
    return ResultadoAccion(tipo == TipoReporte.todoEnOrden ? 0 : 3);
  }

  @override
  Future<ResultadoAccion> calificar({
    required String idPunto,
    required int puntuacion,
    List<String> etiquetas = const [],
    String? comentario,
  }) async {
    if (error != null) throw error!;
    ultimaPuntuacion = puntuacion;
    ultimasEtiquetas = etiquetas;
    ultimoComentarioCalificacion = comentario;
    return const ResultadoAccion(2);
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
    if (error != null) throw error!;
    ultimaSugerencia = nombre;
    ultimosMateriales = materiales;
    ultimaLat = lat;
    return 1;
  }

  @override
  Future<List<SugerenciaCercana>> sugerenciasCercanas({
    required double lat,
    required double lng,
  }) async {
    if (error != null) throw error!;
    return sugerencias;
  }

  @override
  Future<int> confirmarSugerencia({
    required int idSugerencia,
    required double lat,
    required double lng,
  }) async {
    if (error != null) throw error!;
    ultimaConfirmada = idSugerencia;
    return 1;
  }

  @override
  Future<OpinionesPunto> opiniones(String idPunto) async => opinionesDelPunto;

  @override
  Future<List<MiReporte>> misReportes() async {
    if (error != null) throw error!;
    return reportes;
  }
}
