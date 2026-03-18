import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'sim_widgets.dart';

class ElectricCircuitsScreen extends ConsumerStatefulWidget {
  const ElectricCircuitsScreen({super.key});
  @override
  ConsumerState<ElectricCircuitsScreen> createState() =>
      _ElectricCircuitsScreenState();
}

class _ElectricCircuitsScreenState extends ConsumerState<ElectricCircuitsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _voltage = 12;
  double _r1 = 100;
  double _r2 = 150;
  bool _series = true;

  static const _circuitAccent = Color(0xFFE24B4A);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _totalResistance =>
      _series ? _r1 + _r2 : 1 / (1 / _r1 + 1 / _r2);
  double get _current => _voltage / _totalResistance;
  double get _power => _voltage * _current;
  double get _v1 => _series ? _current * _r1 : _voltage;
  double get _v2 => _series ? _current * _r2 : _voltage;

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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Electric Circuits',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
            tooltip: 'Explain this topic',
            onPressed: () => _showAiExplanation(context, 'electric-circuits'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'V = IR   •   P = VI',
                style: TextStyle(
                  color: _circuitAccent.withOpacity(0.6),
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
              accentColor: _circuitAccent,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: CircuitPainter(
                    voltage: _voltage,
                    r1: _r1,
                    r2: _r2,
                    series: _series,
                    current: _current,
                    v1: _v1,
                    v2: _v2,
                    animProgress: _controller.value,
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
                    label: 'Voltage (V)',
                    value: _voltage,
                    unit: ' V',
                    min: 1,
                    max: 24,
                    decimals: 0,
                    accentColor: _circuitAccent,
                    onChanged: (v) => setState(() => _voltage = v),
                  ),
                  SimSliderRow(
                    label: 'Resistor 1 (R1)',
                    value: _r1,
                    unit: ' Ω',
                    min: 10,
                    max: 300,
                    decimals: 0,
                    accentColor: _circuitAccent,
                    onChanged: (v) => setState(() => _r1 = v),
                  ),
                  SimSliderRow(
                    label: 'Resistor 2 (R2)',
                    value: _r2,
                    unit: ' Ω',
                    min: 10,
                    max: 300,
                    decimals: 0,
                    accentColor: _circuitAccent,
                    onChanged: (v) => setState(() => _r2 = v),
                  ),
                  const SizedBox(height: 8),
                  // Series / Parallel segmented toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDeep,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _buildToggleTab('Series', _series,
                            () => setState(() => _series = true)),
                        _buildToggleTab('Parallel', !_series,
                            () => setState(() => _series = false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stats grid
                  Row(
                    children: [
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.electric_bolt_rounded,
                          label: 'Current (I)',
                          value: '${_current.toStringAsFixed(3)} A',
                          color: _circuitAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.memory_rounded,
                          label: 'Total R',
                          value:
                              '${_totalResistance.toStringAsFixed(1)} Ω',
                          color: AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.bolt_rounded,
                          label: 'Power',
                          value: '${_power.toStringAsFixed(2)} W',
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.looks_one_rounded,
                          label: 'V across R1',
                          value: '${_v1.toStringAsFixed(2)} V',
                          color: AppColors.blueLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.looks_two_rounded,
                          label: 'V across R2',
                          value: '${_v2.toStringAsFixed(2)} V',
                          color: AppColors.blueLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.account_tree_rounded,
                          label: 'Type',
                          value: _series ? 'Series' : 'Parallel',
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SimFormulaBar(
                    _series
                        ? 'Series: R_total = R1 + R2   •   V = IR'
                        : 'Parallel: 1/R = 1/R1 + 1/R2   •   V = IR',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(
      String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _circuitAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontWeight:
                  active ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painters (unchanged logic) ────────────────────────────
class CircuitPainter extends CustomPainter {
  final double voltage, r1, r2, current, v1, v2, animProgress;
  final bool series;

  CircuitPainter({
    required this.voltage,
    required this.r1,
    required this.r2,
    required this.series,
    required this.current,
    required this.v1,
    required this.v2,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bw = size.width * 0.72;
    final bh = size.height * 0.55;
    final x1 = cx - bw / 2;
    final x2 = cx + bw / 2;
    final y1 = cy - bh / 2;
    final y2 = cy + bh / 2;

    final wirePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (series) {
      _drawSeriesCircuit(canvas, size, x1, x2, y1, y2, wirePaint);
    } else {
      _drawParallelCircuit(canvas, size, x1, x2, y1, y2, wirePaint);
    }
  }

  void _drawSeriesCircuit(Canvas canvas, Size size, double x1, double x2,
      double y1, double y2, Paint wirePaint) {
    canvas.drawLine(Offset(x1, y1), Offset(x2, y1), wirePaint);
    canvas.drawLine(Offset(x2, y1), Offset(x2, y2), wirePaint);
    canvas.drawLine(Offset(x2, y2), Offset(x1, y2), wirePaint);
    canvas.drawLine(Offset(x1, y2), Offset(x1, y1), wirePaint);

    _drawBattery(canvas, Offset(x1, (y1 + y2) / 2), voltage);

    final r1x = x1 + (x2 - x1) * 0.3;
    _drawResistor(canvas, Offset(r1x, y1), 'R1', r1, v1, current);

    final r2x = x1 + (x2 - x1) * 0.7;
    _drawResistor(canvas, Offset(r2x, y1), 'R2', r2, v2, current);

    _drawCurrentDots(canvas, [
      Offset(x1, y1), Offset(x2, y1),
      Offset(x2, y2), Offset(x1, y2),
    ], animProgress, current);
  }

  void _drawParallelCircuit(Canvas canvas, Size size, double x1, double x2,
      double y1, double y2, Paint wirePaint) {
    final midY = (y1 + y2) / 2;
    final r1y = y1 + (y2 - y1) * 0.3;
    final r2y = y1 + (y2 - y1) * 0.7;

    canvas.drawLine(Offset(x1, y1), Offset(x2, y1), wirePaint);
    canvas.drawLine(Offset(x1, y2), Offset(x2, y2), wirePaint);
    canvas.drawLine(Offset(x1, y1), Offset(x1, y2), wirePaint);
    canvas.drawLine(Offset(x2, y1), Offset(x2, y2), wirePaint);

    canvas.drawLine(Offset(x2, y1), Offset(x2, r1y - 18), wirePaint);
    canvas.drawLine(Offset(x2, r1y + 18), Offset(x2, midY - 5), wirePaint);
    canvas.drawLine(Offset(x2, midY + 5), Offset(x2, r2y - 18), wirePaint);
    canvas.drawLine(Offset(x2, r2y + 18), Offset(x2, y2), wirePaint);

    _drawBattery(canvas, Offset(x1, midY), voltage);
    _drawResistor(canvas, Offset(x2, r1y), 'R1', r1, v1, current / 2);
    _drawResistor(canvas, Offset(x2, r2y), 'R2', r2, v2, current / 2);

    _drawCurrentDots(canvas, [
      Offset(x1, y1), Offset(x2, y1),
      Offset(x2, y2), Offset(x1, y2),
    ], animProgress, current);
  }

  void _drawBattery(Canvas canvas, Offset center, double volt) {
    const w = 22.0, h = 48.0;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: w + 8, height: h + 12),
            const Radius.circular(6)),
        Paint()..color = const Color(0xFF1A2A1A));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: w + 8, height: h + 12),
            const Radius.circular(6)),
        Paint()
          ..color = Colors.greenAccent.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
        text: '+',
        style: TextStyle(
            color: Colors.greenAccent.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - h / 2 - 2));

    tp.text = TextSpan(
        text: '–',
        style: TextStyle(
            color: Colors.redAccent.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + h / 2 - 14));

    tp.text = TextSpan(
        text: '${volt.toStringAsFixed(0)}V',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawResistor(Canvas canvas, Offset center, String label,
      double resistance, double voltDrop, double curr) {
    const w = 52.0, h = 22.0;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: w, height: h),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFF2A1A0A));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: w, height: h),
            const Radius.circular(4)),
        Paint()
          ..color = Colors.amber.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    final zPaint = Paint()
      ..color = Colors.amber.withOpacity(0.5)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final zPath = Path();
    final zx = center.dx - 18.0;
    final zy = center.dy;
    zPath.moveTo(zx, zy);
    for (int i = 0; i < 6; i++) {
      zPath.lineTo(zx + i * 6 + 3, zy + (i % 2 == 0 ? -5 : 5));
    }
    zPath.lineTo(zx + 36, zy);
    canvas.drawPath(zPath, zPaint);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
        text: label,
        style: const TextStyle(
            color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - h / 2 - 14));

    tp.text = TextSpan(
        text: '${resistance.toStringAsFixed(0)}Ω',
        style: TextStyle(
            color: Colors.white.withOpacity(0.55), fontSize: 9));
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + h / 2 + 4));

    tp.text = TextSpan(
        text: '${voltDrop.toStringAsFixed(1)}V',
        style: TextStyle(color: Colors.tealAccent.withOpacity(0.7), fontSize: 9));
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + h / 2 + 14));
  }

  void _drawCurrentDots(Canvas canvas, List<Offset> corners,
      double progress, double current) {
    if (corners.length < 4) return;
    final speed = (current * 0.4).clamp(0.05, 1.0);
    final dotCount = (current * 3).clamp(2, 8).toInt();

    final segments = <_Segment>[];
    for (int i = 0; i < corners.length; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % corners.length];
      segments.add(_Segment(a, b));
    }
    final totalLen = segments.fold(0.0, (s, seg) => s + seg.length);

    for (int d = 0; d < dotCount; d++) {
      final t = ((progress * speed + d / dotCount) % 1.0);
      var dist = t * totalLen;
      for (final seg in segments) {
        if (dist <= seg.length) {
          final pos = seg.start + (seg.end - seg.start) * (dist / seg.length);
          canvas.drawCircle(pos, 3.5,
              Paint()..color = AppColors.blue.withOpacity(0.85));
          break;
        }
        dist -= seg.length;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CircuitPainter old) =>
      old.animProgress != animProgress ||
      old.voltage != voltage ||
      old.r1 != r1 ||
      old.r2 != r2 ||
      old.series != series;
}

class _Segment {
  final Offset start, end;
  _Segment(this.start, this.end);
  double get length => (end - start).distance;
}