import '../data/mock/recolectores_mock.dart';
import '../models/recolector_particular.dart';
import 'recolectores_repository.dart';

/// Implementación de maqueta: sirve los recolectores de ejemplo en memoria,
/// simulando la latencia de una llamada real.
class RecolectoresRepositoryMock implements RecolectoresRepository {
  /// Si es true, `obtenerRecolectores` lanza una excepción en vez de
  /// devolver datos — forma simple de mostrar el estado de error en la
  /// demo. Ej: `RecolectoresRepositoryMock(forzarError: true)`.
  final bool forzarError;

  RecolectoresRepositoryMock({this.forzarError = false});

  @override
  Future<List<RecolectorParticular>> obtenerRecolectores() async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (forzarError) {
      throw Exception(
        'Error simulado: no se pudieron cargar los recolectores.',
      );
    }

    return recolectoresMock;
  }
}
