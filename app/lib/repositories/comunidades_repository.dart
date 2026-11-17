import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Una comunidad (tabla `comunidad`) vista desde la sesión actual.
class ComunidadResumen {
  final int id;
  final String nombre;
  final String descripcion;
  final String? comuna;
  final int miembros;
  final bool esMiembro;

  /// 'administrador', 'moderador' o 'miembro'; null si no es miembro.
  final String? miRol;

  /// Rebin Points que ganaron sus miembros reciclando en los últimos 7 días.
  final int puntosSemana;

  const ComunidadResumen({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.comuna,
    required this.miembros,
    required this.esMiembro,
    required this.miRol,
    required this.puntosSemana,
  });

  bool get administro => miRol == 'administrador';

  factory ComunidadResumen.fromJson(Map<String, dynamic> j) => ComunidadResumen(
    id: (j['id'] as num).toInt(),
    nombre: j['nombre'] as String,
    descripcion: (j['descripcion'] as String?) ?? '',
    comuna: j['comuna'] as String?,
    miembros: (j['miembros'] as num).toInt(),
    esMiembro: j['es_miembro'] as bool,
    miRol: j['mi_rol'] as String?,
    puntosSemana: (j['puntos_semana'] as num?)?.toInt() ?? 0,
  );
}

class MiembroResumen {
  final String alias;
  final int puntos;
  final bool esOrganizador;
  final bool esYo;

  const MiembroResumen({
    required this.alias,
    required this.puntos,
    required this.esOrganizador,
    required this.esYo,
  });

  factory MiembroResumen.fromJson(Map<String, dynamic> j) => MiembroResumen(
    alias: j['alias'] as String,
    puntos: (j['puntos'] as num).toInt(),
    esOrganizador: j['rol'] == 'administrador',
    esYo: j['es_yo'] as bool,
  );
}

class Publicacion {
  final int id;
  final String autor;
  final String texto;
  final DateTime fecha;
  final bool esPropia;

  const Publicacion({
    required this.id,
    required this.autor,
    required this.texto,
    required this.fecha,
    required this.esPropia,
  });

  factory Publicacion.fromJson(Map<String, dynamic> j) => Publicacion(
    id: (j['id'] as num).toInt(),
    autor: j['autor'] as String,
    texto: j['texto'] as String,
    fecha: DateTime.parse(j['fecha'] as String).toLocal(),
    esPropia: j['es_propio'] as bool,
  );
}

class ComunidadException implements Exception {
  final String mensaje;
  final Object? causa;

  const ComunidadException(this.mensaje, [this.causa]);

  @override
  String toString() => 'ComunidadException($mensaje, $causa)';
}

/// Comunidades, miembros y anuncios (foro de cada comunidad). Las pantallas
/// dependen solo de esta interfaz.
abstract class ComunidadesRepository {
  Future<List<ComunidadResumen>> comunidades();
  Future<int> crear({
    required String nombre,
    String? descripcion,
    String? comuna,
  });
  Future<void> unirse(int id);
  Future<void> salir(int id);
  Future<List<MiembroResumen>> miembros(int id);
  Future<List<Publicacion>> publicaciones(int id);
  Future<void> publicar(int id, String texto);
}

ComunidadesRepository comunidadesPorDefecto() => SupabaseService.disponible
    ? ComunidadesRepositorySupabase()
    : ComunidadesRepositoryMock();

/// Usa las funciones app_comunidades, app_crear_comunidad,
/// app_unirse_comunidad, app_salir_comunidad, app_miembros_comunidad,
/// app_publicaciones_comunidad y app_publicar_comunidad
/// (backend/eco_reciclaje/02_funciones_app.sql).
class ComunidadesRepositorySupabase implements ComunidadesRepository {
  final SupabaseClient _cliente;

  ComunidadesRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  @override
  Future<List<ComunidadResumen>> comunidades() async {
    final filas = await _ejecutar(() => _cliente.rpc('app_comunidades'));
    return [
      for (final f in filas as List)
        ComunidadResumen.fromJson(Map<String, dynamic>.from(f as Map)),
    ];
  }

  @override
  Future<int> crear({
    required String nombre,
    String? descripcion,
    String? comuna,
  }) async {
    final id = await _ejecutar(
      () => _cliente.rpc(
        'app_crear_comunidad',
        params: {
          'p_nombre': nombre,
          'p_descripcion': descripcion,
          'p_comuna': comuna,
        },
      ),
    );
    return (id as num).toInt();
  }

  @override
  Future<void> unirse(int id) => _ejecutar(
    () => _cliente.rpc('app_unirse_comunidad', params: {'p_id': id}),
  );

  @override
  Future<void> salir(int id) => _ejecutar(
    () => _cliente.rpc('app_salir_comunidad', params: {'p_id': id}),
  );

  @override
  Future<List<MiembroResumen>> miembros(int id) async {
    final filas = await _ejecutar(
      () => _cliente.rpc('app_miembros_comunidad', params: {'p_id': id}),
    );
    return [
      for (final f in filas as List)
        MiembroResumen.fromJson(Map<String, dynamic>.from(f as Map)),
    ];
  }

