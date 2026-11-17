import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Lo que devuelve la base al registrar un reciclaje.
class RegistroReciclaje {
  final int puntos;
  final int saldo;

  const RegistroReciclaje({required this.puntos, required this.saldo});
}

class EscaneoException implements Exception {
  final String mensaje;
  final Object? causa;

  const EscaneoException(this.mensaje, [this.causa]);

  @override
  String toString() => 'EscaneoException($mensaje, $causa)';
}

/// Registra lo que se escaneó como un reciclaje del usuario (suma Rebin
/// Points según `regla_puntuacion`).
abstract class EscaneoRepository {
  Future<RegistroReciclaje> registrar({
    required String categoria,
    int cantidad = 1,
    double? confianza,
  });
}

EscaneoRepository escaneoPorDefecto() => SupabaseService.disponible
    ? EscaneoRepositorySupabase()
    : EscaneoRepositoryMock();

/// Usa `app_registrar_reciclaje` (backend/eco_reciclaje/02_funciones_app.sql).
class EscaneoRepositorySupabase implements EscaneoRepository {
  final SupabaseClient _cliente;

  EscaneoRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  @override
  Future<RegistroReciclaje> registrar({
    required String categoria,
    int cantidad = 1,
    double? confianza,
  }) async {
    try {
      final r = await _cliente.rpc(
        'app_registrar_reciclaje',
        params: {
          'p_codigo_categoria': categoria,
          'p_cantidad': cantidad,
          'p_confianza_ia': confianza,
        },
      );
      final mapa = Map<String, dynamic>.from(r as Map);
      return RegistroReciclaje(
        puntos: (mapa['puntos'] as num).toInt(),
        saldo: (mapa['saldo'] as num).toInt(),
      );
    } on PostgrestException catch (e) {
      debugPrint('EscaneoRepository: $e');
      throw EscaneoException(_mensaje(e.message), e);
    } on SocketException catch (e) {
      throw EscaneoException(
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
        e,
      );
    }
  }

  String _mensaje(String codigo) => switch (codigo) {
    'limite_diario' =>
      'Llegaste al máximo de 30 artículos por hoy. ¡Vuelve mañana!',
    'categoria_invalida' => 'Ese material todavía no se puede registrar.',
    'cantidad_invalida' => 'La cantidad debe estar entre 1 y 5.',
    'sesion_requerida' =>
      'No hay sesión activa. Cierra y vuelve a abrir la app.',
    _ => 'No pudimos registrar el reciclaje. Inténtalo de nuevo.',
  };
}

/// Demo sin Supabase: suma 10 puntos por artículo.
class EscaneoRepositoryMock implements EscaneoRepository {
  int _saldo = 0;

  @override
  Future<RegistroReciclaje> registrar({
    required String categoria,
    int cantidad = 1,
    double? confianza,
  }) async {
    final puntos = 10 * cantidad;
    _saldo += puntos;
    return RegistroReciclaje(puntos: puntos, saldo: _saldo);
  }
}
