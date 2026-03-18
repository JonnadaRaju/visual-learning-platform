import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'sim_widgets.dart';

class WavesScreen extends ConsumerStatefulWidget {
  const WavesScreen({super.key});
  @override
  ConsumerState<WavesScreen> createState() => _WavesScreenState();
}

class _WavesScreenState extends ConsumerState<WavesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _amplitude = 50;
  double _frequency = 1.5;
  double _phase = 0;
  bool _showCosine = true;
  bool _showSuper = true;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  double get _period => 1 / _frequency;
  double get _omega => 2 * math.pi * _frequency;

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
        title: const Text('Waves & SHM',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
            tooltip: 'Explain this topic',
            onPressed: () => _showAiExplanation(context, 'waves-shm'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'y = A · sin(ωt + φ)',
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
                  painter: WavePainter(
                    time: _controller.value,
                    amplitude: _amplitude,
                    frequency: _frequency,
                    phase: _phase,
                    showCosine: _showCosine,
                    showSuper: _showSuper,
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
                    label: 'Amplitude (A)',
                    value: _amplitude,
                    unit: ' px',
                    min: 10,
                    max: 80,
                    decimals: 0,
                    accentColor: AppColors.blue,
                    onChanged: (v) => setState(() => _amplitude = v),
                  ),
                  SimSliderRow(
                    label: 'Frequency (f)',
                    value: _frequency,
                    unit: ' Hz',
                    min: 0.5,
                    max: 3.0,
                    decimals: 1,
                    accentColor: AppColors.blue,
                    onChanged: (v) => setState(() => _frequency = v),
                  ),
                  SimSliderRow(
                    label: 'Phase Shift (φ)',
                    value: _phase,
                    unit: '°',
                    min: 0,
                    max: 360,
                    decimals: 0,
                    accentColor: AppColors.blue,
                    onChanged: (v) => setState(() => _phase = v),
                  ),
                  const SizedBox(height: 8),
                  // Wave chip toggles
                  Row(
                    children: [
                      SimIconToggle(
                        icon: Icons.waves_rounded,
                        label: 'Cosine',
                        value: _showCosine,
                        activeColor: Colors.tealAccent,
                        onChanged: (v) => setState(() => _showCosine = v),
                      ),
                      const SizedBox(width: 8),
                      SimIconToggle(
                        icon: Icons.auto_graph_rounded,
                        label: 'Superposition',
                        value: _showSuper,
                        activeColor: Colors.amber,
                        onChanged: (v) => setState(() => _showSuper = v),
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
                    color:
                        _isPaused ? AppColors.green : AppColors.blue,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.repeat_rounded,
                          label: 'Period',
                          value: '${_period.toStringAsFixed(2)} s',
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.rotate_right_rounded,
                          label: 'ω',
                          value: '${_omega.toStringAsFixed(2)} r/s',
                          color: Colors.tealAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.waves_rounded,
                          label: 'λ',
                          value:
                              '${(300 / _frequency).toStringAsFixed(0)} px',
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.height_rounded,
                          label: 'A',
                          value:
                              '${_amplitude.toStringAsFixed(0)} px',
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SimFormulaBar(
                      'y = A · sin(ωt + φ)   •   Superposition: y₁ + y₂'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter unchanged ─────────────────────────────────────
class WavePainter extends CustomPainter {
  final double time, amplitude, frequency, phase;
  final bool showCosine, showSuper;

  WavePainter({
    required this.time,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.showCosine,
    required this.showSuper,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 40.0;
    final midY = size.height / 2;
    final w = size.width - pad * 2;
    final omega = 2 * math.pi * frequency;
    final phaseRad = phase * math.pi / 180;

    final gP = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(
          Offset(pad, pad + (size.height - pad * 2) / 4 * i),
          Offset(size.width - pad, pad + (size.height - pad * 2) / 4 * i),
          gP);
    }
    for (int i = 0; i <= 8; i++) {
      canvas.drawLine(Offset(pad + w / 8 * i, pad),
          Offset(pad + w / 8 * i, size.height - pad), gP);
    }

    final axP = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(pad, midY), Offset(size.width - pad, midY), axP);
    canvas.drawLine(Offset(pad, pad), Offset(pad, size.height - pad), axP);

    canvas.drawLine(Offset(pad - 6, midY - amplitude),
        Offset(pad + 4, midY - amplitude),
        Paint()
          ..color = AppColors.blue.withOpacity(0.4)
          ..strokeWidth = 1);
    canvas.drawLine(Offset(pad - 6, midY + amplitude),
        Offset(pad + 4, midY + amplitude),
        Paint()
          ..color = AppColors.blue.withOpacity(0.4)
          ..strokeWidth = 1);

    _drawWave(canvas, size, pad, w, midY, (x) {
      return midY -
          amplitude *
              math.sin(omega * (x / w) * 3 + time * omega * 1.5 + phaseRad);
    }, AppColors.blue, 2.2, dashed: false);

    if (showCosine) {
      _drawWave(canvas, size, pad, w, midY, (x) {
        return midY -
            amplitude *
                0.7 *
                math.cos(omega * (x / w) * 3 + time * omega * 1.5);
      }, Colors.tealAccent.withOpacity(0.75), 1.6, dashed: true);
    }

    if (showSuper) {
      _drawWave(canvas, size, pad, w, midY, (x) {
        final y1 = amplitude *
            math.sin(omega * (x / w) * 3 + time * omega * 1.5 + phaseRad);
        final y2 = amplitude *
            0.7 *
            math.cos(omega * (x / w) * 3 + time * omega * 1.5);
        return midY - (y1 + y2) * 0.62;
      }, Colors.amber, 2.5, dashed: false);
    }

    final legendItems = [
      _LegendItem('Sine (y₁)', AppColors.blue, false),
      if (showCosine) _LegendItem('Cosine (y₂)', Colors.tealAccent, true),
      if (showSuper) _LegendItem('Sum (y₁+y₂)', Colors.amber, false),
    ];
    for (int i = 0; i < legendItems.length; i++) {
      final lx = size.width - 120.0, ly = 14.0 + i * 18;
      final item = legendItems[i];
      if (item.dashed) {
        canvas.drawLine(Offset(lx, ly), Offset(lx + 22, ly),
            Paint()
              ..color = item.color
              ..strokeWidth = 1.5
              ..strokeCap = StrokeCap.round);
        canvas.drawLine(Offset(lx + 6, ly), Offset(lx + 14, ly),
            Paint()
              ..color = const Color(0xFF0D0D16)
              ..strokeWidth = 1.5);
      } else {
        canvas.drawLine(Offset(lx, ly), Offset(lx + 22, ly),
            Paint()
              ..color = item.color
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round);
      }
      final tp = TextPainter(
          text: TextSpan(
              text: item.label,
              style: TextStyle(
                  color: item.color.withOpacity(0.85), fontSize: 10)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(lx + 26, ly - tp.height / 2));
    }
  }

  void _drawWave(Canvas canvas, Size size, double pad, double w, double midY,
      double Function(double x) yFn, Color color, double sw,
      {required bool dashed}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (double x = 0; x <= w; x += 1.5) {
      final y = yFn(x);
      x == 0 ? path.moveTo(pad + x, y) : path.lineTo(pad + x, y);
    }
    if (!dashed) {
      canvas.drawPath(path, paint);
    } else {
      for (final m in path.computeMetrics()) {
        double d = 0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, d + 10), paint);
          d += 18;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter old) =>
      old.time != time ||
      old.amplitude != amplitude ||
      old.frequency != frequency ||
      old.phase != phase ||
      old.showCosine != showCosine ||
      old.showSuper != showSuper;
}

class _LegendItem {
  final String label;
  final Color color;
  final bool dashed;
  const _LegendItem(this.label, this.color, this.dashed);
}