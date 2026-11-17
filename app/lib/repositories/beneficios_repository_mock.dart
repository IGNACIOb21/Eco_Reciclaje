import '../models/beneficio.dart';
import '../models/mi_canje.dart';
import 'beneficios_repository.dart';

/// Para demos sin conexión y tests. Con [error] lanza esa excepción al
/// canjear; [saldo] es lo que informa tras un canje exitoso.
class BeneficiosRepositoryMock implements BeneficiosRepository {
  final List<Beneficio> catalogo;
  final List<MiCanje> canjes;
  final CanjeException? error;
  final int saldo;

  /// Último beneficio canjeado, para comprobarlo en tests.
  int? ultimoCanjeado;

  BeneficiosRepositoryMock({
    this.catalogo = const [],
    this.canjes = const [],
    this.error,
    this.saldo = 0,
  });

  @override
  Future<List<Beneficio>> beneficios() async => catalogo;

  @override
  Future<ResultadoCanje> canjear(int idBeneficio) async {
    if (error != null) throw error!;
    ultimoCanjeado = idBeneficio;
    final b = catalogo.firstWhere((b) => b.id == idBeneficio);
    return ResultadoCanje(codigo: 'ABCD2345', costo: b.costo, saldo: saldo);
  }

  @override
  Future<List<MiCanje>> misCanjes() async => canjes;
}
