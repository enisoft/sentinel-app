import 'dart:async';

/// Monitor de inatividade para upload TUS (ENI-105).
///
/// Reinicia um timer a cada [onProgress]; se nenhum progresso ocorrer em
/// [stallTimeout], dispara [onStalled] uma única vez.
class TusUploadStallGuard {
  TusUploadStallGuard({
    required this.stallTimeout,
    required Future<void> Function() onStalled,
  }) : _onStalled = onStalled;

  final Duration stallTimeout;
  final Future<void> Function() _onStalled;

  Timer? _timer;
  bool didStall = false;

  void start() => _resetTimer();

  void onProgress() {
    if (didStall) return;
    _resetTimer();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(stallTimeout, () {
      if (didStall) return;
      didStall = true;
      unawaited(_onStalled());
    });
  }
}
