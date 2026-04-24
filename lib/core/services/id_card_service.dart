import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class IdCardService {
  static Future<Uint8List?> captureCard({
    required GlobalKey cardKey,
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('IdCardService: capture failed — $e');
      return null;
    }
  }

  static Future<void> shareCard({
    required GlobalKey cardKey,
    required String petName,
    double pixelRatio = 3.0,
  }) async {
    final bytes = await captureCard(cardKey: cardKey, pixelRatio: pixelRatio);
    if (bytes == null) return;

    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/${petName}_id_card.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "$petName's Pet ID Card — powered by PawPass",
    );
  }
}