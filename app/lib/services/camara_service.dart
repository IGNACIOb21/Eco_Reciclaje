import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/camara_foto_screen.dart';
import 'permisos_service.dart';
import '../widgets/ruta_rapida.dart';
import 'voz_service.dart';

/// Foto rescatada con [CamaraService.recuperarFotoPerdida], junto con lo que
/// la pantalla guardó al abrir la cámara para poder volver a ella.
typedef FotoRecuperada = ({Map<String, Object?> pendiente, File foto});

/// Cámara nativa (image_picker) y manejo de sus archivos temporales.
///
/// mobile_scanner declara CAMERA en el manifest, así que Android exige ese
/// permiso concedido también para abrir la cámara de image_picker: siempre
/// llamar a [asegurarPermiso] antes de [tomarFoto] o del lector QR.
class CamaraService {
  final PermisosService permisos;
  final ImagePicker _picker;
  final ProcesadorFoto procesador;

  CamaraService({
    this.permisos = const PermisosService(),
    ImagePicker? picker,
    this.procesador = const ProcesadorFoto(),
  }) : _picker = picker ?? ImagePicker();

  /// Clave de shared_preferences con lo que la pantalla necesita para
  /// retomar la foto si Android cierra la app con la cámara abierta.
  static const clavePendiente = 'foto_pendiente';

  /// Aviso cuando la persona no da el permiso: le dice dónde activarlo
  /// después (la fila Cámara de Perfil › Ajustes › Permisos).
  static String avisoSinPermiso(EstadoPermiso estado) =>
      estado == EstadoPermiso.bloqueado
      ? 'Activa la cámara para Rebin en los ajustes del teléfono. También '
            'puedes hacerlo desde Perfil › Ajustes › Permisos.'
      : 'Sin la cámara no puedes escanear. Puedes activarla cuando quieras '
            'en Perfil › Ajustes › Permisos.';

