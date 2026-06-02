import 'dart:math';
import 'package:flutter/material.dart';

class Sparkle {
  final String id;
  double x;
  double y;
  final String text;
  double vx;
  double vy;
  double rotation;
  final double rotationSpeed;
  double scale;
  final Color color;

  Sparkle({
    required this.id,
    required this.x,
    required this.y,
    required this.text,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.scale,
    required this.color,
  });
}

class SparkleOverlay extends StatefulWidget {
  final Widget child;

  const SparkleOverlay({super.key, required this.child});

  @override
  State<SparkleOverlay> createState() => _SparkleOverlayState();
}

class _SparkleOverlayState extends State<SparkleOverlay> with SingleTickerProviderStateMixin {
  final List<Sparkle> _sparkles = [];
  late AnimationController _controller;
  final Random _random = Random();

  final List<String> _sparkleSymbols = ['✨', '✦', '⭐', '✧'];
  final List<Color> _presetColors = [
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF43F5E),
    Colors.blue,
    Colors.amber,
    Colors.purple,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateSparkles);
  }

  void _updateSparkles() {
    if (_sparkles.isEmpty) {
      if (_controller.isAnimating) _controller.stop();
      return;
    }

    setState(() {
      for (var s in _sparkles) {
        s.x += s.vx;
        s.y += s.vy;
        s.vy += 0.15; // mild gravity
        s.rotation += s.rotationSpeed;
        s.scale -= 0.04; // decay rate
      }
      // Remove dead sparkles or off-screen ones
      _sparkles.removeWhere((s) => s.scale <= 0 || s.y > MediaQuery.of(context).size.height + 50);
    });

    if (_sparkles.isNotEmpty) {
      _controller.forward(from: 0.0);
    }
  }

  void _spawnSparkles(Offset globalPosition) {
    // Generate gentle burst of 3 to 6 sparkles on tap
    final count = _random.nextInt(4) + 3;
    
    for (int i = 0; i < count; i++) {
      final double angle = _random.nextDouble() * pi * 2;
      final double speed = 1.0 + _random.nextDouble() * 2.5;
      final double vx = cos(angle) * speed;
      final double vy = sin(angle) * speed - 0.8;

      final sparkle = Sparkle(
        id: 'sparkle_${DateTime.now().microsecondsSinceEpoch}_$i',
        x: globalPosition.dx,
        y: globalPosition.dy,
        text: _sparkleSymbols[_random.nextInt(_sparkleSymbols.length)],
        vx: vx,
        vy: vy,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        scale: 0.4 + _random.nextDouble() * 0.4,
        color: _presetColors[_random.nextInt(_presetColors.length)],
      );

      _sparkles.add(sparkle);
    }

    if (!_controller.isAnimating) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        _spawnSparkles(event.position);
      },
      child: Stack(
        children: [
          widget.child,
          IgnorePointer(
            child: CustomPaint(
              painter: SparklePainter(sparkles: _sparkles),
              child: Container(),
            ),
          )
        ],
      ),
    );
  }
}

class SparklePainter extends CustomPainter {
  final List<Sparkle> sparkles;

  SparklePainter({required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var sparkle in sparkles) {
      if (sparkle.scale <= 0) continue;

      canvas.save();
      canvas.translate(sparkle.x, sparkle.y);
      canvas.rotate(sparkle.rotation * pi / 180);
      canvas.scale(sparkle.scale);

      textPainter.text = TextSpan(
        text: sparkle.text,
        style: TextStyle(
          color: sparkle.color,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 8.0,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) {
    return true;
  }
}
