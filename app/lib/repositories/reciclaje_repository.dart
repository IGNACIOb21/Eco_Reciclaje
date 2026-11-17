import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../models/punto_qr.dart';
import '../services/clasificacion_service.dart';

/// Lo que devuelve la base al registrar un escaneo ("¿Se recicla?").
class RegistroEscaneo {
  final int? idEscaneo;
  final int puntos;

  /// false si la foto no se pudo subir y el escaneo quedó sin `foto_url`.
  final bool conFoto;

  const RegistroEscaneo({
    required this.idEscaneo,
    required this.puntos,
    this.conFoto = true,
  });
}

/// Lo que devuelve la base al registrar un artículo depositado.
class RegistroDeposito {
  final int? idReciclaje;

  /// `estado_validacion`: aprobado, dudoso, rechazado o
  /// sin_puntos_por_limite.
  final String estado;

  /// Señal que decidió el estado (lejos_del_punto, sin_ia…); null si se
  /// aprobó.
  final String? motivo;
  final int puntos;
  final String nombrePunto;
  final double? distanciaMetros;

  const RegistroDeposito({
    required this.idReciclaje,
    required this.estado,
    required this.motivo,
    required this.puntos,
    required this.nombrePunto,
    this.distanciaMetros,
  });

  bool get aprobado => estado == 'aprobado';
  bool get rechazado => estado == 'rechazado';
  bool get enRevision => estado == 'dudoso' || estado == 'pendiente_revision';

  factory RegistroDeposito.fromMap(Map<String, dynamic> m) => RegistroDeposito(
    idReciclaje: (m['id_reciclaje'] as num?)?.toInt(),
    estado: m['estado_validacion'] as String,
    motivo: m['motivo'] as String?,
    puntos: (m['puntos_otorgados'] as num?)?.toInt() ?? 0,
    nombrePunto: (m['punto_nombre'] as String?) ?? 'Punto de reciclaje',
    distanciaMetros: (m['distancia_calculada'] as num?)?.toDouble(),
  );

  /// Explicación del motivo para la persona.
  static String explicar(String? motivo) => switch (motivo) {
    'punto_no_operativo' => 'el punto no está operativo',
    'qr_inactivo' => 'el QR del punto está reportado como faltante o dañado',
    'categoria_no_aceptada' => 'este punto no recibe ese material',
    'lejos_del_punto' => 'estabas a más de 150 m del contenedor',
    'foto_antigua' => 'la foto se tomó hace más de 30 minutos',
    'limite_punto' => 'ya registraste 3 artículos hoy en este punto',
    'limite_diario' => 'ya registraste 10 artículos hoy',
    'limite_regla' => 'alcanzaste el máximo de Rebin Points de hoy',
    'ubicacion_simulada' => 'la ubicación parece simulada',
    'foto_repetida' => 'la foto se parece mucho a otra ya enviada',
    'desplazamiento_imposible' =>
      'te moviste demasiado rápido desde tu depósito anterior',
    'hora_invalida' => 'la hora del teléfono no coincide',
    'cerca_del_punto' => 'estabas a más de 50 m del contenedor',
    'gps_impreciso' => 'el GPS no tenía buena precisión',
    'foto_tardia' => 'la foto se tomó hace más de 5 minutos',
    'sin_ia' => 'la categoría la elegiste tú y no la IA',
    'confianza_baja' => 'la IA no está segura de qué residuo es',
    _ => 'hay que revisarlo',
  };
}

/// Error con un mensaje listo para mostrar al usuario.
class ReciclajeException implements Exception {
  final String mensaje;

  /// true si el QR no es de Rebin o no corresponde a ningún punto.
  final bool qrInvalido;

  const ReciclajeException(this.mensaje, {this.qrInvalido = false});

  @override
  String toString() => 'ReciclajeException($mensaje)';
}

/// Registro del flujo "Reciclar". La app manda los datos crudos; la base
/// decide el estado de cada depósito y los puntos (ver
/// backend/remoto/20261017100000_escaneos_depositos.sql).
abstract class ReciclajeRepository {
  /// El punto del QR leído (`app_punto_qr`). Lanza [ReciclajeException]
  /// (con `qrInvalido`) si el QR no corresponde a ningún punto.
  Future<PuntoQr> puntoPorQr(CodigoQrPunto qr);

  /// "¿Se recicla?": sube la foto (si falla, registra sin foto) e inserta en
  /// `escaneos`.
  Future<RegistroEscaneo> registrarEscaneo({
    required File foto,
    required ResultadoClasificacion resultado,
  });

  /// Un artículo depositado en [punto]: sube la foto y lo registra en
  /// `reciclajes`. Si la base lo rechaza por un error, un nuevo intento con
  /// la MISMA foto reutiliza la ya subida. Lanza [ReciclajeException].
  Future<RegistroDeposito> registrarDeposito({
    required File foto,
    required PuntoQr punto,
    required Position gps,
    required DateTime horaCaptura,
    required ResultadoClasificacion resultado,
  });
}
