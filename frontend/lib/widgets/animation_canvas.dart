import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/compute_result.dart';

class AnimatedWaveSeries {
  const AnimatedWaveSeries({
    required this.label,
    required this.points,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final List<PlotPoint> points;
  final Color color;
  final bool highlight;
}

class CircuitVisualComponent {
  const CircuitVisualComponent({
    required this.id,
    required this.type,
    required this.label,
    required this.value,
    required this.position,
    required this.size,
  });

  final String id;
  final String type;
  final String label;
  final double value;
  final Offset position;
  final Size size;

  Offset terminalA() => Offset(position.dx, position.dy + size.height / 2);
  Offset terminalB() =>
      Offset(position.dx + size.width, position.dy + size.height / 2);
}

class CircuitVisualWire {
  const CircuitVisualWire(
      {required this.id, required this.start, required this.end, this.speed = 0});

  final String id;
  final Offset start;
  final Offset end;
  final double speed;
}

class AnimationCanvas extends StatefulWidget {
  const AnimationCanvas.projectile({
    super.key,
    required this.projectilePoints,
  })  : scene = AnimationScene.projectile,
        waveSeries = const [],
        wires = const [];

  const AnimationCanvas.waves({
    super.key,
    required this.waveSeries,
  })  : scene = AnimationScene.waves,
        projectilePoints = const [],
        wires = const [];

  const AnimationCanvas.circuit({
    super.key,
    required this.wires,
  })  : scene = AnimationScene.circuit,
        projectilePoints = const [],
        waveSeries = const [];

  final AnimationScene scene;
  final List<PlotPoint> projectilePoints;
  final List<AnimatedWaveSeries> waveSeries;
  final List<CircuitVisualWire> wires;

  @override
  State<AnimationCanvas> createState() => _AnimationCanvasState();
}

enum AnimationScene { projectile, waves, circuit }

class _AnimationCanvasState extends State<AnimationCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimationCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scene != oldWidget.scene) {
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 280,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            switch (widget.scene) {
              case AnimationScene.projectile:
                return CustomPaint(
                  painter: _ProjectilePainter(
                    points: widget.projectilePoints,
                    progress: _controller.value,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  child: const SizedBox.expand(),
                );
              case AnimationScene.waves:
                return CustomPaint(
                  painter: _WavePainter(
                    series: widget.waveSeries,
                    progress: _controller.value,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  child: const SizedBox.expand(),
                );
              case AnimationScene.circuit:
                return CustomPaint(
                  painter: _CircuitPainter(
                    wires: widget.wires,
                    progress: _controller.value,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  child: const SizedBox.expand(),
                );
            }
          },
        ),
      ),
    );
  }
}

class _ProjectilePainter extends CustomPainter {
  _ProjectilePainter(
      {required this.points,
      required this.progress,
      required this.colorScheme});

  final List<PlotPoint> points;
  final double progress;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE8F3EC);
    canvas.drawRect(Offset.zero & size, background);
    final groundPaint = Paint()
      ..color = const Color(0xFF355E3B)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, size.height - 28),
        Offset(size.width, size.height - 28), groundPaint);
    if (points.isEmpty) {
      _drawCenterLabel(canvas, size, 'Run the simulation to view the arc.');
      return;
    }
    final maxX = points.map((p) => p.x).reduce(math.max);
    final maxY = points.map((p) => p.y).reduce(math.max);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final dx = 24 + (p.x / (maxX == 0 ? 1 : maxX)) * (size.width - 48);
      final dy =
          size.height - 28 - (p.y / (maxY == 0 ? 1 : maxY)) * (size.height - 64);
      i == 0 ? path.moveTo(dx, dy) : path.lineTo(dx, dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    final ai = (progress * (points.length - 1)).round().clamp(0, points.length - 1);
    final ball = points[ai];
    final bx = 24 + (ball.x / (maxX == 0 ? 1 : maxX)) * (size.width - 48);
    final by = size.height -
        28 -
        (ball.y / (maxY == 0 ? 1 : maxY)) * (size.height - 64);
    canvas.drawCircle(Offset(bx, by), 10,
        Paint()..color = colorScheme.secondary);
  }

  @override
  bool shouldRepaint(covariant _ProjectilePainter old) =>
      old.points != points || old.progress != progress;
}

class _WavePainter extends CustomPainter {
  _WavePainter(
      {required this.series,
      required this.progress,
      required this.colorScheme});

  final List<AnimatedWaveSeries> series;
  final double progress;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFF5F3EA));
    final axisPaint = Paint()
      ..color = colorScheme.outline
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(20, size.height / 2),
        Offset(size.width - 20, size.height / 2), axisPaint);
    canvas.drawLine(
        Offset(24, 20), Offset(24, size.height - 20), axisPaint);
    if (series.isEmpty) {
      _drawCenterLabel(canvas, size, 'Adjust sliders to animate the wave.');
      return;
    }
    final maxY = series
        .expand((s) => s.points)
        .map((p) => p.y.abs())
        .fold<double>(1, math.max);
    for (final item in series) {
      if (item.points.isEmpty) continue;
      final offset = (progress * item.points.length).round();
      final path = Path();
      for (var i = 0; i < item.points.length; i++) {
        final p = item.points[(i + offset) % item.points.length];
        final dx =
            24 + (i / (item.points.length - 1)) * (size.width - 48);
        final dy =
            size.height / 2 - (p.y / maxY) * (size.height / 2 - 28);
        i == 0 ? path.moveTo(dx, dy) : path.lineTo(dx, dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = item.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = item.highlight ? 4 : 2.5);
    }
    final tp = TextPainter(textDirection: TextDirection.ltr);
    var y = 16.0;
    for (final item in series) {
      tp.text = TextSpan(
          text: item.label,
          style: TextStyle(
              color: item.color,
              fontSize: 12,
              fontWeight: FontWeight.w600));
      tp.layout();
      tp.paint(canvas, Offset(size.width - tp.width - 14, y));
      y += tp.height + 6;
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.series != series || old.progress != progress;
}

class _CircuitPainter extends CustomPainter {
  _CircuitPainter(
      {required this.wires,
      required this.progress,
      required this.colorScheme});

  final List<CircuitVisualWire> wires;
  final double progress;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFEEF0F8));
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 24.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (wires.isEmpty) {
      _drawCenterLabel(
          canvas, size, 'Tap two terminals to create wires.');
      return;
    }
    for (final wire in wires) {
      canvas.drawLine(
          wire.start,
          wire.end,
          Paint()
            ..color = colorScheme.primary
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
      final dotCount = math.max(1, (wire.speed.abs() * 4).round());
      for (var i = 0; i < dotCount; i++) {
        final shifted = (progress + (i / dotCount)) % 1;
        final dx =
            wire.start.dx + (wire.end.dx - wire.start.dx) * shifted;
        final dy =
            wire.start.dy + (wire.end.dy - wire.start.dy) * shifted;
        canvas.drawCircle(
            Offset(dx, dy), 4.5, Paint()..color = colorScheme.tertiary);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter old) =>
      old.wires != wires || old.progress != progress;
}

void _drawCenterLabel(Canvas canvas, Size size, String text) {
  final painter = TextPainter(
    text: TextSpan(
        text: text,
        style: const TextStyle(
            color: Color(0xFF5E6470),
            fontSize: 15,
            fontWeight: FontWeight.w600)),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width - 40);
  painter.paint(
      canvas,
      Offset((size.width - painter.width) / 2,
          (size.height - painter.height) / 2));
}