import 'package:flutter/material.dart';

import '../../core/capture/camera_zoom_levels.dart';

/// Botões de nível de zoom no preview (ENI-58) — sem gesto de pinça/scroll.
class CameraZoomControls extends StatefulWidget {
  const CameraZoomControls({
    super.key,
    required this.getMinZoomLevel,
    required this.getMaxZoomLevel,
    required this.setZoomLevel,
  });

  final Future<double> Function() getMinZoomLevel;
  final Future<double> Function() getMaxZoomLevel;
  final Future<void> Function(double zoom) setZoomLevel;

  @override
  State<CameraZoomControls> createState() => _CameraZoomControlsState();
}

class _CameraZoomControlsState extends State<CameraZoomControls> {
  CameraZoomSession? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final minZoom = await widget.getMinZoomLevel();
      final maxZoom = await widget.getMaxZoomLevel();
      final session = CameraZoomSession(
        minZoom: minZoom,
        maxZoom: maxZoom,
        applyZoom: widget.setZoomLevel,
      );
      await session.applyInitial();
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _onLevelSelected(double level) async {
    final session = _session;
    if (session == null) return;
    await session.select(level);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final session = _session;
    if (session == null || session.levels.length < 2) {
      return const SizedBox.shrink();
    }

    return Row(
      key: const Key('camera_zoom_controls'),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final level in session.levels) ...[
          if (level != session.levels.first) const SizedBox(width: 8),
          _ZoomLevelButton(
            level: level,
            selected: level == session.selectedLevel,
            onTap: () => _onLevelSelected(level),
          ),
        ],
      ],
    );
  }
}

class _ZoomLevelButton extends StatelessWidget {
  const _ZoomLevelButton({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final double level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = formatZoomLevelLabel(level);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('camera_zoom_$label'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? Colors.white : Colors.black54,
            border: Border.all(
              color: selected ? Colors.white : Colors.white54,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black87 : Colors.white,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
