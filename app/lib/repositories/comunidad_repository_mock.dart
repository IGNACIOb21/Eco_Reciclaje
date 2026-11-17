import '../models/comunidad_hoy.dart';
import 'comunidad_repository.dart';

/// Datos de ejemplo para la demo sin Supabase (textos del lienzo corregido,
/// en objetos).
class ComunidadRepositoryMock implements ComunidadRepository {
  bool oculto = false;
  final DateTime Function() _ahora;

  ComunidadRepositoryMock({DateTime Function()? ahora})
    : _ahora = ahora ?? DateTime.now;

  @override
  Future<MetaComuna> metaComuna(String comuna) async => MetaComuna(
    comuna: comuna,
    objetivo: 2500,
    actual: 1710,
    vecinos: 812,
    tuAporte: 38,
    diasRestantes: 16,
  );

  @override
  Future<List<ActividadComuna>> actividad(String comuna) async {
    final ahora = _ahora();
    return [
      ActividadComuna(
        tipo: TipoActividad.reporte,
        alias: 'Vale',
        texto: 'reportó Punto Limpio Plaza $comuna: todo en orden',
        fecha: ahora.subtract(const Duration(minutes: 20)),
      ),
      ActividadComuna(
        tipo: TipoActividad.reciclaje,
        alias: 'Vecinos',
        texto: 'se reciclaron 9 objetos en Campana Av. Grecia',
        fecha: ahora.subtract(const Duration(hours: 3)),
      ),
      ActividadComuna(
        tipo: TipoActividad.puntoNuevo,
        alias: 'Cami',
        texto: 'agregó el punto Campana de vidrio Suecia 1520',
        fecha: ahora.subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<PuestoRanking>> ranking() async => [
    const PuestoRanking(posicion: 1, alias: 'Vale', puntos: 214, esTuyo: false),
    const PuestoRanking(
      posicion: 2,
      alias: 'Diego',
      puntos: 190,
      esTuyo: false,
    ),
    const PuestoRanking(posicion: 3, alias: 'Fran', puntos: 152, esTuyo: false),
    if (!oculto)
      const PuestoRanking(posicion: 4, alias: 'Tú', puntos: 117, esTuyo: true),
    const PuestoRanking(posicion: 5, alias: 'Cami', puntos: 96, esTuyo: false),
  ];

  @override
  Future<void> ocultarRanking(bool oculto) async => this.oculto = oculto;
}
