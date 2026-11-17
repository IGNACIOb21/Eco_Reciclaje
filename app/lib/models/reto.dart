import 'package:flutter/material.dart';

/// Misión semanal: una meta concreta con puntos al reclamarla.
class Mision {
  final String id;
  final String titulo;
  final String detalle;
  final IconData icono;
  final Color color;
  final int actual;
  final int meta;
  final int puntos;

  /// Misión con bonus (p. ej. sugerir un punto en una zona sin cobertura).
  final bool bonus;
  final bool reclamada;

  const Mision({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.color,
    required this.actual,
    required this.meta,
    required this.puntos,
    this.bonus = false,
    this.reclamada = false,
  });

  bool get lista => !reclamada && actual >= meta;
  double get progreso =>
      meta == 0 ? 1 : (actual / meta).clamp(0.0, 1.0).toDouble();

  Mision copyWith({bool? reclamada}) => Mision(
    id: id,
    titulo: titulo,
    detalle: detalle,
    icono: icono,
    color: color,
    actual: actual,
    meta: meta,
    puntos: puntos,
    bonus: bonus,
    reclamada: reclamada ?? this.reclamada,
  );
}

/// Un escalón de un logro: cuánto pide y cuántos Rebin Points da.
class EscalonLogro {
  final int meta;
  final int puntos;

  const EscalonLogro(this.meta, this.puntos);
}

/// Logro con niveles (I, II, III). [nivel] es 0 mientras no se obtiene.
class Logro {
  final String id;
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
  final int actual;
  final List<EscalonLogro> escalones;

  /// Niveles ya reclamados (la base los paga al reclamar). Null en los datos
  /// que no distinguen alcanzar de reclamar: el nivel sale del avance.
  final int? nivelReclamado;

  const Logro({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.actual,
    required this.escalones,
    this.nivelReclamado,
  });

  /// Nivel conseguido: el reclamado o, sin ese dato, los escalones alcanzados.
  int get nivel =>
      nivelReclamado ?? escalones.where((e) => actual >= e.meta).length;

  /// El siguiente escalón ya se alcanzó y falta reclamarlo.
  bool get reclamable =>
      nivel < escalones.length && actual >= escalones[nivel].meta;

  /// Rebin Points del siguiente escalón (0 si ya está completo).
  int get puntosSiguiente => completo ? 0 : escalones[nivel].puntos;

  Logro copyWith({int? nivelReclamado}) => Logro(
    id: id,
    nombre: nombre,
    descripcion: descripcion,
    icono: icono,
    color: color,
    actual: actual,
    escalones: escalones,
    nivelReclamado: nivelReclamado ?? this.nivelReclamado,
  );

  bool get completo => nivel == escalones.length;

  /// Meta del escalón en curso (o la última si ya está completo).
  int get metaActual => escalones[completo ? escalones.length - 1 : nivel].meta;

  double get progreso => (actual / metaActual).clamp(0.0, 1.0).toDouble();
}

class Retos {
  final List<Mision> misiones;
  final List<Logro> logros;

  const Retos({required this.misiones, required this.logros});
}
