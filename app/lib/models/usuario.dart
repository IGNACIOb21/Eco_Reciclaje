import 'movimiento_punto.dart';
import 'nivel.dart';

/// Usuario de la tabla `usuarios` de Supabase (esquema remoto, ver
/// docs/esquema-remoto.md del repo rebin). `id` es `usuarios.id_usuario`, que
/// es el mismo uuid que auth.uid(). En modo invitado `correo` es null.
///
/// Ninguno de los totales es una columna: `puntosTotales` es la suma de
/// `movimientos_puntos` (ledger) y el resto son conteos de `reciclajes`,
/// `reporte_punto` y `logros_usuario`, ver UsuarioRepositorySupabase.
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
  /// tiene columna para él); opcional, null si no lo dio en la bienvenida.
  final String? nombre;

  /// Alias visible (columna `alias` de `usuarios`). Lo llena el trigger
  /// handle_new_auth_user al crear la cuenta y se cambia en la bienvenida.
  final String alias;
  final DateTime fechaRegistro;

  /// Saldo: suma de todos los movimientos, canjes incluidos.
  final int puntosTotales;

  /// Puntos ganados en toda la historia (sin descontar canjes): define el
  /// nivel. Si no se informa, se asume igual al saldo.
  final int puntosAcumulados;

  /// Umbrales de la tabla `niveles` de la nube; null si no se pudieron leer.
  final List<Nivel>? niveles;

  /// Días consecutivos con alguna acción que dio puntos (`usuarios.racha_actual`).
  final int racha;
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
    int? puntosAcumulados,
    this.niveles,
    this.racha = 0,
    this.correo,
    this.tieneContrasena = false,
    this.nombre,
    this.objetosEscaneados = 0,
    this.reportesHechos = 0,
    this.logrosObtenidos = 0,
    this.movimientos = const [],
  }) : puntosAcumulados = puntosAcumulados ?? puntosTotales;

  factory Usuario.fromSupabaseRow(
    Map<String, dynamic> fila, {
    required int puntosTotales,
    int? puntosAcumulados,
    List<Nivel>? niveles,
    int racha = 0,
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
      puntosAcumulados: puntosAcumulados,
      niveles: niveles,
      racha: racha,
      objetosEscaneados: objetosEscaneados,
      reportesHechos: reportesHechos,
      logrosObtenidos: logrosObtenidos,
      movimientos: movimientos,
    );
  }

  /// true en una sesión anónima (sin correo vinculado).
  bool get esInvitado => correo == null;
}
