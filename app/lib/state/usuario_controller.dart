import 'package:flutter/widgets.dart';

import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';

/// Usuario remoto (puntos, fecha de alta), compartido por Inicio, Comunidad y
/// Perfil. Carga en segundo plano: la app no espera a la red para abrir.
class UsuarioController extends ChangeNotifier {
  final UsuarioRepository _repositorio;
  UsuarioController(this._repositorio);

  Usuario? _usuario;
  bool _cargando = false;
  Object? _error;
  bool _intentado = false;

  Usuario? get usuario => _usuario;
  bool get cargando => _cargando;
  Object? get error => _error;

  /// true desde que terminó el primer intento de carga (con o sin éxito).
  bool get intentado => _intentado;

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuario = await _repositorio.obtenerOCrear();
    } catch (e) {
      debugPrint('UsuarioController: no se pudo cargar el usuario ($e)');
      _error = e;
    } finally {
      _cargando = false;
      _intentado = true;
      notifyListeners();
    }
  }

  /// Guarda nombre y alias. Lanza si falla, para que el formulario muestre
  /// el error y deje reintentar.
  Future<void> guardarDatos({
    required String nombre,
    required String alias,
  }) async {
    _usuario = await _repositorio.guardarDatos(nombre: nombre, alias: alias);
    notifyListeners();
  }
}

class UsuarioScope extends InheritedNotifier<UsuarioController> {
  const UsuarioScope({
    super.key,
    required UsuarioController controller,
    required super.child,
  }) : super(notifier: controller);

  static UsuarioController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UsuarioScope>();
    assert(scope != null, 'UsuarioScope no encontrado en el árbol');
    return scope!.notifier!;
  }
}
