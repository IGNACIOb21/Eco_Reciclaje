import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'cuenta_repository.dart';

/// Convierte la sesión anónima en una cuenta permanente con el flujo oficial
/// de Supabase Auth: es el mismo auth.uid(), así que se conservan la fila de
/// `usuario`, los puntos y todo lo demás.
///
/// 1. updateUser(email) envía el correo "Change Email Address" con el código
///    ({{ .Token }} en la plantilla, largo configurado en Auth → Email OTP
///    Length = 8).
/// 2. verifyOTP(type: emailChange) confirma el correo; el trigger
///    handle_auth_user_email_change lo copia a usuario.correo_electronico.
/// 3. updateUser(password) guarda la contraseña (hash bcrypt en auth.users,
///    nadie puede leerla). Se marca `tiene_password` en user_metadata para
///    saber si el registro quedó completo.
class CuentaRepositorySupabase implements CuentaRepository {
  final SupabaseClient _cliente;

  CuentaRepositorySupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? SupabaseService.cliente;

  @override
  Future<void> enviarCodigo(String correo) => _envolver(
    () => _cliente.auth.updateUser(UserAttributes(email: correo.trim())),
  );

  @override
  Future<void> reenviarCodigo(String correo) => _envolver(
    () => _cliente.auth.resend(type: OtpType.emailChange, email: correo.trim()),
  );

  @override
  Future<void> verificarCodigo(String correo, String codigo) => _envolver(
    () => _cliente.auth.verifyOTP(
      type: OtpType.emailChange,
      email: correo.trim(),
      token: codigo.trim(),
    ),
  );

  @override
  Future<void> crearContrasena(String contrasena) => _envolver(
    () => _cliente.auth.updateUser(
      UserAttributes(password: contrasena, data: {'tiene_password': true}),
    ),
  );

  @override
  Future<String> iniciarSesion(String correo, String contrasena) async {
    final respuesta = await _envolver(
      () => _cliente.auth.signInWithPassword(
        email: correo.trim(),
        password: contrasena,
      ),
    );
    return respuesta.user!.id;
  }

  Future<T> _envolver<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AuthRetryableFetchException catch (e) {
      // Va antes que AuthException porque hereda de ella.
      throw CuentaException(MotivoErrorCuenta.sinConexion, e);
    } on AuthException catch (e) {
      throw CuentaException(_motivo(e), e);
    } on SocketException catch (e) {
      throw CuentaException(MotivoErrorCuenta.sinConexion, e);
    }
  }

  MotivoErrorCuenta _motivo(AuthException e) {
    switch (e.code) {
      case 'email_exists':
      case 'user_already_exists':
        return MotivoErrorCuenta.correoYaRegistrado;
      case 'otp_expired':
      case 'otp_disabled':
        return MotivoErrorCuenta.codigoIncorrecto;
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return MotivoErrorCuenta.demasiadosIntentos;
      case 'weak_password':
        return MotivoErrorCuenta.contrasenaDebil;
      case 'invalid_credentials':
        return MotivoErrorCuenta.credencialesInvalidas;
    }
    if (e.statusCode == '429') return MotivoErrorCuenta.demasiadosIntentos;
    return MotivoErrorCuenta.desconocido;
  }
}
