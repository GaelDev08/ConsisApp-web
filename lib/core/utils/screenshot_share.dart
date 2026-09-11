import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

abstract final class ScreenshotShare {
  /// Captura un [RepaintBoundary] vía su [GlobalKey] y lo comparte a redes sociales.
  static Future<void> captureAndShare({
    required GlobalKey repaintKey,
    required BuildContext context,
    String text = '¡Sigo firme con mi consistencia en ConsisApp! 🚀🔥 #ConsisApp #Habitos',
  }) async {
    try {
      final boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'consis_app_progreso.png',
      );

      await Share.shareXFiles(
        [xFile],
        text: text,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compartiendo progreso... ($e)')),
        );
      }
    }
  }
}
