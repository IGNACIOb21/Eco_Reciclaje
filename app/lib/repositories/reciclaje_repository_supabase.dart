import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/punto_qr.dart';
import '../services/clasificacion_service.dart';
import '../services/supabase_service.dart';
import '../utils/hash_perceptual.dart';
import 'reciclaje_repository.dart';

/// Sube las fotos al bucket privado `residuos`
/// (`<auth.uid()>/<escaneos|depositos>/<ms>.jpg`) y registra con
/// `app_punto_qr`, `app_registrar_escaneo` y `app_registrar_deposito`.
/// `foto_url` guarda la ruta dentro del bucket, no una URL pública.
///
/// Como en Reportes, la foto se sube antes de llamar a la RPC; si la RPC
/// falla, la ruta se guarda y "Reintentar envío" con la MISMA foto la
/// reutiliza en vez de subir otra.
class ReciclajeRepositorySupabase implements ReciclajeRepository {
  static const bucket = 'residuos';

  // Solo para tests: el cliente, la subida a Storage, la llamada a la RPC y
  // el usuario de la sesión. Sin ellos se usa el Supabase real.
  final SupabaseClient? cliente;
  final Future<void> Function(String ruta, File foto)? subir;
  final Future<dynamic> Function(String funcion, Map<String, dynamic> params)?
  rpc;
  final String? Function()? uid;
  final Future<String> Function(Uint8List bytes) calcularHash;

  late final SupabaseClient _cliente = cliente ?? SupabaseService.cliente;

  /// Fotos ya subidas cuyo registro todavía no se aceptó: archivo → ruta.
  final _subidas = <String, String>{};

  ReciclajeRepositorySupabase({
    this.cliente,
    this.subir,
    this.rpc,
    this.uid,
    this.calcularHash = hashPerceptual,
  });

  Future<dynamic> _llamar(String funcion, Map<String, dynamic> params) {
    final rpc = this.rpc;
    return rpc != null
        ? rpc(funcion, params)
        : _cliente.rpc(funcion, params: params);
  }

