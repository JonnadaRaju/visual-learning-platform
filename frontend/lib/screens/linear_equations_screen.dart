import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../widgets/ai_explanation_dialog.dart';

/// Maths: Linear Equations — y = mx + c interactive visualizer
class LinearEquationsScreen extends ConsumerStatefulWidget {
  const LinearEquationsScreen({super.key});

  @override
  ConsumerState<LinearEquationsScreen> createState() => _LinearEquationsScreenState();
}

class _LinearEquationsScreenState extends ConsumerState<LinearEquationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _m1 = 2;
  double _c1 = 1;
  double _m2 = -1;
  double _c2 = 4;
  bool _showSecond = true;
  bool _showIntersection = true;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Intersection: m1*x + c1 = m2*x + c2  => x = (c2-c1)/(m1-m2)
  double? get _intersectX {
    if ((_m1 - _m2).abs() < 0.001) return null;
    return (_c2 - _c1) / (_m1 - _m2);
  }

  double? get _intersectY {
    final x = _intersectX;
    if (x == null) return null;
    return _m1 * x + _c1;
  }

  void _saveRun() {
    ref.read(apiServiceProvider).saveGenericRun(
      slug: 'linear-equations',
      inputParams: {
        'm1': _m1,
        'c1': _c1,
        'm2': _m2,
        'c2': _c2,
        'show_second': _showSecond ? 1.0 : 0.0,
      },
      resultPayload: {
        'intersect_x': _intersectX ?? 0.0,
        'intersect_y': _intersectY ?? 0.0,
        'parallel': _intersectX == null ? 1.0 : 0.0,
      },
    );
  }

  Future<void> _showAiExplanation(BuildContext context, String topic) async {
    final api = ref.read(apiServiceProvider);
    showLoading(context);
    try {
      final explanation = await api.explainTopic(topic);
      if (!mounted) return;
      Navigator.pop(context);
      showAiExplanation(context, topic, explanation);
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
    final ix = _intersectX;
    final iy = _intersectY;
    final parallel = ix == null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        title: const Text('Linear Equations'),
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
            tooltip: 'Explain this topic',
            onPressed: () => _showAiExplanation(context, 'linear-equations'),
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
                    painter: _GraphPainter(
                      m1: _m1, c1: _c1,
                      m2: _m2, c2: _c2,
                      showSecond: _showSecond,
                      showIntersection: _showIntersection,
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
                // Line 1 controls
                _sectionLabel('Line 1  —  y = ${_m1.toStringAsFixed(1)}x + ${_c1.toStringAsFixed(1)}',
                    const Color(0xFF378ADD)),
                _buildSlider('Slope (m)', _m1, -5, 5, '', (v) { setState(() => _m1 = v); _saveRun(); }),
                _buildSlider('Intercept (c)', _c1, -8, 8, '', (v) { setState(() => _c1 = v); _saveRun(); }),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Show Line 2', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Switch(
                      value: _showSecond,
                      onChanged: (v) { setState(() => _showSecond = v); _saveRun(); },
                      activeColor: Colors.tealAccent,
                    ),
                    const Spacer(),
                    const Text('Intersection', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Switch(
                      value: _showIntersection,
                      onChanged: (v) => setState(() => _showIntersection = v),
                      activeColor: Colors.amber,
                    ),
                  ],
                ),
                if (_showSecond) ...[
                  _sectionLabel('Line 2  —  y = ${_m2.toStringAsFixed(1)}x + ${_c2.toStringAsFixed(1)}',
                      Colors.tealAccent),
                  _buildSlider('Slope (m)', _m2, -5, 5, '', (v) { setState(() => _m2 = v); _saveRun(); }),
                  _buildSlider('Intercept (c)', _c2, -8, 8, '', (v) { setState(() => _c2 = v); _saveRun(); }),
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
                      _buildStat('Line 1 slope', _m1.toStringAsFixed(2)),
                      _buildStat('Line 2 slope', _showSecond ? _m2.toStringAsFixed(2) : '—'),
                      _buildStat(
                        'Intersection',
                        parallel
                            ? 'Parallel'
                            : !_showSecond
                                ? '—'
                                : '(${ix!.toStringAsFixed(1)}, ${iy!.toStringAsFixed(1)})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'y = mx + c   •   Slope = rise/run   •   Intersect when y₁ = y₂',
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

  Widget _sectionLabel(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
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
                style: const TextStyle(color: Color(0xFFBA68C8), fontWeight: FontWeight.bold)),
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

class _GraphPainter extends CustomPainter {
  final double m1, c1, m2, c2;
  final bool showSecond, showIntersection;
  final double pulse;

  _GraphPainter({
    required this.m1, required this.c1,
    required this.m2, required this.c2,
    required this.showSecond,
    required this.showIntersection,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 40.0;
    final cx = size.width / 2, cy = size.height / 2;
    final range = 8.0; // ±8 units

    Offset toScreen(double x, double y) => Offset(
      cx + x * (size.width - pad * 2) / (range * 2),
      cy - y * (size.height - pad * 2) / (range * 2),
    );

    // Grid
    final gridP = Paint()..color = Colors.white.withValues(alpha: 0.06)..strokeWidth = 0.5;
    for (int i = -8; i <= 8; i++) {
      final xp = toScreen(i.toDouble(), 0);
      final yp = toScreen(0, i.toDouble());
      canvas.drawLine(Offset(xp.dx, pad), Offset(xp.dx, size.height - pad), gridP);
      canvas.drawLine(Offset(pad, yp.dy), Offset(size.width - pad, yp.dy), gridP);
    }

    // Axes
    final axP = Paint()..color = Colors.white.withValues(alpha: 0.3)..strokeWidth = 1.2;
    canvas.drawLine(Offset(pad, cy), Offset(size.width - pad, cy), axP);
    canvas.drawLine(Offset(cx, pad), Offset(cx, size.height - pad), axP);

    // Axis labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = -7; i <= 7; i += 2) {
      if (i == 0) continue;
      final xp = toScreen(i.toDouble(), 0);
      final yp = toScreen(0, i.toDouble());
      tp.text = TextSpan(text: '$i',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9));
      tp.layout();
      tp.paint(canvas, Offset(xp.dx - tp.width / 2, cy + 4));
      tp.paint(canvas, Offset(cx + 4, yp.dy - tp.height / 2));
    }
    // Axis name labels
    tp.text = TextSpan(text: 'x', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11));
    tp.layout(); tp.paint(canvas, Offset(size.width - pad + 4, cy - 8));
    tp.text = TextSpan(text: 'y', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11));
    tp.layout(); tp.paint(canvas, Offset(cx + 6, pad - 14));

    // Draw line helper
    void drawLine(double m, double c, Color color, double strokeW) {
      final x0 = -range - 1, x1 = range + 1;
      final p0 = toScreen(x0, m * x0 + c);
      final p1 = toScreen(x1, m * x1 + c);
      canvas.drawLine(p0, p1, Paint()..color = color..strokeWidth = strokeW..strokeCap = StrokeCap.round);
      // Y-intercept dot
      final intercept = toScreen(0, c);
      canvas.drawCircle(intercept, 5, Paint()..color = color);
      tp.text = TextSpan(text: 'c=${c.toStringAsFixed(1)}',
          style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10));
      tp.layout();
      tp.paint(canvas, Offset(intercept.dx + 8, intercept.dy - 12));
    }

    drawLine(m1, c1, const Color(0xFF378ADD), 2.5);
    if (showSecond) drawLine(m2, c2, Colors.tealAccent, 2.0);

    // Intersection point
    if (showSecond && showIntersection) {
      final denom = m1 - m2;
      if (denom.abs() > 0.001) {
        final ix = (c2 - c1) / denom;
        final iy = m1 * ix + c1;
        if (ix.abs() <= range && iy.abs() <= range) {
          final iPos = toScreen(ix, iy);
          final r = 6.0 + pulse * 4;
          canvas.drawCircle(iPos, r,
              Paint()..color = Colors.amber.withValues(alpha: 0.3 - pulse * 0.1));
          canvas.drawCircle(iPos, 6,
              Paint()..color = Colors.amber);
          tp.text = TextSpan(
              text: '(${ix.toStringAsFixed(1)}, ${iy.toStringAsFixed(1)})',
              style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold));
          tp.layout();
          tp.paint(canvas, Offset(iPos.dx + 10, iPos.dy - 14));
        }
      }
    }

    // Slope triangles
    void drawSlopeTri(double m, double c, Color color) {
      const sx = 2.0;
      final p0 = toScreen(sx, m * sx + c);
      final p1 = toScreen(sx + 1, m * sx + c);
      final p2 = toScreen(sx + 1, m * (sx + 1) + c);
      final triPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(p0, p1, triPaint);
      canvas.drawLine(p1, p2, triPaint);
      final mid = Offset((p1.dx + p2.dx) / 2 + 4, (p1.dy + p2.dy) / 2);
      tp.text = TextSpan(text: 'm=${m.toStringAsFixed(1)}',
          style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 9));
      tp.layout();
      tp.paint(canvas, mid);
    }

    drawSlopeTri(m1, c1, const Color(0xFF378ADD));
    if (showSecond) drawSlopeTri(m2, c2, Colors.tealAccent);
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) =>
      old.m1 != m1 || old.c1 != c1 || old.m2 != m2 || old.c2 != c2 ||
      old.showSecond != showSecond || old.pulse != pulse;
}