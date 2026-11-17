import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comunidad_hoy.dart';
import '../services/supabase_service.dart';
import 'comunidad_repository.dart';

/// Usa `app_comunidad_hoy`, `app_actividad_comuna`, `app_ranking_semana` y
/// `app_ocultar_ranking` (backend/remoto/20261017100000_gamificacion.sql).
class ComunidadRepositorySupabase implements ComunidadRepository {
  final SupabaseClient _cliente;

  ComunidadRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  @override
  Future<MetaComuna> metaComuna(String comuna) async {
    final r = await _cliente.rpc(
      'app_comunidad_hoy',
      params: {'p_comuna': comuna},
    );
    return MetaComuna.fromJson(r as Map<String, dynamic>);
  }

  @override
  Future<List<ActividadComuna>> actividad(String comuna) async {
    final filas = await _cliente.rpc(
      'app_actividad_comuna',
      params: {'p_comuna': comuna, 'p_limite': 30},
    );
    return [
      for (final f in filas as List)
        ActividadComuna.fromJson(f as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<PuestoRanking>> ranking() async {
    final filas = await _cliente.rpc(
      'app_ranking_semana',
      params: {'p_limite': 20},
    );
    return [
      for (final f in filas as List)
        PuestoRanking.fromJson(f as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> ocultarRanking(bool oculto) =>
      _cliente.rpc('app_ocultar_ranking', params: {'p_oculto': oculto});
}
