import 'package:flutter/material.dart';

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    // Tentukan faktor lekukan berdasarkan lebar layar.
    // 0.1 berarti 10% dari lebar layar.
    // Anda bisa mengubah 0.1 (misal 0.12 atau 0.08) untuk mengatur kedalaman lekukan.
    final double curveFactor = size.width * 0.1;

    path.lineTo(0, size.height - curveFactor); // <--- RESPONSIVE
    path.quadraticBezierTo(
      size.width / 2,
      size.height + curveFactor, // <--- RESPONSIVE
      size.width,
      size.height - curveFactor, // <--- RESPONSIVE
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