  /// Pide el permiso de cámara si falta. Si no se concede, avisa con un
  /// SnackBar ([avisoSinPermiso]) y devuelve false.
  Future<bool> asegurarPermiso(BuildContext context) async {
    var estado = await permisos.estado(PermisoApp.camara);
    if (estado != EstadoPermiso.concedido) {
      estado = await permisos.pedir(PermisoApp.camara);
    }
    if (estado == EstadoPermiso.concedido) return true;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Text(avisoSinPermiso(estado)),
        ),
      );
    }
    return false;
  }

  /// Abre la cámara nativa y devuelve la foto ya procesada por
  /// [ProcesadorFoto] (lado largo de 1024 px como máximo, JPEG calidad 75, sin
  /// EXIF, menos de 1 MB). Null si el usuario cancela.
  ///
  /// image_picker entrega la original sin comprimir (así se comprime una sola
  /// vez) y esa original, con su EXIF y quizás el GPS, se borra siempre, salga
  /// bien o mal el proceso. Si no se puede procesar lanza
  /// [FotoNoProcesadaException]: nunca se devuelve la original.
  ///
  /// [pendiente] se guarda mientras la cámara está abierta: si Android cierra
  /// la app en ese momento, [recuperarFotoPerdida] lo devuelve con la foto.
  Future<File?> tomarFoto({Map<String, Object?>? pendiente}) async {
    if (pendiente != null) await _guardarPendiente(pendiente);
    final XFile? foto;
    try {
      foto = await _picker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );
    } finally {
      if (pendiente != null) await _guardarPendiente(null);
    }
    if (foto == null) return null;
    return _procesarOriginal(File(foto.path));
  }

  /// Abre la cámara dentro de la app ([CamaraFotoScreen], con el encabezado
  /// del paso encima) y devuelve la foto procesada igual que [tomarFoto].
  /// Null si la persona vuelve sin tomarla. Como la app no pasa a segundo
  /// plano, no hace falta guardar nada para [recuperarFotoPerdida].
  Future<File?> tomarFotoEnApp(
    BuildContext context, {
    required String titulo,
    required int paso,
    required int total,
    required String explicacion,
    VozService? voz,
    ValueListenable<AvisoCamara?>? aviso,
    String? textoSalir,
    ValueListenable<bool>? cerrar,
  }) async {
    final original = await Navigator.of(context).push<File>(
      rutaRapida(
        (_) => CamaraFotoScreen(
          titulo: titulo,
          paso: paso,
          total: total,
          explicacion: explicacion,
          voz: voz,
          aviso: aviso,
          textoSalir: textoSalir,
          cerrar: cerrar,
        ),
      ),
    );
    if (original == null) return null;
    return _procesarOriginal(original);
  }

  /// Android puede cerrar Rebin para liberar memoria mientras la cámara
  /// está abierta (pasa en teléfonos de gama baja); al volver, la foto queda
  /// en image_picker. Se llama al iniciar la app: devuelve la foto procesada
  /// con lo que la pantalla guardó en [tomarFoto], o null si no había nada.
  /// Si la pantalla no guardó nada, la foto se borra sin usarla.
  Future<FotoRecuperada?> recuperarFotoPerdida() async {
    if (!Platform.isAndroid) return null;
    final pendiente = await _leerPendiente();
    if (pendiente != null) await _guardarPendiente(null);
    final LostDataResponse respuesta;
    try {
      respuesta = await _picker.retrieveLostData();
    } catch (e) {
      debugPrint('Camara: no se pudo recuperar la foto ($e)');
      return null;
    }
    final archivos = [
      ...?respuesta.files,
      if (respuesta.files == null && respuesta.file != null) respuesta.file!,
    ].map((x) => File(x.path)).toList();
    if (archivos.isEmpty) return null;
    for (final sobrante in archivos.skip(1)) {
      await borrar(sobrante);
    }
    if (pendiente == null) {
      await borrar(archivos.first);
      return null;
    }
    final foto = await _procesarOriginal(archivos.first);
    return (pendiente: pendiente, foto: foto);
  }

  /// Procesa [original] y la borra siempre. Antes de devolver la foto borra
  /// los restos de capturas anteriores.
  Future<File> _procesarOriginal(File original) async {
    final File procesada;
    try {
      procesada = await procesador.procesar(original);
    } catch (e) {
      debugPrint('Camara: no se pudo procesar la foto ($e)');
      throw FotoNoProcesadaException(
        motivo: e is FotoNoProcesadaException
            ? e.motivo
            : esFaltaDeEspacio(e)
            ? MotivoFotoFallida.sinEspacio
            : MotivoFotoFallida.general,
      );
    } finally {
      await borrar(original);
    }
    await _limpiarRestos(procesada);
    return procesada;
  }

  /// Borra una foto temporal ya usada (ya clasificada o ya subida).
  static Future<void> borrar(File? foto) async {
    if (foto == null) return;
    try {
      if (await foto.exists()) await foto.delete();
    } catch (e) {
      // No es grave: Android limpia la caché por su cuenta.
      debugPrint('Camara: no se pudo borrar ${foto.path} ($e)');
    }
  }

  /// Rutas de fotos que un flujo en curso todavía necesita (ej. la foto 1
  /// mientras se toma la foto 2): la limpieza no las borra.
  static final Set<String> conservar = {};

  /// Borra fotos sueltas de capturas anteriores en la carpeta de caché de
  /// [actual]: image_picker deja un archivo vacío al cancelar la cámara, y
  /// una foto puede quedar si la app se cerró a mitad del flujo o si una
  /// compresión terminó después del tiempo máximo. Solo toca archivos de la
  /// cámara ([esRestoDeCamara]); el resto de la caché (ej. .mapbox) no.
  Future<void> _limpiarRestos(File actual) async {
    try {
      await for (final entrada in actual.parent.list()) {
        if (entrada is File &&
            entrada.path != actual.path &&
            !conservar.contains(entrada.path) &&
            esRestoDeCamara(entrada.uri.pathSegments.last)) {
          await entrada.delete();
        }
      }
    } catch (e) {
      debugPrint('Camara: no se pudieron limpiar fotos anteriores ($e)');
    }
  }

  static Future<void> _guardarPendiente(Map<String, Object?>? datos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (datos == null) {
        await prefs.remove(clavePendiente);
      } else {
        await prefs.setString(clavePendiente, jsonEncode(datos));
      }
    } catch (e) {
      debugPrint('Camara: no se pudo guardar la foto pendiente ($e)');
    }
  }

  static Future<Map<String, Object?>?> _leerPendiente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(clavePendiente);
      if (texto == null) return null;
      return (jsonDecode(texto) as Map).cast<String, Object?>();
    } catch (e) {
      debugPrint('Camara: no se pudo leer la foto pendiente ($e)');
      return null;
    }
  }
}

/// Si [nombre] es un archivo que deja la cámara en la caché de la app:
/// - `rebin_<µs>.jpg`: las fotos que comprime [ProcesadorFoto];
/// - `<uuid><número>.jpg`: la captura de image_picker en Android
///   (`File.createTempFile(UUID, ".jpg", cacheDir)`), vacía si se canceló;
/// - `scaled_…`: lo que image_picker reducía con maxWidth (versiones viejas
///   de la app);
/// - `CAP<número>.jpg`: la captura del paquete camera en Android
///   ([CamaraFotoScreen]).
bool esRestoDeCamara(String nombre) {
  final n = nombre.toLowerCase();
  if (n.startsWith('rebin_') && n.endsWith('.jpg')) return true;
  if (_capturaCamera.hasMatch(n)) return true;
  if (n.startsWith('scaled_')) return true;
  return _capturaImagePicker.hasMatch(n);
}

