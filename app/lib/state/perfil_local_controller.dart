import 'package:flutter/widgets.dart';

import '../models/perfil_local.dart';
import '../services/perfil_local_store.dart';

class PerfilLocalController extends ChangeNotifier {
  final PerfilLocalStore _store;

  /// Clave bajo la que se guarda la personalización: el auth.uid() de la
  /// cuenta de Supabase si hay sesión (así una cuenta nueva parte de cero), o
  /// el device_id del modo invitado sin Supabase.
  String _clave;
  PerfilLocal _perfil;

  PerfilLocalController._(this._store, this._clave, this._perfil);

  String get clave => _clave;

  static Future<PerfilLocalController> cargar({
    PerfilLocalStore? store,
    String? clave,
  }) async {
    final s = store ?? PerfilLocalStore();
    final c = clave ?? await s.obtenerDeviceId();
    final perfil = await s.cargar(c);
    return PerfilLocalController._(s, c, perfil);
  }

  PerfilLocal get perfil => _perfil;

  /// Cambia a la personalización de otra cuenta (ej. al iniciar sesión con
  /// correo). Si esa cuenta nunca se personalizó en este teléfono, parte con
  /// [nombreInicial] (su alias) como nombre visible.
  Future<void> cambiarClave(String clave, {String? nombreInicial}) async {
    _clave = clave;
    var perfil = await _store.cargar(clave);
    if (perfil.esAnonimo && nombreInicial != null) {
      perfil = perfil.copyWith(nombre: nombreInicial);
      await _store.guardar(clave, perfil);
    }
    _perfil = perfil;
    notifyListeners();
  }

  Future<void> actualizar(PerfilLocal nuevo) async {
    _perfil = nuevo;
    notifyListeners();
    await _store.guardar(_clave, nuevo);
  }
}

class PerfilLocalScope extends InheritedNotifier<PerfilLocalController> {
  const PerfilLocalScope({
    super.key,
    required PerfilLocalController controller,
    required super.child,
  }) : super(notifier: controller);

  static PerfilLocalController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PerfilLocalScope>();
    assert(scope != null, 'PerfilLocalScope no encontrado en el árbol');
    return scope!.notifier!;
  }
}
