import 'package:flutter/foundation.dart';

import '../models/mi_reporte.dart';
import '../models/tipo_reporte.dart';
import '../repositories/acciones_repository.dart';

/// Estado de "Mis reportes": los reportes del usuario (`app_mis_reportes`)
/// agrupados por tipo. La pantalla muestra una tarjeta por cada tipo; si la
/// persona no tiene reportes de un tipo, avisa con [sinReportesEn].
class MisReportesController extends ChangeNotifier {
  final AccionesRepository _repositorio;

  MisReportesController(this._repositorio);

  List<MiReporte> _todos = const [];
  bool _cargando = true;
  Object? _error;

  bool get cargando => _cargando;
  Object? get error => _error;

  /// Todos los reportes leídos, del más nuevo al más viejo.
  List<MiReporte> get todos => _todos;

  /// Lee los reportes de la base.
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _todos = await _repositorio.misReportes();
    } catch (e) {
      debugPrint('MisReportesController: no se pudieron leer ($e)');
      _error = e;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Los reportes de [tipo], del más nuevo al más viejo. Vacío = la pantalla
  /// no abre el historial y avisa "Sin reportes en …".
  List<MiReporte> reportesDe(TipoReporte tipo) =>
      _todos.where((r) => r.tipo == tipo).toList();

  /// "Sin reportes en Fuera de servicio".
  static String sinReportesEn(TipoReporte tipo) =>
      'Sin reportes en ${tipo.etiqueta}';

  /// Subtítulo de la tarjeta de [tipo]: cuántos hay y cómo va el último.
  String resumenDe(TipoReporte tipo) {
    final reportes = reportesDe(tipo);
    if (reportes.isEmpty) return 'Sin reportes';
    final cuantos = reportes.length == 1
        ? '1 reporte'
        : '${reportes.length} reportes';
    return '$cuantos · último: ${reportes.first.avance}';
  }
}
