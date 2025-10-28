import 'dart:math';

import 'package:flutter/material.dart';

class CompassCustomPainter extends CustomPainter {
  final double angle;

  const CompassCustomPainter({
    required this.angle,
  });

  // Keeps rotating the North Red Triangle
  double get rotation => -angle * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    // Minimal Compass

    // Center The Compass In The Middle Of The Screen
    canvas.translate(size.width / 2, size.height / 2);

    Paint circle = Paint()
      ..strokeWidth = 2
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 🛠️ FIX: Replaced Colors.grey.withOpacity(.2) with an explicit Color.fromARGB
    // This resolves the 'deprecated_member_use' warning.
    Paint shadowCircle = Paint()
      ..strokeWidth = 2
      ..color = const Color.fromARGB(51, 158, 158, 158) 
      ..style = PaintingStyle.fill;

    // Draw Shadow For Outer Circle
    canvas.drawCircle(Offset.zero, 107, shadowCircle);

    // Draw Outer Circle
    canvas.drawCircle(Offset.zero, 100, circle);

    Paint darkIndexLine = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    Paint lightIndexLine = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    Paint northRedBrush = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    // Rotate the canvas so that 0 degrees (North) is at the top
    canvas.rotate(-pi / 2);

    // Draw The Light Grey Lines 16 Times While Rotating 22.5° Degrees
    for (int i = 1; i <= 16; i++) {
      canvas.drawLine(
          Offset.fromDirection(-(angle + 22.5 * i) * pi / 180, 60),
          Offset.fromDirection(-(angle + 22.5 * i) * pi / 180, 80),
          lightIndexLine);
    }

    // Draw The Dark Grey Lines 3 Times While Rotating 90° Degrees
    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(
          Offset.fromDirection(-(angle + 90 * i) * pi / 180, 60),
          Offset.fromDirection(-(angle + 90 * i) * pi / 180, 80),
          darkIndexLine);
    }

    canvas.drawLine(Offset.fromDirection(rotation, 60),
        Offset.fromDirection(rotation, 80), northRedBrush);

    // Draw Shadow For Inner Circle
    // 🛠️ FIX: Corrected to use the shadowCircle Paint object, not just a Color.
    canvas.drawCircle(Offset.zero, 68, shadowCircle);

    // Draw Inner Circle
    canvas.drawCircle(Offset.zero, 65, circle);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
