import '../models/reto.dart';

abstract class RetosRepository {
  Future<Retos> retos();

  /// Reclama una misión lista. Devuelve los Rebin Points acreditados (0 si ya
  /// estaba reclamada).
  Future<int> reclamarMision(String idMision);

  /// Reclama el siguiente nivel de un logro. Devuelve los Rebin Points
  /// acreditados (0 si no había nivel por reclamar).
  Future<int> reclamarLogro(String idLogro);
}
