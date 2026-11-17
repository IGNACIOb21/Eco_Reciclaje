import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/material_type.dart';
import '../models/postulacion_servicio.dart';
import '../models/recolector_particular.dart';
import '../services/supabase_service.dart';
import 'recolectores_repository.dart';

/// Lee y envía por las funciones `app_servicios`, `app_postular_servicio` y
/// `app_mis_postulaciones` (backend/remoto/20261011100000_servicios_terceros.sql).
/// La app no toca las tablas: están cerradas por RLS.
class RecolectoresRepositorySupabase implements RecolectoresRepository {
  final SupabaseClient _cliente;

  RecolectoresRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  @override
  Future<List<RecolectorParticular>> obtenerRecolectores({
    String? comuna,
    List<TipoMaterial> materiales = const [],
  }) async {
    final filas = await _cliente.rpc(
      'app_servicios',
      params: {
        'comuna_filtro': comuna,
        'materiales_filtro': materiales.isEmpty
            ? null
            : materiales.map((m) => m.codigo).toList(),
      },
    );
    return (filas as List)
        .map(
          (f) =>
              RecolectorParticular.fromSupabaseRow(f as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> postular(PostulacionServicio postulacion) async {
    try {
      await _cliente.rpc(
        'app_postular_servicio',
        params: {
          'p_nombre': postulacion.nombre,
          'p_contacto': postulacion.contacto,
          'p_comunas': postulacion.comunas,
          'p_materiales': postulacion.materiales.map((m) => m.codigo).toList(),
          'p_descripcion': postulacion.descripcion.isEmpty
              ? null
              : postulacion.descripcion,
          'p_retira_a_domicilio': postulacion.retiraADomicilio,
          'p_horario': postulacion.horario.isEmpty ? null : postulacion.horario,
        },
      );
    } on PostgrestException catch (e) {
      throw PostulacionException(_motivo(e), e);
    } on SocketException catch (e) {
      throw PostulacionException(MotivoErrorPostulacion.sinConexion, e);
    }
  }

  @override
  Future<List<MiPostulacion>> misPostulaciones() async {
    final filas = await _cliente.rpc('app_mis_postulaciones');
    return (filas as List)
        .map((f) => MiPostulacion.fromSupabaseRow(f as Map<String, dynamic>))
        .toList();
  }

  /// La función avisa con `raise exception '<codigo>'` (SQLSTATE P0001); el
  /// código llega en el mensaje. Sin permiso de ejecución responde 42501.
  MotivoErrorPostulacion _motivo(PostgrestException e) {
    switch (e.message) {
      case 'nombre_invalido':
        return MotivoErrorPostulacion.nombreInvalido;
      case 'contacto_invalido':
        return MotivoErrorPostulacion.contactoInvalido;
      case 'descripcion_invalida':
        return MotivoErrorPostulacion.descripcionInvalida;
      case 'horario_invalido':
        return MotivoErrorPostulacion.horarioInvalido;
      case 'comunas_invalidas':
        return MotivoErrorPostulacion.comunasInvalidas;
      case 'categorias_invalidas':
        return MotivoErrorPostulacion.materialesInvalidos;
      case 'limite_postulaciones':
        return MotivoErrorPostulacion.limitePostulaciones;
      case 'sesion_requerida':
      case 'usuario_no_registrado':
        return MotivoErrorPostulacion.sinSesion;
    }
    if (e.code == '42501') return MotivoErrorPostulacion.sinSesion;
    return MotivoErrorPostulacion.desconocido;
  }
}