final _capturaCamera = RegExp(r'^cap\d+\.jpe?g$');

final _capturaImagePicker = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\d*\.(jpe?g|png|heic|heif)$',
);

/// Por qué no se pudo procesar una foto (cambia el mensaje).
enum MotivoFotoFallida { general, sinEspacio }

/// La foto no se pudo reducir ni comprimir: hay que tomarla de nuevo.
class FotoNoProcesadaException implements Exception {
  final MotivoFotoFallida motivo;

  const FotoNoProcesadaException({this.motivo = MotivoFotoFallida.general});

  String get mensaje => switch (motivo) {
    MotivoFotoFallida.general =>
      'No pudimos procesar la foto, tómala de nuevo.',
    MotivoFotoFallida.sinEspacio => 'Tu teléfono no tiene espacio para la foto. Libera espacio y tómala de nuevo.',
  };

  @override
  String toString() => 'FotoNoProcesadaException(${motivo.name})';
}

/// Si [error] viene de un disco lleno (ENOSPC, código 28 en Android e iOS).
bool esFaltaDeEspacio(Object error) {
  if (error is FileSystemException && error.osError?.errorCode == 28) {
    return true;
  }
  final texto = error.toString();
  return texto.contains('ENOSPC') || texto.contains('No space left');
}

/// Formatos de foto que el compresor sabe leer.
enum FormatoFoto { jpeg, png, heic }

/// Formato real de una foto según sus primeros bytes ([cabecera], al menos
/// 12), sin fiarse de la extensión del nombre. Null si no es una foto
/// conocida (archivo dañado o de otro tipo).
FormatoFoto? detectarFormato(List<int> cabecera) {
  bool empieza(List<int> firma, [int desde = 0]) {
    if (cabecera.length < desde + firma.length) return false;
    for (var i = 0; i < firma.length; i++) {
      if (cabecera[desde + i] != firma[i]) return false;
    }
    return true;
  }

  if (empieza(const [0xFF, 0xD8, 0xFF])) return FormatoFoto.jpeg;
  if (empieza(const [0x89, 0x50, 0x4E, 0x47])) return FormatoFoto.png;
  // HEIC/HEIF (iPhone y algunos Android): caja "ftyp" con una marca HEIF.
  if (empieza(ascii.encode('ftyp'), 4) && cabecera.length >= 12) {
    final marca = ascii.decode(cabecera.sublist(8, 12), allowInvalid: true);
    const marcas = {'heic', 'heix', 'hevc', 'hevx', 'heim', 'heis', 'mif1'};
    if (marcas.contains(marca)) return FormatoFoto.heic;
  }
  return null;
}

/// Medidas que se piden a flutter_image_compress y lo que se espera obtener.
typedef MedidasCompresion = ({int ancho, int alto, int lado, int muestreo});

/// Calcula cómo reducir una foto de [ancho] × [alto] para que su lado largo
/// quede en [maximo] px como máximo, sin agrandar nunca una foto más chica.
///
/// flutter_image_compress toma `minWidth`/`minHeight` como mínimos (escala por
/// el menor de los dos cocientes y nunca agranda), así que se le pasa el lado
/// corto esperado ([MedidasCompresion.lado]) en ambos: el resultado es el
/// mismo con la foto acostada o de pie, aunque la marca de orientación del
/// EXIF la gire. [MedidasCompresion.muestreo] es el `inSampleSize` de
/// Android: decodifica la foto a 1/2, 1/4… mientras el lado corto siga
/// alcanzando, para no ocupar la memoria de los 12 MP completos.
MedidasCompresion calcularCompresion(
  int ancho,
  int alto, {
  int maximo = ProcesadorFoto.ladoMaximo,
}) {
  final largo = ancho > alto ? ancho : alto;
  final corto = ancho > alto ? alto : ancho;
  if (largo <= maximo) {
    return (ancho: ancho, alto: alto, lado: corto, muestreo: 1);
  }
  final lado = (corto * maximo / largo).round();
  var muestreo = 1;
  while (corto ~/ (muestreo * 2) >= lado) {
    muestreo *= 2;
  }
  return (
    ancho: ancho >= alto ? maximo : lado,
    alto: ancho >= alto ? lado : maximo,
    lado: lado,
    muestreo: muestreo,
  );
}

/// Comprime [origen] en [destino] y devuelve la ruta escrita (o null).
typedef CompresorFoto = Future<String?> Function({
  required String origen,
  required String destino,
  required int lado,
  required int calidad,
  required int muestreo,
});

/// Ancho y alto de una foto.
typedef LectorMedidas = Future<(int, int)> Function(File foto);

