import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Comprueba que el dominio del correo exista y reciba correo (registros MX)
/// consultando DNS sobre HTTPS de Cloudflare. Solo se envía el dominio
/// (ej. "gmail.com"), nunca el correo completo.
///
/// Que el buzón exista no se puede confirmar desde afuera sin enviarle algo:
/// eso lo prueba el código de verificación que llega al correo.
///
/// Devuelve true/false, o null si no se pudo consultar (sin conexión, DNS
/// caído): en ese caso quien llama no bloquea y deja que decida el código.
Future<bool?> dominioRecibeCorreo(String dominio) async {
  final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final uri = Uri.https('cloudflare-dns.com', '/dns-query', {
      'name': dominio,
      'type': 'MX',
    });
    final peticion = await cliente.getUrl(uri);
    peticion.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
    final respuesta = await peticion.close().timeout(
      const Duration(seconds: 5),
    );
    if (respuesta.statusCode != 200) return null;
    final cuerpo = await respuesta.transform(utf8.decoder).join();
    final json = jsonDecode(cuerpo) as Map<String, dynamic>;
    // Status 3 = NXDOMAIN: el dominio no existe.
    if (json['Status'] == 3) return false;
    if (json['Status'] != 0) return null;
    final respuestas = (json['Answer'] as List?) ?? const [];
    // Tipo 15 = MX.
    return respuestas.any((r) => (r as Map)['type'] == 15);
  } catch (e) {
    debugPrint('correo_service: no se pudo consultar el dominio ($e)');
    return null;
  } finally {
    cliente.close(force: true);
  }
}
