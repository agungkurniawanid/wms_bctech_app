import 'package:flutter/material.dart';

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    final double curveFactor = size.width * 0.1;

    path.lineTo(0, size.height - curveFactor);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + curveFactor,
      size.width,
      size.height - curveFactor,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