  @override
  Future<List<Publicacion>> publicaciones(int id) async {
    final filas = await _ejecutar(
      () => _cliente.rpc(
        'app_publicaciones_comunidad',
        params: {'p_id': id, 'p_limite': 50},
      ),
    );
    return [
      for (final f in filas as List)
        Publicacion.fromJson(Map<String, dynamic>.from(f as Map)),
    ];
  }

  @override
  Future<void> publicar(int id, String texto) => _ejecutar(
    () => _cliente.rpc(
      'app_publicar_comunidad',
      params: {'p_id': id, 'p_texto': texto},
    ),
  );

  Future<T> _ejecutar<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on PostgrestException catch (e) {
      debugPrint('ComunidadesRepository: $e');
      throw ComunidadException(_mensaje(e.message), e);
    } on SocketException catch (e) {
      throw ComunidadException(
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
        e,
      );
    }
  }

  String _mensaje(String codigo) => switch (codigo) {
    'nombre_invalido' => 'El nombre debe tener entre 3 y 100 caracteres.',
    'descripcion_invalida' => 'La descripción no puede superar 500 caracteres.',
    'limite_comunidades' => 'Ya creaste 3 comunidades, el máximo por persona.',
    'no_es_miembro' => 'Únete a la comunidad para publicar.',
    'texto_invalido' => 'El anuncio debe tener entre 1 y 1000 caracteres.',
    'limite_publicaciones' =>
      'Llegaste al máximo de 20 anuncios por día. Inténtalo mañana.',
    'comunidad_no_encontrada' => 'Esa comunidad ya no existe.',
    'sesion_requerida' =>
      'No hay sesión activa. Cierra y vuelve a abrir la app.',
    _ => 'Algo salió mal. Inténtalo de nuevo en unos minutos.',
  };
}

/// Demo sin Supabase: guarda todo en memoria.
class ComunidadesRepositoryMock implements ComunidadesRepository {
  final List<ComunidadResumen> _comunidades = [
    const ComunidadResumen(
      id: 1,
      nombre: 'Vecinos de Ñuñoa',
      descripcion: 'Coordinamos días de recolección y avisamos puntos llenos.',
      comuna: 'Ñuñoa',
      miembros: 3,
      esMiembro: false,
      miRol: null,
      puntosSemana: 420,
    ),
  ];
  final Map<int, List<Publicacion>> _publicaciones = {
    1: [
      Publicacion(
        id: 1,
        autor: 'Camila R.',
        texto: 'El punto limpio de Plaza Ñuñoa está lleno, mejor ir mañana.',
        fecha: DateTime.now().subtract(const Duration(hours: 3)),
        esPropia: false,
      ),
    ],
  };

  ComunidadResumen _con(
    ComunidadResumen c, {
    required bool miembro,
    String? rol,
  }) => ComunidadResumen(
    id: c.id,
    nombre: c.nombre,
    descripcion: c.descripcion,
    comuna: c.comuna,
    miembros: c.miembros + (miembro == c.esMiembro ? 0 : (miembro ? 1 : -1)),
    esMiembro: miembro,
    miRol: miembro ? rol ?? 'miembro' : null,
    puntosSemana: c.puntosSemana,
  );

  void _reemplazar(int id, ComunidadResumen Function(ComunidadResumen) f) {
    final i = _comunidades.indexWhere((c) => c.id == id);
    if (i >= 0) _comunidades[i] = f(_comunidades[i]);
  }

  @override
  Future<List<ComunidadResumen>> comunidades() async => List.of(_comunidades);

  @override
  Future<int> crear({
    required String nombre,
    String? descripcion,
    String? comuna,
  }) async {
    final id = _comunidades.length + 1;
    _comunidades.add(
      ComunidadResumen(
        id: id,
        nombre: nombre,
        descripcion: descripcion ?? '',
        comuna: comuna,
        miembros: 1,
        esMiembro: true,
        miRol: 'administrador',
        puntosSemana: 0,
      ),
    );
    return id;
  }

  @override
  Future<void> unirse(int id) async =>
      _reemplazar(id, (c) => _con(c, miembro: true));

  @override
  Future<void> salir(int id) async =>
      _reemplazar(id, (c) => _con(c, miembro: false));

  @override
  Future<List<MiembroResumen>> miembros(int id) async => const [
    MiembroResumen(
      alias: 'Camila R.',
      puntos: 640,
      esOrganizador: true,
      esYo: false,
    ),
    MiembroResumen(
      alias: 'Diego M.',
      puntos: 310,
      esOrganizador: false,
      esYo: false,
    ),
  ];

  @override
  Future<List<Publicacion>> publicaciones(int id) async =>
      List.of(_publicaciones[id] ?? const []);

  @override
  Future<void> publicar(int id, String texto) async {
    (_publicaciones[id] ??= []).insert(
      0,
      Publicacion(
        id: DateTime.now().millisecondsSinceEpoch,
        autor: 'Usuario anónimo',
        texto: texto,
        fecha: DateTime.now(),
        esPropia: true,
      ),
    );
  }
}