/// Reduce, comprime en JPEG y quita los metadatos de una foto con el código
/// nativo del teléfono (flutter_image_compress), sin trabar la interfaz.
///
/// Antes de comprimir revisa que la original exista, no esté vacía y sea
/// una foto de verdad (por sus primeros bytes). Después revisa el resultado:
/// JPEG, lado largo de 1024 px como máximo y menos de 1 MB (el límite del
/// bucket); si no cumple, lo vuelve a comprimir una vez (a calidad 60 si es
/// por peso). Cada compresión tiene [tiempoMaximo].
class ProcesadorFoto {
  static const ladoMaximo = 1024;
  static const calidad = 75;
  static const calidadReducida = 60;
  static const pesoMaximo = 1024 * 1024;

  // Solo para tests: reemplazan al compresor nativo y a la lectura de
  // medidas.
  final CompresorFoto comprimir;
  final LectorMedidas medidas;

  /// Tiempo máximo de cada compresión: si el compresor se queda pegado (un
  /// teléfono muy lento o sin espacio), se corta y se avisa.
  final Duration tiempoMaximo;

  const ProcesadorFoto({
    this.comprimir = _comprimirNativo,
    this.medidas = leerMedidas,
    this.tiempoMaximo = const Duration(seconds: 20),
  });

  /// Devuelve un archivo nuevo junto a [original] (que no se toca) o lanza
  /// si no se pudo procesar.
  Future<File> procesar(File original) async {
    if (!await original.exists() || await original.length() == 0) {
      throw StateError('la cámara entregó un archivo vacío');
    }
    if (detectarFormato(await _cabecera(original)) == null) {
      throw StateError('la cámara entregó un archivo que no es una foto');
    }
    MedidasCompresion m;
    try {
      final (ancho, alto) = await medidas(original);
      m = calcularCompresion(ancho, alto);
    } catch (e) {
      // Sin medidas (ej. un HEIC que Flutter no lee): se pide el lado de una
      // foto 4:3 y la revisión de abajo corrige si queda más grande.
      debugPrint('Camara: medidas no leídas ($e)');
      m = (ancho: ladoMaximo, alto: 768, lado: 768, muestreo: 1);
    }

    var actual = await _pasada(original, m.lado, calidad, m.muestreo);
    try {
      for (var repasos = 0; ; repasos++) {
        if (detectarFormato(await _cabecera(actual)) != FormatoFoto.jpeg) {
          throw StateError('el resultado no es JPEG');
        }
        final (ancho, alto) = await medidas(actual);
        final grande = math.max(ancho, alto) > ladoMaximo;
        final pesada = await actual.length() > pesoMaximo;
        if (!grande && !pesada) return actual;
        if (repasos >= 2) {
          throw StateError('el resultado sigue fuera de medida o de peso');
        }
        final anterior = actual;
        actual = await _pasada(
          anterior,
          calcularCompresion(ancho, alto).lado,
          grande ? calidad : calidadReducida,
          1,
        );
        await CamaraService.borrar(anterior);
      }
    } catch (_) {
      await CamaraService.borrar(actual);
      rethrow;
    }
  }

  /// Una compresión con tiempo máximo. Lanza si no produjo un archivo.
  Future<File> _pasada(File origen, int lado, int calidad, int muestreo) async {
    final destino = File(
      '${origen.parent.path}${Platform.pathSeparator}'
      'rebin_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final String? ruta;
    try {
      ruta = await comprimir(
        origen: origen.path,
        destino: destino.path,
        lado: lado,
        calidad: calidad,
        muestreo: muestreo,
      ).timeout(tiempoMaximo);
    } catch (_) {
      await CamaraService.borrar(destino);
      rethrow;
    }
    final archivo = File(ruta ?? destino.path);
    if (ruta == null ||
        !await archivo.exists() ||
        await archivo.length() == 0) {
      await CamaraService.borrar(archivo);
      throw StateError('compresión sin resultado');
    }
    return archivo;
  }

  static Future<List<int>> _cabecera(File foto) async {
    final lector = await foto.open();
    try {
      return await lector.read(16);
    } finally {
      await lector.close();
    }
  }

  static Future<String?> _comprimirNativo({
    required String origen,
    required String destino,
    required int lado,
    required int calidad,
    required int muestreo,
  }) async {
    final resultado = await FlutterImageCompress.compressAndGetFile(
      origen,
      destino,
      minWidth: lado,
      minHeight: lado,
      quality: calidad,
      format: CompressFormat.jpeg,
      // Sin EXIF: ni GPS ni hora del teléfono. La foto sale ya enderezada.
      keepExif: false,
      autoCorrectionAngle: true,
      inSampleSize: muestreo,
    );
    return resultado?.path;
  }

  /// Ancho y alto de la foto. Lee el archivo comprimido (3-5 MB, por un
  /// instante) pero no descomprime los píxeles, que serían ~48 MB en 12 MP.
  static Future<(int, int)> leerMedidas(File foto) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(foto.path);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        return (descriptor.width, descriptor.height);
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }
}
