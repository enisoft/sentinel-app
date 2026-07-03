/// Limite rígido de gravação de vídeo (5 minutos).
const int kMaxVideoDurationSeconds = 300;

/// Retorna true quando a gravação deve ser encerrada automaticamente.
bool shouldAutoStopRecording(int elapsedSeconds) =>
    elapsedSeconds >= kMaxVideoDurationSeconds;

/// Formata segundos decorridos como `mm:ss` (ex.: `04:59`, `05:00`).
String formatRecordingElapsed(int elapsedSeconds) {
  final minutes = elapsedSeconds ~/ 60;
  final seconds = elapsedSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
