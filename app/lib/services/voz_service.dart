import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Dice por voz el resultado de la IA con el motor de voz del teléfono
/// (`flutter_tts`). Avisa a quien escucha cuando empieza y termina de hablar
/// ([hablando]), para que el altavoz del resultado pueda cortar el audio.
class VozService extends ChangeNotifier {
  final FlutterTts? _tts;
  bool _configurada = false;
  bool _hablando = false;

  VozService({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    final tts = _tts;
    if (tts == null) return;
    tts.setStartHandler(() => _cambiarHablando(true));
    tts.setCompletionHandler(() => _cambiarHablando(false));
    tts.setCancelHandler(() => _cambiarHablando(false));
    tts.setErrorHandler((_) => _cambiarHablando(false));
  }

  /// Sin motor de voz (tests): nunca habla.
  VozService.silenciosa() : _tts = null;

  static final instancia = VozService();

  /// true mientras suena un audio.
  bool get hablando => _hablando;

  void _cambiarHablando(bool valor) {
    if (_hablando == valor) return;
    _hablando = valor;
    notifyListeners();
  }

  /// Dice [texto], cortando lo que estuviera sonando.
  Future<void> decir(String texto) async {
    final tts = _tts;
    if (tts == null || texto.trim().isEmpty) return;
    try {
      if (!_configurada) {
        _configurada = true;
        // Español de Chile si el teléfono lo tiene; si no, el español general.
        final chile = await tts.isLanguageAvailable('es-CL');
        await tts.setLanguage(chile == true ? 'es-CL' : 'es-ES');
        await tts.setSpeechRate(0.5);
      }
      await tts.stop();
      _cambiarHablando(true);
      await tts.speak(texto);
    } catch (e) {
      debugPrint('Voz: no se pudo hablar ($e)');
      _cambiarHablando(false);
    }
  }

  /// Corta el audio que esté sonando.
  Future<void> detener() async {
    _cambiarHablando(false);
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
