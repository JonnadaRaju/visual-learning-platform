import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sim_widgets.dart';
import '../services/api_service.dart';
import '../widgets/ai_explanation_dialog.dart';

class ProjectileMotionScreen extends ConsumerStatefulWidget {
  const ProjectileMotionScreen({super.key});
  @override
  ConsumerState<ProjectileMotionScreen> createState() =>
      _ProjectileMotionScreenState();
}

class _ProjectileMotionScreenState extends ConsumerState<ProjectileMotionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _angle = 45;
  double _velocity = 30;
  double _gravity = 9.8;
  bool _isAnimating = false;

  List<Map<String, double>> _trajectory = [];
  double _animationProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _controller.addListener(
        () => setState(() => _animationProgress = _controller.value));
    _controller.addStatusListener((s) {
      if (s == AnimationStatus.completed)
        setState(() => _isAnimating = false);
    });
    _computeTrajectory();
  }

  void _computeTrajectory() {
    final r = _angle * math.pi / 180;
    final vx = _velocity * math.cos(r);
    final vy = _velocity * math.sin(r);
    _trajectory = [];
    double t = 0;
    while (true) {
      final x = vx * t;
      final y = vy * t - 0.5 * _gravity * t * t;
      if (t > 0 && y < 0) break;
      _trajectory.add({'x': x, 'y': y > 0 ? y : 0, 't': t});
      t += 0.05;
      if (t > 30) break;
    }
  }

  double get _maxHeight {
    final vy = _velocity * math.sin(_angle * math.pi / 180);
    return vy * vy / (2 * _gravity);
  }

  double get _range {
    final r = _angle * math.pi / 180;
    return (_velocity * _velocity * math.sin(2 * r)) / _gravity;
  }

  double get _timeOfFlight =>
      2 * _velocity * math.sin(_angle * math.pi / 180) / _gravity;

  void _launch() {
    _animationProgress = 0;
    _controller.reset();
    _controller.forward();
    setState(() => _isAnimating = true);
    // Save run to backend (Redis + PostgreSQL)
    ref.read(apiServiceProvider).saveGenericRun(
      slug: 'projectile-motion',
      inputParams: {
        'angle': _angle,
        'initial_velocity': _velocity,
        'gravity': _gravity,
        'initial_height': 0.0,
      },
      resultPayload: {
        'max_height': double.parse(_maxHeight.toStringAsFixed(4)),
        'range': double.parse(_range.toStringAsFixed(4)),
        'time_of_flight': double.parse(_timeOfFlight.toStringAsFixed(4)),
      },
    );
  }

  void _reset() {
    _controller.reset();
    setState(() {
      _animationProgress = 0;
      _isAnimating = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Projectile Motion',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'y = v₀sinθ·t − ½gt²',
                style: TextStyle(
                  color: AppColors.blue.withOpacity(0.6),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
            tooltip: 'Explain this topic',
            onPressed: () => _showAiExplanation(context, 'projectile-motion'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: SimCanvas(
              accentColor: AppColors.blue,
              child: CustomPaint(
                size: Size.infinite,
                painter: ProjectilePainter(
                  trajectory: _trajectory,
                  progress: _animationProgress,
                  angle: _angle,
                  velocity: _velocity,
                  gravity: _gravity,
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
                    label: 'Launch Angle',
                    value: _angle,
                    unit: '°',
                    min: 5,
                    max: 85,
                    decimals: 0,
                    accentColor: AppColors.blue,
                    onChanged: (v) => setState(() {
                      _angle = v;
                      _computeTrajectory();
                      _reset();
                    }),
                  ),
                  SimSliderRow(
                    label: 'Initial Velocity',
                    value: _velocity,
                    unit: ' m/s',
                    min: 5,
                    max: 60,
                    decimals: 0,
                    accentColor: AppColors.blue,
                    onChanged: (v) => setState(() {
                      _velocity = v;
                      _computeTrajectory();
                      _reset();
                    }),
                  ),
                  SimSliderRow(
                    label: 'Gravity',
                    value: _gravity,
                    unit: ' m/s²',
                    min: 1,
                    max: 25,
                    decimals: 1,
                    accentColor: AppColors.blue,
                    onChanged: (v) => setState(() {
                      _gravity = v;
                      _computeTrajectory();
                      _reset();
                    }),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SimPrimaryButton(
                          label: 'Launch',
                          icon: Icons.play_arrow_rounded,
                          onPressed: _isAnimating ? null : _launch,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SimSecondaryButton(
                          label: 'Reset',
                          icon: Icons.refresh_rounded,
                          onPressed: _reset,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Max Height',
                          value: '${_maxHeight.toStringAsFixed(1)} m',
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Range',
                          value: '${_range.toStringAsFixed(1)} m',
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.timer_outlined,
                          label: 'Flight Time',
                          value: '${_timeOfFlight.toStringAsFixed(2)} s',
                          color: AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SimFormulaBar(
                      'y = v₀sinθ·t − ½gt²   |   x = v₀cosθ·t'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter (unchanged logic, identical to original) ──────
class ProjectilePainter extends CustomPainter {
  final List<Map<String, double>> trajectory;
  final double progress;
  final double angle;
  final double velocity;
  final double gravity;

  ProjectilePainter({
    required this.trajectory,
    required this.progress,
    required this.angle,
    required this.velocity,
    required this.gravity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trajectory.isEmpty) return;
    const pad = 44.0;
    final gW = size.width - pad * 2;
    final gH = size.height - pad * 2;
    final maxX = trajectory.last['x']!;
    final maxY =
        trajectory.map((p) => p['y']!).reduce(math.max);
    final scaleX = maxX > 0 ? gW / maxX : 1.0;
    final scaleY = maxY > 0 ? gH / maxY : 1.0;
    final scale = math.min(scaleX, scaleY) * 0.88;

    Offset tf(double x, double y) =>
        Offset(pad + x * scale, size.height - pad - y * scale);

    final gridP = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 10; i++) {
      canvas.drawLine(Offset(pad, pad + gH / 10 * i),
          Offset(size.width - pad, pad + gH / 10 * i), gridP);
      canvas.drawLine(Offset(pad + gW / 10 * i, pad),
          Offset(pad + gW / 10 * i, size.height - pad), gridP);
    }

    canvas.drawRect(
      Rect.fromLTRB(
          pad, size.height - pad, size.width - pad, size.height - pad + 16),
      Paint()..color = AppColors.green.withOpacity(0.12),
    );

    final axP = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(pad, pad), Offset(pad, size.height - pad), axP);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(size.width - pad, size.height - pad), axP);

    final path = Path();
    for (int i = 0; i < trajectory.length; i++) {
      final pt = tf(trajectory[i]['x']!, trajectory[i]['y']!);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    final dashP = Paint()
      ..color = AppColors.blue.withOpacity(0.35)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 9), dashP);
        d += 18;
      }
    }

    final ci =
        (progress * (trajectory.length - 1)).clamp(0, trajectory.length - 1).toInt();
    final cur = trajectory[ci];
    final ballPos = tf(cur['x']!, cur['y']!);

    for (int i = math.max(0, ci - 12); i < ci; i++) {
      final a = (i - (ci - 12)) / 12.0;
      canvas.drawCircle(
          tf(trajectory[i]['x']!, trajectory[i]['y']!),
          5 * a,
          Paint()..color = AppColors.blueLight.withOpacity(a * 0.35));
    }

    final bGrad = RadialGradient(
        colors: [Colors.lightBlueAccent, const Color(0xFF1565C0)]);
    canvas.drawCircle(ballPos, 12,
        Paint()
          ..shader = bGrad
              .createShader(Rect.fromCircle(center: ballPos, radius: 12)));
    canvas.drawCircle(
        ballPos,
        14,
        Paint()
          ..color = AppColors.blueLight.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    if (progress > 0.01) {
      final ar = angle * math.pi / 180;
      final vyc = -velocity * math.sin(ar) + gravity * (cur['t'] ?? 0);
      final vxc = velocity * math.cos(ar);
      final aAngle = math.atan2(vyc, vxc);
      const aLen = 44.0;
      final aEnd = Offset(ballPos.dx + aLen * math.cos(aAngle),
          ballPos.dy + aLen * math.sin(aAngle));
      final arP = Paint()
        ..color = AppColors.amber
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(ballPos, aEnd, arP);
      canvas.drawPath(
        Path()
          ..moveTo(aEnd.dx, aEnd.dy)
          ..lineTo(aEnd.dx - 10 * math.cos(aAngle - 0.5),
              aEnd.dy - 10 * math.sin(aAngle - 0.5))
          ..moveTo(aEnd.dx, aEnd.dy)
          ..lineTo(aEnd.dx - 10 * math.cos(aAngle + 0.5),
              aEnd.dy - 10 * math.sin(aAngle + 0.5)),
        Paint()
          ..color = AppColors.amber
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    if (trajectory.length > 2) {
      final pIdx = trajectory.indexWhere(
          (p) => p['y'] == trajectory.map((pp) => pp['y']!).reduce(math.max));
      if (pIdx >= 0) {
        final pPos = tf(trajectory[pIdx]['x']!, trajectory[pIdx]['y']!);
        canvas.drawCircle(
            pPos,
            5,
            Paint()
              ..color = AppColors.amberLight.withOpacity(0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        _label(canvas, 'H=${maxY.toStringAsFixed(1)}m',
            Offset(pPos.dx + 8, pPos.dy - 14), AppColors.amberLight.withOpacity(0.7));
      }
    }

    final rPos = tf(maxX, 0);
    _label(canvas, 'R=${maxX.toStringAsFixed(1)}m',
        Offset(rPos.dx - 60, rPos.dy - 18), AppColors.green.withOpacity(0.7));
  }

  void _label(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant ProjectilePainter old) =>
      old.progress != progress ||
      old.angle != angle ||
      old.velocity != velocity ||
      old.gravity != gravity;
}