import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../widgets/ai_explanation_dialog.dart';
import 'sim_widgets.dart';

class FluidPressureScreen extends ConsumerStatefulWidget {
  const FluidPressureScreen({super.key});
  @override
  ConsumerState<FluidPressureScreen> createState() => _FluidPressureScreenState();
}

class _FluidPressureScreenState extends ConsumerState<FluidPressureScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _objectDensity = 0.6;
  double _fluidDensity = 1.0;
  double _objectSize = 40;
  bool _isDropped = false;

  double _objectY = 0;
  double _velocity = 0;
  double _equilibriumY = 0;
  double _submergedRatio = 0;

  static const double _g = 9.8;
  static const double _fluidLevel = 55.0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..addListener(_updatePhysics);
    _calculateEquilibrium();
  }

  void _calculateEquilibrium() {
    const containerBottom = 260.0;
    if (_objectDensity < _fluidDensity) {
      _equilibriumY =
          _fluidLevel + (_objectSize * (_objectDensity / _fluidDensity)) - _objectSize;
      _submergedRatio = _objectDensity / _fluidDensity;
    } else if ((_objectDensity - _fluidDensity).abs() < 0.05) {
      _equilibriumY = (_fluidLevel + containerBottom) / 2 - _objectSize / 2;
      _submergedRatio = 1.0;
    } else {
      _equilibriumY = containerBottom - _objectSize - 4;
      _submergedRatio = 1.0;
    }
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

  void _updatePhysics() {
    if (!_isDropped) return;
    const dt = 0.016;
    const containerBottom = 260.0;
    final subDepth = math.max(
        0.0, math.min(_objectSize, _objectY + _objectSize - _fluidLevel));
    final curSubRatio = subDepth / _objectSize;
    final buoyancy = (_fluidDensity / _objectDensity) * _g * curSubRatio;
    final net = _g - buoyancy;
    _velocity += net * dt;
    _velocity *= 0.97;
    _objectY += _velocity * 28 * dt;
    if (_objectY >= _equilibriumY && _velocity > 0) {
      _objectY = _equilibriumY;
      _velocity *= -0.15;
    }
    if (_objectY + _objectSize > containerBottom - 4 && _velocity > 0) {
      _objectY = containerBottom - _objectSize - 4;
      _velocity = 0;
    }
    _submergedRatio =
        math.max(0, math.min(1, subDepth / _objectSize));
    if (mounted) setState(() {});
  }

  void _dropObject() {
    setState(() {
      _isDropped = true;
      _objectY = 0;
      _velocity = 0;
      _submergedRatio = 0;
    });
    _calculateEquilibrium();
    _controller.reset();
    _controller.forward();
  }

  void _reset() {
    _controller.stop();
    setState(() {
      _isDropped = false;
      _objectY = 0;
      _velocity = 0;
      _submergedRatio = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _status {
    if (_objectDensity < _fluidDensity) return 'Floating';
    if ((_objectDensity - _fluidDensity).abs() < 0.05) return 'Neutral';
    return 'Sinking';
  }

  IconData get _statusIcon {
    if (_objectDensity < _fluidDensity) return Icons.arrow_upward_rounded;
    if ((_objectDensity - _fluidDensity).abs() < 0.05) return Icons.remove;
    return Icons.arrow_downward_rounded;
  }

  Color get _statusColor {
    if (_objectDensity < _fluidDensity) return AppColors.green;
    if ((_objectDensity - _fluidDensity).abs() < 0.05) return AppColors.blue;
    return AppColors.red;
  }

  double get _buoyancyForce =>
      _submergedRatio *
      _fluidDensity *
      _g *
      (_objectSize * _objectSize * _objectSize / 1e5);

  double get _densityRatio => _objectDensity / _fluidDensity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Fluid Pressure & Buoyancy',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
            tooltip: 'Explain this topic',
            onPressed: () => _showAiExplanation(context, 'fluid-pressure'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'F_b = ρ_fluid · V_sub · g',
                style: TextStyle(
                  color: AppColors.blue.withOpacity(0.6),
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
              accentColor: AppColors.blue,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: FluidPainter(
                    objectY: _objectY,
                    objectDensity: _objectDensity,
                    fluidDensity: _fluidDensity,
                    objectSize: _objectSize,
                    isDropped: _isDropped,
                    submergedRatio: _submergedRatio,
                    time: _controller.value,
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
                    label: 'Object Density (ρ_obj)',
                    value: _objectDensity,
                    unit: ' g/cm³',
                    min: 0.1,
                    max: 2.0,
                    decimals: 2,
                    accentColor: AppColors.blue,
                    onChanged: (v) => setState(() {
                      _objectDensity = v;
                      _calculateEquilibrium();
                    }),
                  ),
                  SimSliderRow(
                    label: 'Fluid Density (ρ_fluid)',
                    value: _fluidDensity,
                    unit: ' g/cm³',
                    min: 0.5,
                    max: 2.5,
                    decimals: 1,
                    accentColor: AppColors.blue,
                    onChanged: (v) => setState(() {
                      _fluidDensity = v;
                      _calculateEquilibrium();
                    }),
                  ),
                  SimSliderRow(
                    label: 'Object Size',
                    value: _objectSize,
                    unit: ' px',
                    min: 20,
                    max: 70,
                    decimals: 0,
                    accentColor: AppColors.blue,
                    onChanged: (v) => setState(() {
                      _objectSize = v;
                      _calculateEquilibrium();
                    }),
                  ),
                  const SizedBox(height: 8),
                  // Density ratio + status row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDeep,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text('ρ_obj / ρ_fluid',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        const Text(' = ',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 12)),
                        Text(
                          _densityRatio.toStringAsFixed(2),
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        SimStatusPill(
                          label: _status,
                          icon: _statusIcon,
                          color: _statusColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SimPrimaryButton(
                          label: 'Drop Object',
                          icon: Icons.arrow_downward_rounded,
                          onPressed: _isDropped ? null : _dropObject,
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
                          icon: Icons.water_drop_rounded,
                          label: 'Buoyancy',
                          value: '${_buoyancyForce.toStringAsFixed(3)} N',
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.percent_rounded,
                          label: 'Submerged',
                          value:
                              '${(_submergedRatio * 100).toStringAsFixed(0)}%',
                          color: AppColors.blue,
                          progress: _submergedRatio,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.straighten_rounded,
                          label: 'Obj Size',
                          value: '${_objectSize.toStringAsFixed(0)} px',
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SimFormulaBar(
                      'F_b = ρ_fluid · V_sub · g  (Archimedes\' Principle)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter (unchanged logic) ─────────────────────────────
class FluidPainter extends CustomPainter {
  final double objectY, objectDensity, fluidDensity, objectSize, submergedRatio, time;
  final bool isDropped;

  FluidPainter({
    required this.objectY,
    required this.objectDensity,
    required this.fluidDensity,
    required this.objectSize,
    required this.isDropped,
    required this.submergedRatio,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cL = size.width * 0.18;
    final cR = size.width * 0.82;
    const cT = 28.0;
    final cB = size.height - 36;
    const fluidLevel = 55.0;

    for (int i = 0; i < 3; i++) {
      final py = fluidLevel + (cB - fluidLevel) * (0.3 + i * 0.3);
      canvas.drawLine(Offset(cL + 8, py), Offset(cR - 8, py),
          Paint()
            ..color = Colors.white.withOpacity(0.03 + i * 0.03)
            ..strokeWidth = 4.0 + i * 2.5);
      final tp = TextPainter(
          text: TextSpan(
              text: 'P${i + 1}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 10)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(cR - 26, py - 7));
    }

    final flGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1565C0).withOpacity(0.28),
        const Color(0xFF0D47A1).withOpacity(0.52),
      ],
    ).createShader(Rect.fromLTRB(cL, fluidLevel, cR, cB));
    canvas.drawRect(Rect.fromLTRB(cL + 1.5, fluidLevel, cR - 1.5, cB - 1.5),
        Paint()..shader = flGrad);

    final wPath = Path();
    for (double x = cL; x <= cR; x += 2) {
      final wy = fluidLevel + 4 * math.sin((x + time * 400) * 0.06);
      x == cL ? wPath.moveTo(x, wy) : wPath.lineTo(x, wy);
    }
    canvas.drawPath(
        wPath,
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);

    canvas.drawRect(Rect.fromLTRB(cL, cT, cR, cB),
        Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);

    final dTP = TextPainter(
        text: TextSpan(
            text: 'Fluid: ρ = ${fluidDensity.toStringAsFixed(1)} g/cm³',
            style: TextStyle(
                color: AppColors.blue.withOpacity(0.7), fontSize: 11)),
        textDirection: TextDirection.ltr)
      ..layout();
    dTP.paint(canvas, Offset(cL + 8, fluidLevel - 18));

    final ow = objectSize * 1.5;
    final ox = (cL + cR) / 2 - ow / 2;
    final oy = cT + objectY;

    Color objColor;
    if (objectDensity < fluidDensity) {
      objColor = AppColors.purple;
    } else if ((objectDensity - fluidDensity).abs() < 0.05) {
      objColor = AppColors.green;
    } else {
      objColor = AppColors.red;
    }

    final objRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(ox, oy, ow, objectSize), const Radius.circular(8));
    canvas.drawRRect(objRect, Paint()..color = objColor.withOpacity(0.82));
    canvas.drawRRect(
        objRect,
        Paint()
          ..color = Colors.white.withOpacity(0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    final lTP = TextPainter(
        text: TextSpan(
            text: 'ρ=${objectDensity.toStringAsFixed(1)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout();
    lTP.paint(canvas,
        Offset(ox + (ow - lTP.width) / 2, oy + (objectSize - lTP.height) / 2));

    if (isDropped && submergedRatio > 0.05) {
      final bLen = submergedRatio * 55;
      final ax = ox + ow / 2;
      final ay = oy;
      canvas.drawLine(Offset(ax, ay), Offset(ax, ay - bLen),
          Paint()
            ..color = AppColors.green
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round);
      _arrowHead(canvas, Offset(ax, ay - bLen), -math.pi / 2, AppColors.green);
      final fbTP = TextPainter(
          text: const TextSpan(
              text: 'F_b',
              style: TextStyle(
                  color: AppColors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr)
        ..layout();
      fbTP.paint(canvas, Offset(ax + 6, ay - bLen / 2 - fbTP.height / 2));
    }

    final wax = ox + ow / 2;
    final way = oy + objectSize;
    canvas.drawLine(Offset(wax, way), Offset(wax, way + 42),
        Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
    _arrowHead(canvas, Offset(wax, way + 42), math.pi / 2, Colors.redAccent);
    final mgTP = TextPainter(
        text: const TextSpan(
            text: 'mg',
            style: TextStyle(
                color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout();
    mgTP.paint(canvas, Offset(wax + 6, way + 20 - mgTP.height / 2));
  }

  void _arrowHead(Canvas canvas, Offset tip, double angle, Color color) {
    const s = 8.0;
    canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - s * math.cos(angle - math.pi / 6),
              tip.dy - s * math.sin(angle - math.pi / 6))
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - s * math.cos(angle + math.pi / 6),
              tip.dy - s * math.sin(angle + math.pi / 6)),
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant FluidPainter old) =>
      old.objectY != objectY ||
      old.objectDensity != objectDensity ||
      old.fluidDensity != fluidDensity ||
      old.objectSize != objectSize ||
      old.isDropped != isDropped ||
      old.time != time;
}