import 'movimiento_punto.dart';

/// Usuario de la tabla `usuarios` de Supabase (esquema remoto, ver
/// docs/esquema-remoto.md del repo rebin). `id` es `usuarios.id_usuario`, que
/// es el mismo uuid que auth.uid(). En modo invitado `correo` es null.
///
/// Ninguno de los totales es una columna: `puntosTotales` es la suma de
/// `movimientos_puntos` (ledger) y el resto son conteos de `reciclajes`,
/// `reportes_punto` y `logros_usuario`, ver UsuarioRepositorySupabase.
class Usuario {
  /// `usuarios.id_usuario` = auth.uid().
  final String id;

  /// Correo verificado; null en modo invitado (sesión anónima).
  final String? correo;

  /// true cuando el registro terminó con contraseña (user_metadata
  /// `tiene_password` de Supabase Auth). Con correo pero sin contraseña el
  /// Perfil ofrece terminar el registro.
  final bool tieneContrasena;

  /// Nombre real (user_metadata `nombre` de Supabase Auth: `usuarios` no
  /// tiene columna para él); null hasta que completa la bienvenida.
  final String? nombre;

  /// Alias visible (columna `alias` de `usuarios`). Lo llena el trigger
  /// handle_new_auth_user al crear la cuenta y se cambia en la bienvenida.
  final String alias;
  final DateTime fechaRegistro;
  final int puntosTotales;
  final int objetosEscaneados;
  final int reportesHechos;
  final int logrosObtenidos;

  /// Últimos movimientos de puntos, del más reciente al más antiguo.
  final List<MovimientoPunto> movimientos;

  const Usuario({
    required this.id,
    required this.alias,
    required this.fechaRegistro,
    required this.puntosTotales,
    this.correo,
    this.tieneContrasena = false,
    this.nombre,
    this.objetosEscaneados = 0,
    this.reportesHechos = 0,
    this.logrosObtenidos = 0,
    this.movimientos = const [],
  });

  factory Usuario.fromSupabaseRow(
    Map<String, dynamic> fila, {
    required int puntosTotales,
    String? nombre,
    bool tieneContrasena = false,
    int objetosEscaneados = 0,
    int reportesHechos = 0,
    int logrosObtenidos = 0,
    List<MovimientoPunto> movimientos = const [],
  }) {
    return Usuario(
      id: fila['id_usuario'] as String,
      correo: fila['correo_electronico'] as String?,
      tieneContrasena: tieneContrasena,
      nombre: nombre,
      alias: fila['alias'] as String,
      fechaRegistro: DateTime.parse(fila['fecha_creacion'] as String),
      puntosTotales: puntosTotales,
      objetosEscaneados: objetosEscaneados,
      reportesHechos: reportesHechos,
      logrosObtenidos: logrosObtenidos,
      movimientos: movimientos,
    );
  }

  /// true mientras falte el nombre real: la APK muestra la bienvenida
  /// obligatoria (nombre, alias y permisos) antes de entrar.
  bool get esInvitado => correo == null;

  bool get faltanDatos => nombre == null || nombre!.trim().isEmpty;
}
