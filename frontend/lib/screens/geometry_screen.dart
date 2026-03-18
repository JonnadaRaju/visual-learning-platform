import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Maths: Geometry — Area, Perimeter & Pythagoras interactive visualizer
class GeometryScreen extends ConsumerStatefulWidget {
  const GeometryScreen({super.key});
  @override
  ConsumerState<GeometryScreen> createState() => _GeometryScreenState();
}

class _GeometryScreenState extends ConsumerState<GeometryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 0 = Triangle, 1 = Circle, 2 = Rectangle
  int _shapeIndex = 0;

  // Triangle
  double _triBase = 6;
  double _triHeight = 4;

  // Circle
  double _circleRadius = 4;

  // Rectangle
  double _rectW = 7;
  double _rectH = 4;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _area {
    switch (_shapeIndex) {
      case 0: return 0.5 * _triBase * _triHeight;
      case 1: return math.pi * _circleRadius * _circleRadius;
      case 2: return _rectW * _rectH;
      default: return 0;
    }
  }

  double get _perimeter {
    switch (_shapeIndex) {
      case 0:
        // right-triangle hypotenuse
        final hyp = math.sqrt(_triBase * _triBase + _triHeight * _triHeight);
        return _triBase + _triHeight + hyp;
      case 1: return 2 * math.pi * _circleRadius;
      case 2: return 2 * (_rectW + _rectH);
      default: return 0;
    }
  }

  Future<void> _showAiExplanation(BuildContext context, String topic) async {
    final api = ref.read(apiServiceProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final explanation = await api.explainTopic(topic);
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
              SizedBox(width: 8),
              Text('AI Explanation', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(explanation, style: const TextStyle(color: Colors.white70)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it!'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get explanation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        title: const Text('Geometry Explorer'),
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
            tooltip: 'Explain this topic',
            onPressed: () => _showAiExplanation(context, 'geometry'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _GeometryPainter(
                      shapeIndex: _shapeIndex,
                      triBase: _triBase,
                      triHeight: _triHeight,
                      circleRadius: _circleRadius,
                      rectW: _rectW,
                      rectH: _rectH,
                      pulse: _controller.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A24),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Shape selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12121A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _shapeTab(0, '▲ Triangle'),
                      _shapeTab(1, '● Circle'),
                      _shapeTab(2, '■ Rectangle'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Controls per shape
                if (_shapeIndex == 0) ...[
                  _buildSlider('Base', _triBase, 1, 10, ' units',
                      (v) => setState(() => _triBase = v)),
                  _buildSlider('Height', _triHeight, 1, 8, ' units',
                      (v) => setState(() => _triHeight = v)),
                ],
                if (_shapeIndex == 1) ...[
                  _buildSlider('Radius', _circleRadius, 1, 7, ' units',
                      (v) => setState(() => _circleRadius = v)),
                ],
                if (_shapeIndex == 2) ...[
                  _buildSlider('Width', _rectW, 1, 10, ' units',
                      (v) => setState(() => _rectW = v)),
                  _buildSlider('Height', _rectH, 1, 8, ' units',
                      (v) => setState(() => _rectH = v)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12121A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Area', '${_area.toStringAsFixed(2)} u²'),
                      _buildStat(_shapeIndex == 1 ? 'Circumference' : 'Perimeter',
                          '${_perimeter.toStringAsFixed(2)} u'),
                      if (_shapeIndex == 0)
                        _buildStat('Hypotenuse',
                            '${math.sqrt(_triBase * _triBase + _triHeight * _triHeight).toStringAsFixed(2)} u'),
                      if (_shapeIndex == 1)
                        _buildStat('Diameter',
                            '${(2 * _circleRadius).toStringAsFixed(1)} u'),
                      if (_shapeIndex == 2)
                        _buildStat('Diagonal',
                            '${math.sqrt(_rectW * _rectW + _rectH * _rectH).toStringAsFixed(2)} u'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formulaText,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _formulaText {
    switch (_shapeIndex) {
      case 0: return 'Area = ½ × b × h   •   Pythagoras: c² = a² + b²';
      case 1: return 'Area = πr²   •   Circumference = 2πr';
      case 2: return 'Area = w × h   •   Perimeter = 2(w + h)';
      default: return '';
    }
  }

  Widget _shapeTab(int index, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _shapeIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: _shapeIndex == index
                  ? const Color(0xFFBA68C8)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _shapeIndex == index ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: _shapeIndex == index ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );

  Widget _buildSlider(String label, double value, double min, double max,
      String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('${value.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                    color: Color(0xFFBA68C8), fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFBA68C8),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: const Color(0xFFBA68C8),
            overlayColor: const Color(0xFFBA68C8).withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) => Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      );
}

class _GeometryPainter extends CustomPainter {
  final int shapeIndex;
  final double triBase, triHeight, circleRadius, rectW, rectH, pulse;

  _GeometryPainter({
    required this.shapeIndex,
    required this.triBase, required this.triHeight,
    required this.circleRadius,
    required this.rectW, required this.rectH,
    required this.pulse,
  });

  static const Color _accent = Color(0xFFBA68C8);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    const scale = 28.0; // pixels per unit

    final fillP = Paint()..color = _accent.withValues(alpha: 0.18);
    final strokeP = Paint()
      ..color = _accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dimP = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    void label(String text, Offset pos, {Color color = Colors.white}) {
      tp.text = TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold));
      tp.layout();
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: pos, width: tp.width + 10, height: tp.height + 6),
              const Radius.circular(4)),
          Paint()..color = const Color(0xFF0D0D16).withValues(alpha: 0.8));
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    void dimLine(Offset a, Offset b, String text) {
      canvas.drawLine(a, b, dimP);
      // tick marks
      canvas.drawLine(
          Offset(a.dx - 4, a.dy), Offset(a.dx + 4, a.dy), dimP);
      canvas.drawLine(
          Offset(b.dx - 4, b.dy), Offset(b.dx + 4, b.dy), dimP);
      label(text, Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 - 14),
          color: Colors.white.withValues(alpha: 0.6));
    }

    // Pulsing glow
    canvas.drawCircle(Offset(cx, cy), 80 + pulse * 12,
        Paint()..color = _accent.withValues(alpha: 0.04 + pulse * 0.02));

    switch (shapeIndex) {
      case 0: // Triangle
        final bPx = triBase * scale;
        final hPx = triHeight * scale;
        final x0 = cx - bPx / 2, y0 = cy + hPx / 2;
        final x1 = cx + bPx / 2, y1 = y0;
        final x2 = cx, y2 = cy - hPx / 2;

        final triPath = Path()
          ..moveTo(x0, y0) ..lineTo(x1, y1) ..lineTo(x2, y2) ..close();
        canvas.drawPath(triPath, fillP);
        canvas.drawPath(triPath, strokeP);

        // Right angle box at base-right
        canvas.drawRect(Rect.fromLTWH(x0, y0 - 10, 10, 10), dimP);

        // Dimension lines
        dimLine(Offset(x0, y0 + 20), Offset(x1, y0 + 20), 'b=${triBase.toStringAsFixed(1)}u');
        dimLine(Offset(x1 + 20, y2), Offset(x1 + 20, y1), 'h=${triHeight.toStringAsFixed(1)}u');

        // Hypotenuse label
        final hyp = math.sqrt(triBase * triBase + triHeight * triHeight);
        label('c=${hyp.toStringAsFixed(2)}u',
            Offset((x0 + x2) / 2 - 22, (y0 + y2) / 2),
            color: Colors.amber.withValues(alpha: 0.85));

        // Area label inside
        label('A=${(0.5 * triBase * triHeight).toStringAsFixed(1)}u²',
            Offset(cx, cy + 10), color: _accent);
        break;

      case 1: // Circle
        final rPx = circleRadius * scale;
        final glowR = rPx + 6 + pulse * 4;
        canvas.drawCircle(Offset(cx, cy), glowR,
            Paint()..color = _accent.withValues(alpha: 0.08));
        canvas.drawCircle(Offset(cx, cy), rPx, fillP);
        canvas.drawCircle(Offset(cx, cy), rPx, strokeP);

        // Radius line
        canvas.drawLine(Offset(cx, cy), Offset(cx + rPx, cy),
            Paint()..color = Colors.amber..strokeWidth = 2..strokeCap = StrokeCap.round);
        canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = Colors.white);
        label('r=${circleRadius.toStringAsFixed(1)}u',
            Offset(cx + rPx / 2, cy - 14), color: Colors.amber);

        // Diameter arrow
        canvas.drawLine(Offset(cx - rPx, cy + rPx * 0.7),
            Offset(cx + rPx, cy + rPx * 0.7),
            Paint()..color = Colors.tealAccent.withValues(alpha: 0.6)..strokeWidth = 1.5);
        label('d=${(2 * circleRadius).toStringAsFixed(1)}u',
            Offset(cx, cy + rPx * 0.7 + 14), color: Colors.tealAccent);

        // Area label
        label('A=${(math.pi * circleRadius * circleRadius).toStringAsFixed(2)}u²',
            Offset(cx, cy + 10), color: _accent);
        break;

      case 2: // Rectangle
        final wPx = rectW * scale;
        final hPx = rectH * scale;
        final rx = cx - wPx / 2, ry = cy - hPx / 2;

        // Diagonal
        canvas.drawLine(Offset(rx, ry + hPx), Offset(rx + wPx, ry),
            Paint()
              ..color = Colors.amber.withValues(alpha: 0.5)
              ..strokeWidth = 1.5
              ..strokeCap = StrokeCap.round);

        canvas.drawRect(Rect.fromLTWH(rx, ry, wPx, hPx), fillP);
        canvas.drawRect(Rect.fromLTWH(rx, ry, wPx, hPx), strokeP);

        // Right angle marks
        canvas.drawPath(Path()
          ..moveTo(rx + 12, ry) ..lineTo(rx + 12, ry + 12) ..lineTo(rx, ry + 12), dimP);

        // Dimension lines
        dimLine(Offset(rx, ry + hPx + 22), Offset(rx + wPx, ry + hPx + 22),
            'w=${rectW.toStringAsFixed(1)}u');
        dimLine(Offset(rx - 22, ry), Offset(rx - 22, ry + hPx),
            'h=${rectH.toStringAsFixed(1)}u');

        // Diagonal label
        final diag = math.sqrt(rectW * rectW + rectH * rectH);
        label('diag=${diag.toStringAsFixed(2)}u',
            Offset(cx + 20, cy - 16), color: Colors.amber.withValues(alpha: 0.85));

        // Area label
        label('A=${(rectW * rectH).toStringAsFixed(1)}u²',
            Offset(cx, cy), color: _accent);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GeometryPainter old) =>
      old.shapeIndex != shapeIndex || old.triBase != triBase ||
      old.triHeight != triHeight || old.circleRadius != circleRadius ||
      old.rectW != rectW || old.rectH != rectH || old.pulse != pulse;
}