import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

class AwesomeSnackbarWidget {
  static void show({
    required BuildContext context,
    required String msg,
    required ContentType type,
    bool top = false,
  }) {
    if (top) {
      _showTopOverlay(context, msg, type);
    } else {
      _showBottomSnackbar(context, msg, type);
    }
  }

  static void _showTopOverlay(
    BuildContext context,
    String msg,
    ContentType type,
  ) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AwesomeSnackbarContent(
            title: _getTitle(type),
            message: msg,
            contentType: type,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  static void _showBottomSnackbar(
    BuildContext context,
    String msg,
    ContentType type,
  ) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      duration: const Duration(seconds: 3),
      content: AwesomeSnackbarContent(
        title: _getTitle(type),
        message: msg,
        contentType: type,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static String _getTitle(ContentType type) {
    switch (type) {
      case ContentType.success:
        return 'Berhasil 🎉';
      case ContentType.warning:
        return 'Perhatian ⚠️';
      case ContentType.failure:
        return 'Gagal ❌';
      default:
        return 'Info ℹ️';
    }
  }
}
