import 'package:shared_preferences/shared_preferences.dart';

/// Preferências de qualidade de captura (foto/vídeo HD).
///
/// Padrão: ambos desligados (~720p), alinhado ao comportamento histórico.
class CaptureQualitySettings {
  CaptureQualitySettings({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const photoHdKey = 'capture.photo_hd';
  static const videoHdKey = 'capture.video_hd';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  bool _photoHd = false;
  bool _videoHd = false;

  bool get photoHd => _photoHd;
  bool get videoHd => _videoHd;

  Future<void> load() async {
    _prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    _photoHd = _prefs!.getBool(photoHdKey) ?? false;
    _videoHd = _prefs!.getBool(videoHdKey) ?? false;
  }

  Future<void> setPhotoHd(bool value) async {
    final prefs = _requirePrefs();
    _photoHd = value;
    await prefs.setBool(photoHdKey, value);
  }

  Future<void> setVideoHd(bool value) async {
    final prefs = _requirePrefs();
    _videoHd = value;
    await prefs.setBool(videoHdKey, value);
  }

  SharedPreferences _requirePrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('CaptureQualitySettings.load() deve ser chamado antes.');
    }
    return prefs;
  }
}
