import '../models/resumen_hoy.dart';
import 'gamificacion_repository.dart';

/// Datos de ejemplo del diseño (racha de 6 días, meta pendiente), para la demo
/// sin Supabase. Los reales salen de `GamificacionRepositorySupabase`. Los
/// congeladores y el saldo viven en memoria mientras la app está abierta.
class GamificacionRepositoryMock implements GamificacionRepository {
  bool metaCumplida;
  final int racha;
  int congeladores;
  int saldo;
  bool sorpresaDisponible;
  bool sorpresaAbierta = false;

  /// Máximo de congeladores (0 = la base aún no los ofrece, como hoy).
  final int maxCongeladores;
  static const _costo = 20;
  static const _puntosSorpresa = 3;

  GamificacionRepositoryMock({
    this.metaCumplida = false,
    this.racha = 6,
    this.congeladores = 1,
    this.saldo = 524,
    this.sorpresaDisponible = true,
    this.maxCongeladores = 2,
  });

  @override
  Future<ResumenHoy> resumenHoy() async {
    // Semana de ejemplo con "hoy" en jueves.
    const estados = [
      EstadoDia.hecho,
      EstadoDia.hecho,
      EstadoDia.congelado,
      EstadoDia.hoy,
      EstadoDia.futuro,
      EstadoDia.futuro,
      EstadoDia.futuro,
    ];
    final lunes = DateTime(2026, 10, 12);
    return ResumenHoy(
      metaCumplida: metaCumplida,
      metaActual: metaCumplida ? 1 : 0,
      metaObjetivo: 1,
      racha: racha,
      rachaMaxima: racha > 12 ? racha : 12,
      semana: [
        for (var i = 0; i < estados.length; i++)
          DiaRacha(lunes.add(Duration(days: i)), estados[i]),
      ],
      congeladores: congeladores,
      maxCongeladores: maxCongeladores,
      costoCongelador: _costo,
    );
  }

  @override
  Future<CompraCongelador> comprarCongelador() async {
    if (congeladores >= maxCongeladores) {
      throw const GamificacionException(
        MotivoGamificacion.congeladoresAlMaximo,
      );
    }
    if (saldo < _costo) {
      throw const GamificacionException(MotivoGamificacion.puntosInsuficientes);
    }
    congeladores++;
    saldo -= _costo;
    return CompraCongelador(congeladores: congeladores, saldo: saldo);
  }

  @override
  Future<SorpresaHoy> sorpresaHoy() async => SorpresaHoy(
    disponible: sorpresaDisponible,
    abierta: sorpresaAbierta,
    puntos: _puntosSorpresa,
  );

  @override
  Future<int> abrirSorpresa() async {
    if (!sorpresaDisponible) {
      throw const GamificacionException(MotivoGamificacion.sinSorpresaHoy);
    }
    if (sorpresaAbierta) {
      throw const GamificacionException(MotivoGamificacion.sorpresaYaAbierta);
    }
    sorpresaAbierta = true;
    saldo += _puntosSorpresa;
    return _puntosSorpresa;
  }
}