  /// Sube la foto (o reutiliza la ya subida) y devuelve su ruta en el bucket.
  Future<String> _subir(File foto, String carpeta) async {
    final previa = _subidas[foto.path];
    if (previa != null) return previa;
    final leerUid = uid;
    final id = leerUid != null ? leerUid() : _cliente.auth.currentUser?.id;
    if (id == null) {
      throw const ReciclajeException(
        'No hay una sesión abierta. Cierra y vuelve a abrir la app.',
      );
    }
    final ruta = '$id/$carpeta/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final subir = this.subir;
    if (subir != null) {
      await subir(ruta, foto);
    } else {
      await _cliente.storage
          .from(bucket)
          .uploadBinary(
            ruta,
            await foto.readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    }
    _subidas[foto.path] = ruta;
    return ruta;
  }

  @override
  Future<PuntoQr> puntoPorQr(CodigoQrPunto qr) async {
    try {
      final r = await _llamar('app_punto_qr', {
        'p_codigo_qr': qr.codigo,
        'p_qr_secreto': qr.secreto,
      });
      final punto = PuntoQr.fromSupabase(
        qr,
        Map<String, dynamic>.from(r as Map),
      );
      // El código y el secreto son de un punto, pero el id impreso es de
      // otro: el QR está mal generado o lo editaron.
      if (qr.idPunto != null && qr.idPunto != punto.idPunto) {
        throw const ReciclajeException(
          'Este QR tiene datos de otro punto. Repórtalo desde la ficha del '
          'punto para que lo reemplacen.',
          qrInvalido: true,
        );
      }
      return punto;
    } catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<RegistroEscaneo> registrarEscaneo({
    required File foto,
    required ResultadoClasificacion resultado,
  }) async {
    // La foto del escaneo es opcional en la base: si no sube, se registra
    // igual.
    String? ruta;
    try {
      ruta = await _subir(foto, 'escaneos');
    } catch (e) {
      debugPrint('Reciclaje: no se pudo subir la foto del escaneo ($e)');
    }
    try {
      final r = await _llamar('app_registrar_escaneo', {
        'p_foto_ruta': ruta,
        'p_codigo_categoria': resultado.codigoCategoria,
        'p_es_reciclable': resultado.reciclable,
        'p_confianza_ia': resultado.confianza,
        'p_modelo_version': resultado.modeloVersion,
      });
      if (ruta != null) _subidas.remove(foto.path);
      final mapa = Map<String, dynamic>.from(r as Map);
      return RegistroEscaneo(
        idEscaneo: (mapa['id_escaneo'] as num?)?.toInt(),
        puntos: (mapa['puntos_otorgados'] as num?)?.toInt() ?? 0,
        conFoto: ruta != null,
      );
    } catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<RegistroDeposito> registrarDeposito({
    required File foto,
    required PuntoQr punto,
    required Position gps,
    required DateTime horaCaptura,
    required ResultadoClasificacion resultado,
  }) async {
    final codigo = resultado.codigoCategoria;
    if (codigo == null) {
      throw const ReciclajeException(
        'Un residuo no reciclable no se deposita.',
      );
    }
    try {
      final hash = await calcularHash(await foto.readAsBytes());
      final ruta = await _subir(foto, 'depositos');
      final r = await _llamar('app_registrar_deposito', {
        'p_codigo_qr': punto.qr.codigo,
        'p_qr_secreto': punto.qr.secreto,
        'p_codigo_categoria': codigo,
        'p_confianza_ia': resultado.confianza,
        'p_modelo_version': resultado.modeloVersion,
        'p_foto_ruta': ruta,
        'p_hash_perceptual': hash,
        'p_lat': gps.latitude,
        'p_lng': gps.longitude,
        'p_precision_gps': gps.accuracy,
        'p_ubicacion_simulada': gps.isMocked,
        'p_hora_captura': horaCaptura.toUtc().toIso8601String(),
      });
      _subidas.remove(foto.path);
      return RegistroDeposito.fromMap(Map<String, dynamic>.from(r as Map));
    } catch (e) {
      // La base no aceptó esa ruta (no existe o ya se usó): no reutilizarla.
      if (e is PostgrestException && e.message == 'foto_invalida') {
        _subidas.remove(foto.path);
      }
      throw _traducir(e);
    }
  }

  ReciclajeException _traducir(Object e) {
    debugPrint('Reciclaje: $e');
    if (e is ReciclajeException) return e;
    if (e is PostgrestException) {
      if (e.code == 'PGRST202') {
        return const ReciclajeException(
          'El registro todavía no está habilitado en la base de datos '
          '(falta aplicar el SQL de escaneos y depósitos).',
        );
      }
      switch (e.message) {
        case 'qr_invalido':
          return const ReciclajeException(
            'Ese código QR no corresponde a ningún punto de Rebin.',
            qrInvalido: true,
          );
        case 'categoria_invalida':
          return const ReciclajeException(
            'La categoría del residuo no existe en la base de datos.',
          );
        case 'foto_invalida':
          return const ReciclajeException(
            'La foto no se guardó bien. Reintenta el envío.',
          );
        case 'datos_invalidos':
          return const ReciclajeException(
            'Faltan datos del depósito (ubicación u hora). Toma la foto de '
            'nuevo.',
          );
        case 'sesion_requerida':
        case 'usuario_no_registrado':
          return const ReciclajeException(
            'No hay una sesión abierta. Cierra y vuelve a abrir la app.',
          );
      }
    }
    if (e is StorageException) {
      return ReciclajeException(
        e.message.contains('not found')
            ? 'Falta crear el espacio para fotos ("$bucket") en Supabase.'
            : 'No pudimos subir la foto. Revisa tu conexión.',
      );
    }
    if (e is SocketException || e.toString().contains('SocketException')) {
      return const ReciclajeException(
        'Sin conexión a internet. Intenta de nuevo.',
      );
    }
    return const ReciclajeException(
      'No pudimos registrar tu reciclaje. Intenta de nuevo.',
    );
  }
}
