import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../widgets/ai_explanation_dialog.dart';
import 'sim_widgets.dart';

class GravitationOrbitsScreen extends ConsumerStatefulWidget {
  const GravitationOrbitsScreen({super.key});
  @override
  ConsumerState<GravitationOrbitsScreen> createState() =>
      _GravitationOrbitsScreenState();
}

class _GravitationOrbitsScreenState extends ConsumerState<GravitationOrbitsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _mass = 5;
  double _radius = 90;
  bool _moonEnabled = true;
  bool _isPaused = false;
  bool _showVectors = true;
  final List<_Star> _stars = [];

  static const _orbitAccent = Color(0xFF60B4F0);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    final rng = math.Random(42);
    for (int i = 0; i < 55; i++) {
      _stars.add(_Star(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          size: rng.nextDouble() * 1.8 + 0.4));
    }
  }

  double get _orbitalSpeed => math.sqrt(_mass / _radius);
  double get _period => 2 * math.pi * _radius / _orbitalSpeed;
  double get _gravityForce => _mass / (_radius * _radius) * 100;

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

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      _isPaused ? _controller.stop() : _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Gravitation & Orbits',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
            tooltip: 'Explain this topic',
            onPressed: () => _showAiExplanation(context, 'gravitation-orbits'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Kepler's 3rd: T² ∝ r³   •   F = GMm/r²",
                style: TextStyle(
                  color: _orbitAccent.withOpacity(0.6),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: SimCanvas(
              accentColor: _orbitAccent,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: OrbitPainter(
                    stars: _stars,
                    progress: _controller.value,
                    mass: _mass,
                    radius: _radius,
                    moonEnabled: _moonEnabled,
                    isPaused: _isPaused,
                    showVectors: _showVectors,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: SimControlsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SimSliderRow(
                    label: 'Planet Mass (M)',
                    value: _mass,
                    unit: ' units',
                    min: 1,
                    max: 12,
                    decimals: 1,
                    accentColor: _orbitAccent,
                    onChanged: (v) => setState(() => _mass = v),
                  ),
                  SimSliderRow(
                    label: 'Orbit Radius (r)',
                    value: _radius,
                    unit: ' px',
                    min: 50,
                    max: 130,
                    decimals: 0,
                    accentColor: _orbitAccent,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  const SizedBox(height: 8),
                  // Icon toggle row
                  Row(
                    children: [
                      SimIconToggle(
                        icon: Icons.nightlight_round,
                        label: 'Moon',
                        value: _moonEnabled,
                        activeColor: const Color(0xFFCCCCFF),
                        onChanged: (v) => setState(() => _moonEnabled = v),
                      ),
                      const SizedBox(width: 10),
                      SimIconToggle(
                        icon: Icons.arrow_forward_rounded,
                        label: 'Vectors',
                        value: _showVectors,
                        activeColor: Colors.greenAccent,
                        onChanged: (v) => setState(() => _showVectors = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SimPrimaryButton(
                    label: _isPaused ? 'Resume' : 'Pause',
                    icon: _isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    onPressed: _togglePause,
                    color: _isPaused ? AppColors.green : _orbitAccent,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.speed_rounded,
                          label: 'Orbital Speed',
                          value: '${_orbitalSpeed.toStringAsFixed(2)} u/s',
                          color: _orbitAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.loop_rounded,
                          label: 'Period',
                          value: '${_period.toStringAsFixed(1)} s',
                          color: AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.compress_rounded,
                          label: 'Gravity',
                          value: '${_gravityForce.toStringAsFixed(2)} N',
                          color: const Color(0xFFFF8A65),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SimFormulaBar(
                      "Kepler's 3rd: T² ∝ r³   •   F = GMm/r²"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Star {
  final double x, y, size;
  _Star({required this.x, required this.y, required this.size});
}

// ── Painter (unchanged logic) ─────────────────────────────
class OrbitPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress, mass, radius;
  final bool moonEnabled, isPaused, showVectors;

  OrbitPainter({
    required this.stars,
    required this.progress,
    required this.mass,
    required this.radius,
    required this.moonEnabled,
    required this.isPaused,
    required this.showVectors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final minD = math.min(size.width, size.height);
    final orbitR = radius * minD / 260;

    for (final s in stars) {
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size,
          Paint()..color = Colors.white.withOpacity(0.4 + s.size * 0.1));
    }

    canvas.drawCircle(Offset(cx, cy), orbitR,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);

    final sunR = 14.0 + mass * 2;
    for (int i = 3; i >= 0; i--) {
      canvas.drawCircle(Offset(cx, cy), sunR + i * 6.0,
          Paint()..color = Colors.orangeAccent.withOpacity(0.07 * (4 - i)));
    }
    final sGrad = RadialGradient(colors: [
      Colors.white,
      Colors.amber,
      Colors.orange.withOpacity(0.5),
      Colors.transparent
    ], stops: const [0.0, 0.25, 0.55, 1.0]);
    canvas.drawCircle(Offset(cx, cy), sunR,
        Paint()
          ..shader = sGrad
              .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: sunR)));

    final sTP = TextPainter(
        text: TextSpan(
            text: 'M=${mass.toStringAsFixed(0)}',
            style: TextStyle(
                color: Colors.amber.withOpacity(0.65), fontSize: 10)),
        textDirection: TextDirection.ltr)
      ..layout();
    sTP.paint(canvas, Offset(cx - sTP.width / 2, cy + sunR + 5));

    final ang = progress * 2 * math.pi * math.sqrt(mass / radius) * 0.5;
    final px = cx + orbitR * math.cos(ang);
    final py = cy + orbitR * math.sin(ang);
    final pPos = Offset(px, py);

    canvas.drawLine(Offset(cx, cy), pPos,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round);

    for (int i = 0; i < 28; i++) {
      final ta = ang - i * 0.032;
      canvas.drawCircle(
          Offset(cx + orbitR * math.cos(ta), cy + orbitR * math.sin(ta)),
          2.0,
          Paint()..color = Colors.lightBlue.withOpacity((1 - i / 28) * 0.5));
    }

    final pR = 11.0 + mass * 1.2;
    final pGrad = RadialGradient(
        colors: [Colors.lightBlue.shade300, const Color(0xFF1565C0)]);
    canvas.drawCircle(pPos, pR,
        Paint()
          ..shader = pGrad
              .createShader(Rect.fromCircle(center: pPos, radius: pR)));
    canvas.drawCircle(pPos, pR + 3,
        Paint()
          ..color = Colors.lightBlue.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    if (showVectors) {
      final velAng = ang + math.pi / 2;
      final velLen = math.sqrt(mass / radius) * 16;
      final velEnd = Offset(
          px + velLen * math.cos(velAng), py + velLen * math.sin(velAng));
      canvas.drawLine(pPos, velEnd,
          Paint()
            ..color = Colors.greenAccent
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
      _arrowHead(canvas, velEnd, velAng, Colors.greenAccent);

      final cAng = math.atan2(cy - py, cx - px);
      const cLen = 24.0;
      final cEnd = Offset(px + cLen * math.cos(cAng), py + cLen * math.sin(cAng));
      canvas.drawLine(pPos, cEnd,
          Paint()
            ..color = Colors.orangeAccent
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
      _arrowHead(canvas, cEnd, cAng, Colors.orangeAccent);
    }

    if (moonEnabled) {
      final moonR = pR * 3.5;
      canvas.drawCircle(pPos, moonR,
          Paint()
            ..color = Colors.white.withOpacity(0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6);
      final mAng = ang * 1.7;
      final mPos =
          Offset(px + moonR * math.cos(mAng), py + moonR * math.sin(mAng));
      canvas.drawCircle(mPos, 5, Paint()..color = Colors.grey.shade400);
    }
  }

  void _arrowHead(Canvas canvas, Offset tip, double angle, Color color) {
    const s = 7.0;
    canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - s * math.cos(angle - 0.5),
              tip.dy - s * math.sin(angle - 0.5))
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - s * math.cos(angle + 0.5),
              tip.dy - s * math.sin(angle + 0.5)),
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant OrbitPainter old) =>
      old.progress != progress ||
      old.mass != mass ||
      old.radius != radius ||
      old.moonEnabled != moonEnabled ||
      old.showVectors != showVectors;
}