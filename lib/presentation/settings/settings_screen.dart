import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../data/settings/capture_quality_settings.dart';

/// Preferências locais do operador (qualidade de captura).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.settings,
  });

  final CaptureQualitySettings? settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final CaptureQualitySettings _settings;
  late bool _photoHd;
  late bool _videoHd;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? getIt<CaptureQualitySettings>();
    _photoHd = _settings.photoHd;
    _videoHd = _settings.videoHd;
  }

  Future<void> _onPhotoHdChanged(bool value) async {
    await _settings.setPhotoHd(value);
    if (!mounted) return;
    setState(() => _photoHd = value);
  }

  Future<void> _onVideoHdChanged(bool value) async {
    await _settings.setVideoHd(value);
    if (!mounted) return;
    setState(() => _videoHd = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('settings_screen'),
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            key: const Key('settings_photo_hd'),
            title: const Text('Foto em HD'),
            subtitle: Text(_photoHd ? '1080p' : '720p'),
            value: _photoHd,
            onChanged: _onPhotoHdChanged,
          ),
          SwitchListTile(
            key: const Key('settings_video_hd'),
            title: const Text('Vídeo em HD'),
            subtitle: Text(_videoHd ? '1080p' : '720p'),
            value: _videoHd,
            onChanged: _onVideoHdChanged,
          ),
        ],
      ),
    );
  }
}
