import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../models/material_type.dart';
import '../models/punto_qr.dart';
import '../services/clasificacion_service.dart';
import 'reciclaje_repository.dart';

/// Sin Supabase (demo y tests): cualquier QR de Rebin es un punto que recibe
/// todo menos aceite (con el id, nombre y ubicación del QR si los trae), y la base "aprueba" los depósitos clasificados por la
/// IA (+20) y deja en revisión los que eligió la persona.
class ReciclajeRepositoryMock implements ReciclajeRepository {
  final Duration espera;

  /// Lo que devuelve [puntoPorQr]; si es null, un punto de prueba.
  final PuntoQr? punto;

  /// Depósitos registrados (para los tests).
  final List<ResultadoClasificacion> depositos = [];

  ReciclajeRepositoryMock({
    this.espera = const Duration(milliseconds: 600),
    this.punto,
  });

  @override
  Future<PuntoQr> puntoPorQr(CodigoQrPunto qr) async {
    await Future<void>.delayed(espera);
    return punto ??
        PuntoQr(
          qr: qr,
          idPunto: qr.idPunto ?? 0,
          nombre: qr.nombre ?? 'Punto de prueba (${qr.codigo})',
          lat: qr.lat ?? -33.4372,
          lng: qr.lng ?? -70.6506,
          materiales: TipoMaterial.values
              .where((m) => m != TipoMaterial.aceite)
              .toSet(),
        );
  }

  @override
  Future<RegistroEscaneo> registrarEscaneo({
    required File foto,
    required ResultadoClasificacion resultado,
  }) async {
    await Future<void>.delayed(espera);
    return RegistroEscaneo(
      idEscaneo: null,
      puntos: resultado.elegidoPorPersona ? 0 : 5,
    );
  }

  @override
  Future<RegistroDeposito> registrarDeposito({
    required File foto,
    required PuntoQr punto,
    required Position gps,
    required DateTime horaCaptura,
    required ResultadoClasificacion resultado,
  }) async {
    await Future<void>.delayed(espera);
    depositos.add(resultado);
    final porPersona = resultado.elegidoPorPersona;
    return RegistroDeposito(
      idReciclaje: null,
      estado: porPersona ? 'dudoso' : 'aprobado',
      motivo: porPersona ? 'sin_ia' : null,
      puntos: porPersona ? 0 : 20,
      nombrePunto: punto.nombre,
      distanciaMetros: 8,
    );
  }
}
