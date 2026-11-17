/// Vincular la sesión anónima a un correo con contraseña, e iniciar sesión
/// con esa cuenta en otro dispositivo.
abstract class CuentaRepository {
  /// Asocia [correo] a la cuenta de esta sesión y envía el código de
  /// verificación a ese correo.
  Future<void> enviarCodigo(String correo);

  /// Vuelve a enviar el código al mismo correo.
  Future<void> reenviarCodigo(String correo);

  /// Confirma el correo si [codigo] coincide con el enviado.
  Future<void> verificarCodigo(String correo, String codigo);

  /// Define la contraseña de la cuenta (después de verificar el correo).
  Future<void> crearContrasena(String contrasena);

  /// Reemplaza la sesión actual por la de la cuenta [correo]. Devuelve el
  /// auth.uid() de esa cuenta.
  Future<String> iniciarSesion(String correo, String contrasena);

  /// true si la sesión actual es de una cuenta con correo vinculado (no un
  /// invitado). Solo esas cuentas pueden cerrar sesión: un invitado no tiene
  /// cómo volver a entrar y perdería sus puntos.
  bool get tieneCorreoVinculado;

  /// Cierra la sesión de la cuenta y abre una de invitado nueva, para que la
  /// app siga funcionando. Devuelve el auth.uid() de esa sesión nueva.
  Future<String> cerrarSesion();
}

enum MotivoErrorCuenta {
  correoYaRegistrado,
  codigoIncorrecto,
  demasiadosIntentos,
  contrasenaDebil,
  credencialesInvalidas,
  sinConexion,
  errorServidor,
  desconocido,
}

class CuentaException implements Exception {
  final MotivoErrorCuenta motivo;
  final Object? causa;

  const CuentaException(this.motivo, [this.causa]);

  String get mensaje => switch (motivo) {
    MotivoErrorCuenta.correoYaRegistrado =>
      'Este correo ya tiene una cuenta. Inicia sesión con él.',
    MotivoErrorCuenta.codigoIncorrecto =>
      'El código no coincide o ya venció. Revísalo o pide uno nuevo.',
    MotivoErrorCuenta.demasiadosIntentos =>
      'Demasiados intentos. Espera un minuto y vuelve a intentarlo.',
    MotivoErrorCuenta.contrasenaDebil =>
      'La contraseña no cumple los requisitos.',
    MotivoErrorCuenta.credencialesInvalidas =>
      'Correo o contraseña incorrectos.',
    MotivoErrorCuenta.sinConexion =>
      'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
    MotivoErrorCuenta.errorServidor =>
      'El servidor no pudo completar la solicitud. Inténtalo de nuevo en '
          'unos minutos.',
    MotivoErrorCuenta.desconocido =>
      'Algo salió mal. Inténtalo de nuevo en unos minutos.',
  };

  @override
  String toString() => 'CuentaException($motivo, $causa)';
}
