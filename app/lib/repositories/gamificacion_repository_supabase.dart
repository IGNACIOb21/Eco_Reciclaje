import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/resumen_hoy.dart';
import '../services/supabase_service.dart';
import 'gamificacion_repository.dart';

/// Usa `app_resumen_hoy` (backend/remoto/20261017100000_gamificacion.sql). La
/// meta y la racha las calcula la base desde las tablas reales; la app solo
/// las lee.
class GamificacionRepositorySupabase implements GamificacionRepository {
  final SupabaseClient _cliente;

  GamificacionRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  @override
  Future<ResumenHoy> resumenHoy() async {
    final r = await _cliente.rpc('app_resumen_hoy');
    return ResumenHoy.fromJson(r as Map<String, dynamic>);
  }

  @override
  Future<CompraCongelador> comprarCongelador() async {
    try {
      final r =
          await _cliente.rpc('app_comprar_congelador') as Map<String, dynamic>;
      return CompraCongelador(
        congeladores: (r['congeladores'] as num).toInt(),
        saldo: (r['saldo'] as num).toInt(),
      );
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<SorpresaHoy> sorpresaHoy() async {
    final r = await _cliente.rpc('app_sorpresa_hoy') as Map<String, dynamic>;
    return SorpresaHoy(
      disponible: r['disponible'] as bool? ?? false,
      abierta: r['abierta'] as bool? ?? false,
      puntos: (r['puntos'] as num).toInt(),
    );
  }

  @override
  Future<int> abrirSorpresa() async {
    try {
      final r =
          await _cliente.rpc('app_abrir_sorpresa') as Map<String, dynamic>;
      return (r['puntos'] as num).toInt();
    } on PostgrestException catch (e) {
      throw _traducir(e);
    }
  }

  /// El código de la base como excepción de la app; lo desconocido se relanza.
  Object _traducir(PostgrestException e) {
    final motivo = MotivoGamificacion.fromCodigo(e.message);
    return motivo == null ? e : GamificacionException(motivo);
  }
}
