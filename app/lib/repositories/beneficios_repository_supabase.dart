import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/beneficio.dart';
import '../models/mi_canje.dart';
import '../services/supabase_service.dart';
import 'beneficios_repository.dart';

/// Usa `app_beneficios`, `app_generar_canje` y `app_mis_canjes`
/// (backend/remoto/20261013100000_canje_app.sql).
class BeneficiosRepositorySupabase implements BeneficiosRepository {
  final SupabaseClient _cliente;

  BeneficiosRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  @override
  Future<List<Beneficio>> beneficios() async {
    final filas = await _cliente.rpc('app_beneficios');
    return (filas as List)
        .map((f) => Beneficio.fromSupabaseRow(f as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ResultadoCanje> canjear(int idBeneficio) async {
    try {
      final r = await _cliente.rpc(
        'app_generar_canje',
        params: {'p_id_beneficio': idBeneficio},
      ) as Map<String, dynamic>;
      return ResultadoCanje(
        codigo: r['codigo_canje'] as String,
        costo: (r['costo'] as num).toInt(),
        saldo: (r['saldo'] as num).toInt(),
      );
    } on PostgrestException catch (e) {
      throw CanjeException(_motivo(e), e);
    } on SocketException catch (e) {
      throw CanjeException(MotivoErrorCanje.sinConexion, e);
    }
  }

  @override
  Future<List<MiCanje>> misCanjes() async {
    final filas = await _cliente.rpc('app_mis_canjes');
    return (filas as List)
        .map((f) => MiCanje.fromSupabaseRow(f as Map<String, dynamic>))
        .toList();
  }

  /// La función avisa con `raise exception '<codigo>'` (P0001); sin permiso
  /// de ejecución responde 42501.
  MotivoErrorCanje _motivo(PostgrestException e) {
    switch (e.message) {
      case 'requiere_cuenta':
        return MotivoErrorCanje.requiereCuenta;
      case 'saldo_insuficiente':
        return MotivoErrorCanje.saldoInsuficiente;
      case 'sin_stock':
        return MotivoErrorCanje.sinStock;
      case 'tope_alcanzado':
        return MotivoErrorCanje.topeAlcanzado;
      case 'beneficio_no_disponible':
        return MotivoErrorCanje.beneficioNoDisponible;
      case 'sesion_requerida':
      case 'usuario_no_registrado':
        return MotivoErrorCanje.sinSesion;
    }
    if (e.code == '42501') return MotivoErrorCanje.sinSesion;
    return MotivoErrorCanje.desconocido;
  }
}
