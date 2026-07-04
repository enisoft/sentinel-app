import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/presentation/capture/camera_zoom_controls.dart';

void main() {
  testWidgets('exibe níveis suportados e destaca o ativo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraZoomControls(
            getMinZoomLevel: () async => 1.0,
            getMaxZoomLevel: () async => 8.0,
            setZoomLevel: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('camera_zoom_controls')), findsOneWidget);
    expect(find.byKey(const Key('camera_zoom_1x')), findsOneWidget);
    expect(find.byKey(const Key('camera_zoom_2x')), findsOneWidget);
    expect(find.byKey(const Key('camera_zoom_4x')), findsOneWidget);
    expect(find.byKey(const Key('camera_zoom_0.5x')), findsNothing);
  });

  testWidgets('selecionar nível chama setZoomLevel correspondente', (tester) async {
    final applied = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraZoomControls(
            getMinZoomLevel: () async => 0.5,
            getMaxZoomLevel: () async => 8.0,
            setZoomLevel: (zoom) async => applied.add(zoom),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // applyInitial aplica 1x.
    expect(applied, [1.0]);

    await tester.tap(find.byKey(const Key('camera_zoom_2x')));
    await tester.pumpAndSettle();

    expect(applied, [1.0, 2.0]);

    await tester.tap(find.byKey(const Key('camera_zoom_0.5x')));
    await tester.pumpAndSettle();

    expect(applied, [1.0, 2.0, 0.5]);
  });

  testWidgets('não exibe controles com um único nível', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraZoomControls(
            getMinZoomLevel: () async => 1.0,
            getMaxZoomLevel: () async => 1.0,
            setZoomLevel: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('camera_zoom_controls')), findsNothing);
  });
}
