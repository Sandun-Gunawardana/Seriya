import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';

const _navy = Color(0xFF10243E);
const _teal = Color(0xFF0F9D8B);

class SeriyaMap extends StatelessWidget {
  const SeriyaMap({super.key, required this.shift});

  final DailyShift shift;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _MapPainter()),
        const Positioned(
          left: 51,
          top: 290,
          child: _PickupMarker(initials: 'NK', label: 'Nimali'),
        ),
        const Positioned(
          right: 44,
          top: 356,
          child: _PickupMarker(initials: 'KS', label: 'Kasun'),
        ),
        Positioned(
          left: MediaQuery.sizeOf(context).width * 0.44,
          top: MediaQuery.sizeOf(context).height * 0.32,
          child: _VehicleMarker(shift: shift),
        ),
      ],
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({required this.shift});

  final DailyShift shift;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 11, 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3D10243E),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: const BoxDecoration(
                  color: _teal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  shift == DailyShift.morning
                      ? Icons.directions_bus_filled_rounded
                      : Icons.airport_shuttle_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NB-4521',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Moving · 32 km/h',
                    style: TextStyle(
                      color: Color(0xFF71807B),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(20, 11),
          painter: _MarkerTipPainter(color: Colors.white),
        ),
      ],
    );
  }
}

class _PickupMarker extends StatelessWidget {
  const _PickupMarker({required this.initials, required this.label});

  final String initials;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 51,
          height: 51,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3810243E),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD6EDE8),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(16, 9),
          painter: _MarkerTipPainter(color: Colors.white),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _navy,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MarkerTipPainter extends CustomPainter {
  const _MarkerTipPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MarkerTipPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE7F0E4),
    );

    final random = math.Random(14);
    final blockPaint = Paint()..color = const Color(0xFFD1E7CA);
    for (var i = 0; i < 36; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.78;
      final width = 24 + random.nextDouble() * 70;
      final height = 18 + random.nextDouble() * 48;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: width, height: height),
          const Radius.circular(14),
        ),
        blockPaint,
      );
    }

    _drawRoad(canvas, size, [
      Offset(-20, size.height * 0.16),
      Offset(size.width * 0.25, size.height * 0.25),
      Offset(size.width * 0.58, size.height * 0.21),
      Offset(size.width + 20, size.height * 0.34),
    ], 13);
    _drawRoad(canvas, size, [
      Offset(size.width * 0.08, -20),
      Offset(size.width * 0.20, size.height * 0.31),
      Offset(size.width * 0.46, size.height * 0.46),
      Offset(size.width * 0.67, size.height * 0.68),
      Offset(size.width * 0.78, size.height),
    ], 12);
    _drawRoad(canvas, size, [
      Offset(-20, size.height * 0.55),
      Offset(size.width * 0.31, size.height * 0.49),
      Offset(size.width * 0.55, size.height * 0.35),
      Offset(size.width * 0.73, size.height * 0.18),
      Offset(size.width + 20, size.height * 0.08),
    ], 10);
    _drawRoad(canvas, size, [
      Offset(-20, size.height * 0.40),
      Offset(size.width * 0.27, size.height * 0.42),
      Offset(size.width * 0.49, size.height * 0.58),
      Offset(size.width + 20, size.height * 0.64),
    ], 8);

    final route = Path()
      ..moveTo(size.width * 0.15, size.height * 0.48)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.40,
        size.width * 0.36,
        size.height * 0.45,
        size.width * 0.51,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.27,
        size.width * 0.72,
        size.height * 0.30,
        size.width * 0.87,
        size.height * 0.24,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = _teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    _drawLabel(
      canvas,
      'Kadawatha',
      Offset(size.width * 0.08, size.height * 0.45),
    );
    _drawLabel(
      canvas,
      'Kelaniya',
      Offset(size.width * 0.63, size.height * 0.16),
    );
    _drawLabel(
      canvas,
      'Colombo',
      Offset(size.width * 0.54, size.height * 0.55),
    );
  }

  void _drawRoad(Canvas canvas, Size size, List<Offset> points, double width) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFBEC8C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF8FAF7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF65726E),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
