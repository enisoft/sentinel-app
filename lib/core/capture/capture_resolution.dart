import 'package:camera/camera.dart';

/// Preset de captura: HD (~1080p) ou padrão (~720p).
ResolutionPreset resolutionPresetForHd(bool hd) =>
    hd ? ResolutionPreset.high : ResolutionPreset.medium;
