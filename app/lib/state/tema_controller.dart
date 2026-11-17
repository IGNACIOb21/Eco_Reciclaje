import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_themes.dart';

/// Tema de la app (ver TemaApp). Es una preferencia del teléfono, no de la
/// cuenta: se mantiene al iniciar o cerrar sesión y solo vuelve al valor por
/// defecto (Modo claro) al desinstalar o borrar los datos de la app.
class TemaController extends ChangeNotifier {
  static const _clave = 'tema_app';

  /// Clave de versiones anteriores (solo Eco o claro): se respeta si el
  /// usuario ya había elegido uno.
  static const _claveAntigua = 'modo_eco';

  TemaApp _tema;

  TemaController._(this._tema);

  /// Temas que se pueden elegir: solo el claro y el Eco (interruptor "Modo
  /// Eco" en Perfil). Los demás de TemaApp ya no se ofrecen.
  static const disponibles = {TemaApp.claro, TemaApp.eco};

  static Future<TemaController> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = TemaApp.desdeNombre(prefs.getString(_clave));
    final antiguo = prefs.getBool(_claveAntigua);
    final tema =
        guardado ??
        (antiguo == null
            ? TemaApp.porDefecto
            : (antiguo ? TemaApp.eco : TemaApp.claro));
    // Quien había elegido otro tema (Nórdico, Terracota…) vuelve al claro.
    return TemaController._(
      disponibles.contains(tema) ? tema : TemaApp.porDefecto,
    );
  }

  TemaApp get tema => _tema;

  Future<void> cambiar(TemaApp tema) async {
    if (tema == _tema) return;
    _tema = tema;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, tema.name);
  }
}

class TemaScope extends InheritedNotifier<TemaController> {
  const TemaScope({
    super.key,
    required TemaController controller,
    required super.child,
  }) : super(notifier: controller);

  static TemaController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TemaScope>();
    assert(scope != null, 'TemaScope no encontrado en el árbol');
    return scope!.notifier!;
  }
}
