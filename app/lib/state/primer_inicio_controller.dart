import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Banderas locales del primer inicio tras instalar la app. Viven en
/// SharedPreferences, así que solo se reinician al desinstalar o borrar los
/// datos de la app; iniciar o cerrar sesión no las toca.
class PrimerInicioController extends ChangeNotifier {
  static const _claveCompletado = 'primer_inicio_completado';
  static const _clavePermisos = 'permisos_solicitados';
  static const _claveOnboarding = 'onboarding_visto';

  bool _completado;
  bool _permisosSolicitados;
  bool _onboardingVisto;

  PrimerInicioController._(
    this._completado,
    this._permisosSolicitados,
    this._onboardingVisto,
  );

  static Future<PrimerInicioController> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    return PrimerInicioController._(
      prefs.getBool(_claveCompletado) ?? false,
      prefs.getBool(_clavePermisos) ?? false,
      prefs.getBool(_claveOnboarding) ?? false,
    );
  }

  /// true cuando ya pasó (o saltó) las 3 láminas de presentación. Quien
  /// completó el primer inicio antes de que existieran nunca las ve, porque
  /// la bienvenida ya no se le abre.
  bool get onboardingVisto => _onboardingVisto;

  Future<void> marcarOnboardingVisto() async {
    _onboardingVisto = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveOnboarding, true);
  }

  /// true cuando terminó el flujo de acceso, alias y permisos. Desde ahí la
  /// app abre directo en el MainShell.
  bool get completado => _completado;

  /// true desde que se le mostraron los permisos de ubicación y
  /// notificaciones (los haya aceptado, rechazado u omitido). Nunca se le
  /// vuelven a pedir automáticamente; quedan en Perfil › Ajustes.
  bool get permisosSolicitados => _permisosSolicitados;

  Future<void> marcarPermisosSolicitados() async {
    _permisosSolicitados = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clavePermisos, true);
  }

  Future<void> completar() async {
    _completado = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveCompletado, true);
  }
}

class PrimerInicioScope extends InheritedNotifier<PrimerInicioController> {
  const PrimerInicioScope({
    super.key,
    required PrimerInicioController controller,
    required super.child,
  }) : super(notifier: controller);

  static PrimerInicioController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PrimerInicioScope>();
    assert(scope != null, 'PrimerInicioScope no encontrado en el árbol');
    return scope!.notifier!;
  }
}
