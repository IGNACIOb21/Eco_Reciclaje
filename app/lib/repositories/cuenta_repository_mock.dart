import 'cuenta_repository.dart';

/// Registro de ejemplo sin Supabase (demo y tests): el código válido es
/// siempre [codigoValido] y la única cuenta es la que se registra.
class CuentaRepositoryMock implements CuentaRepository {
  static const codigoValido = '12345678';

  String? _correo;
  String? _contrasena;
  bool _verificado = false;
  bool _conCorreo;

  /// [conCorreo] simula una sesión que ya tiene correo vinculado.
  CuentaRepositoryMock({bool conCorreo = false})
    : _conCorreo = conCorreo; // ignore: prefer_initializing_formals

  @override
  bool get tieneCorreoVinculado => _conCorreo;

  @override
  Future<String> cerrarSesion() async {
    _conCorreo = false;
    return 'mock-invitado';
  }

  @override
  Future<void> enviarCodigo(String correo) async {
    if (correo.trim().toLowerCase() == 'ocupado@rebin.cl') {
      throw const CuentaException(MotivoErrorCuenta.correoYaRegistrado);
    }
    _correo = correo.trim();
    _verificado = false;
  }

  @override
  Future<void> reenviarCodigo(String correo) async {}

  @override
  Future<void> verificarCodigo(String correo, String codigo) async {
    if (correo.trim() != _correo || codigo.trim() != codigoValido) {
      throw const CuentaException(MotivoErrorCuenta.codigoIncorrecto);
    }
    _verificado = true;
  }

  @override
  Future<void> crearContrasena(String contrasena) async {
    if (!_verificado) {
      throw const CuentaException(MotivoErrorCuenta.desconocido);
    }
    _contrasena = contrasena;
    _conCorreo = true;
  }

  @override
  Future<String> iniciarSesion(String correo, String contrasena) async {
    if (correo.trim() != _correo || contrasena != _contrasena) {
      throw const CuentaException(MotivoErrorCuenta.credencialesInvalidas);
    }
    _conCorreo = true;
    return 'mock';
  }
}
