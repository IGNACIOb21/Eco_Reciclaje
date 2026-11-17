import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reto.dart';
import '../services/supabase_service.dart';
import 'retos_repository.dart';

/// Usa `app_misiones_semana`, `app_reclamar_mision`, `app_logros` y
/// `app_reclamar_logro` (backend/remoto/20261017100000_gamificacion.sql). El
/// avance lo calcula la base desde las tablas reales; la app solo lo lee.
class RetosRepositorySupabase implements RetosRepository {
  final SupabaseClient _cliente;

  RetosRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  @override
  Future<Retos> retos() async {
    final (misiones, logros) = await (
      _cliente.rpc('app_misiones_semana'),
      _cliente.rpc('app_logros'),
    ).wait;
    return Retos(
      misiones: (misiones as List)
          .map((f) => _mision(f as Map<String, dynamic>))
          .toList(),
      logros: (logros as List)
          .map((f) => _logro(f as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<int> reclamarMision(String idMision) async {
    try {
      final r = await _cliente.rpc(
        'app_reclamar_mision',
        params: {'p_id_mision': int.parse(idMision)},
      ) as Map<String, dynamic>;
      return (r['puntos'] as num).toInt();
    } on PostgrestException catch (e) {
      // Otro toque (u otro teléfono) ya la reclamó: no es un error para la
      // persona, la lista se vuelve a leer y aparece como reclamada.
      if (e.message == 'mision_ya_reclamada') return 0;
      rethrow;
    }
  }

  @override
  Future<int> reclamarLogro(String idLogro) async {
    try {
      final r = await _cliente.rpc(
        'app_reclamar_logro',
        params: {'p_codigo': idLogro},
      ) as Map<String, dynamic>;
      return (r['puntos'] as num).toInt();
    } on PostgrestException catch (e) {
      if (e.message == 'logro_maximo') return 0;
      rethrow;
    }
  }

  Mision _mision(Map<String, dynamic> f) {
    final codigo = f['codigo'] as String;
    final (icono, color) = _estiloMision[codigo] ?? _estiloPorDefecto;
    return Mision(
      id: '${f['id_mision']}',
      titulo: f['titulo'] as String,
      detalle: (f['detalle'] as String?) ?? '',
      icono: icono,
      color: color,
      actual: (f['progreso'] as num).toInt(),
      meta: (f['meta'] as num).toInt(),
      puntos: (f['puntos'] as num).toInt(),
      bonus: f['bonus'] as bool? ?? false,
      reclamada: f['reclamada'] as bool? ?? false,
    );
  }

  Logro _logro(Map<String, dynamic> f) {
    final codigo = f['codigo'] as String;
    final (icono, color) = _estiloLogro[codigo] ?? _estiloPorDefecto;
    final niveles = (f['niveles'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return Logro(
      id: codigo,
      nombre: f['nombre'] as String,
      descripcion: (f['descripcion'] as String?) ?? '',
      icono: icono,
      color: color,
      actual: (f['progreso'] as num).toInt(),
      escalones: [
        for (final n in niveles)
          EscalonLogro(
            (n['meta'] as num).toInt(),
            (n['puntos'] as num).toInt(),
          ),
      ],
      nivelReclamado: (f['nivel_obtenido'] as num).toInt(),
    );
  }

  // Ícono y color por código: la base no guarda nada visual. Una misión o un
  // logro nuevo creado desde el panel usa el estilo por defecto.
  static const _estiloPorDefecto = (
    Icons.emoji_events_outlined,
    Color(0xFF0C872B),
  );

  static const _estiloMision = {
    'materiales_3': (Icons.layers_outlined, Color(0xFF1F7A72)),
    'escanear_5': (Icons.qr_code_scanner, Color(0xFF0C872B)),
    'reportar_2': (Icons.flag_outlined, Color(0xFF2F6DB5)),
    'sugerir_1': (Icons.place_outlined, Color(0xFFE2B85C)),
    'calificar_1': (Icons.star_outline, Color(0xFF7E5AA6)),
  };

  static const _estiloLogro = {
    'vidriero': (Icons.wine_bar_outlined, Color(0xFF1F7A72)),
    'papelero': (Icons.description_outlined, Color(0xFF2F6DB5)),
    'racha_7': (Icons.local_fire_department_outlined, Color(0xFF0C872B)),
    'guardian': (Icons.flag_outlined, Color(0xFF2F6DB5)),
    'vecino': (Icons.star_outline, Color(0xFF7E5AA6)),
    'explorador': (Icons.explore_outlined, Color(0xFFE2B85C)),
    'pilas': (Icons.battery_charging_full, Color(0xFFC0392B)),
    'buen_vecino': (Icons.handshake_outlined, Color(0xFF1F7A72)),
  };
}
