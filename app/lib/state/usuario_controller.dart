import 'package:flutter/widgets.dart';

import '../models/nivel.dart';
import '../models/resumen_puntos.dart';
import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';
import '../services/nivel_visto_store.dart';
import '../services/resumen_puntos_store.dart';

/// Usuario remoto (puntos, fecha de alta), compartido por Inicio, Comunidad y
/// Perfil. Carga en segundo plano: la app no espera a la red para abrir.
///
/// Cada carga exitosa guarda una copia de los puntos y niveles en el
/// teléfono ([resumen]); si después no hay conexión, el Perfil muestra esa
/// copia ([resumenDesdeCopia]) en vez de nada.
class UsuarioController extends ChangeNotifier {
  final UsuarioRepository _repositorio;
  final ResumenPuntosStore _copia;
  final NivelVistoStore _nivelVisto;

  /// Id de la sesión actual aunque no haya red (Supabase la guarda en el
  /// teléfono), para no mostrar la copia de otra cuenta. Null = sin Supabase.
  final String? Function() _idSesion;

  /// Hora actual (reemplazable en tests).
  final DateTime Function() _ahora;

  UsuarioController(
    this._repositorio, {
    ResumenPuntosStore? copia,
    NivelVistoStore? nivelVisto,
    String? Function()? idSesion,
    DateTime Function()? ahora,
  }) : _copia = copia ?? ResumenPuntosStore(),
       _nivelVisto = nivelVisto ?? NivelVistoStore(),
       _idSesion = idSesion ?? (() => null),
       _ahora = ahora ?? DateTime.now;

  /// Al pasar de una pestaña a otra no se vuelve a leer si la última carga
  /// exitosa es más nueva que esto (ver [cargarSiHaceFalta]).
  static const vigencia = Duration(seconds: 20);
  DateTime? _cargadoEn;

  Usuario? _usuario;
  ResumenPuntos? _resumen;
  bool _resumenDesdeCopia = false;
  bool _cargando = false;
  Object? _error;
  bool _intentado = false;
  Nivel? _nivelPorCelebrar;

  Usuario? get usuario => _usuario;

  /// Puntos y nivel: los de Supabase o, sin conexión, la última copia.
  ResumenPuntos? get resumen => _resumen;

  /// true cuando [resumen] es la copia guardada y no un dato recién leído.
  bool get resumenDesdeCopia => _resumenDesdeCopia;
  bool get cargando => _cargando;
  Object? get error => _error;

  /// true desde que terminó el primer intento de carga (con o sin éxito).
  bool get intentado => _intentado;

  /// Nivel recién alcanzado que todavía no se celebró; null si no hay. Lo
  /// muestra el MainShell y luego llama a [celebracionMostrada].
  Nivel? get nivelPorCelebrar => _nivelPorCelebrar;

  void celebracionMostrada() {
    if (_nivelPorCelebrar == null) return;
    _nivelPorCelebrar = null;
    notifyListeners();
  }

  /// Recarga solo si la última carga exitosa tiene más de [vigencia]: cambiar
  /// de pestaña seguido no repite las mismas consultas. Tras una acción que
  /// cambia los puntos (reportar, canjear, reciclar) usar [cargar].
  Future<void> cargarSiHaceFalta() async {
    final ultima = _cargadoEn;
    if (ultima != null && _ahora().difference(ultima) < vigencia) return;
    await cargar();
  }

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuario = await _obtenerConReintento();
      await _actualizarResumen(_usuario!);
      await _revisarNivel();
      _cargadoEn = _ahora();
    } catch (e) {
      debugPrint('UsuarioController: no se pudo cargar el usuario ($e)');
      _error = e;
      await _usarCopia();
    } finally {
      _cargando = false;
      _intentado = true;
      notifyListeners();
    }
  }

  /// Justo después de abrir la sesión, Supabase a veces rechaza el token por
  /// unos segundos ("JWT issued at future", PGRST303: el reloj de quien lo
  /// emite va un poco adelantado). Ese error se reintenta una vez, tras una
  /// pausa corta; cualquier otro se informa de inmediato.
  Future<Usuario> _obtenerConReintento() async {
    try {
      return await _repositorio.obtenerOCrear();
    } catch (e) {
      if (!esTokenDelFuturo(e)) rethrow;
      debugPrint('UsuarioController: token aún no vigente, se reintenta');
      await Future<void>.delayed(pausaReintento);
      return _repositorio.obtenerOCrear();
    }
  }

  /// Pausa antes de reintentar un token "del futuro".
  static const pausaReintento = Duration(milliseconds: 1500);

  /// Guarda el alias y el nombre (opcional). Lanza si falla.
  Future<void> guardarDatos({required String alias, String? nombre}) async {
    _usuario = await _repositorio.guardarDatos(nombre: nombre, alias: alias);
    await _actualizarResumen(_usuario!);
    notifyListeners();
  }

  /// Arma el resumen con lo recién leído y lo guarda como copia. Si la nube
  /// no entregó los niveles, conserva los de la copia anterior.
  Future<void> _actualizarResumen(Usuario usuario) async {
    final anterior = _resumen ?? await _copia.cargar();
    _resumen = ResumenPuntos(
      idUsuario: usuario.id,
      saldo: usuario.puntosTotales,
      acumulado: usuario.puntosAcumulados,
      niveles: usuario.niveles ?? anterior?.niveles ?? Nivel.porDefecto,
      actualizado: DateTime.now(),
    );
    _resumenDesdeCopia = false;
    try {
      await _copia.guardar(_resumen!);
    } catch (e) {
      debugPrint('UsuarioController: no se pudo guardar la copia ($e)');
    }
  }

  /// Compara el nivel recién leído con el último visto en este teléfono. La
  /// primera vez de una cuenta solo lo guarda (no se celebra lo que ya
  /// tenía); si subió, queda en [nivelPorCelebrar]. Nunca con la copia sin
  /// conexión, solo con datos recién leídos.
  Future<void> _revisarNivel() async {
    final resumen = _resumen;
    if (resumen == null) return;
    final actual = resumen.nivelActual;
    final visto = await _nivelVisto.leer(resumen.idUsuario);
    if (visto == null || actual.puntosMinimos != visto) {
      await _nivelVisto.guardar(resumen.idUsuario, actual.puntosMinimos);
    }
    if (visto != null && actual.puntosMinimos > visto) {
      _nivelPorCelebrar = actual;
    }
  }

  /// Sin conexión: muestra la última copia si es de esta misma cuenta.
  Future<void> _usarCopia() async {
    final idSesion = _idSesion();
    bool esDeEstaCuenta(ResumenPuntos r) =>
        idSesion == null || r.idUsuario == idSesion;

    // Datos de una carga anterior de esta misma cuenta: se mantienen.
    if (_resumen != null && esDeEstaCuenta(_resumen!)) return;
    _resumen = null;
    final copia = await _copia.cargar();
    if (copia == null || !esDeEstaCuenta(copia)) return;
    _resumen = copia;
    _resumenDesdeCopia = true;
  }
}

/// true si [error] (o el que envuelve un ParallelWaitError) es el rechazo
/// momentáneo "JWT issued at future" (PGRST303).
bool esTokenDelFuturo(Object error) {
  final texto = error.toString();
  return texto.contains('PGRST303') || texto.contains('JWT issued at future');
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
