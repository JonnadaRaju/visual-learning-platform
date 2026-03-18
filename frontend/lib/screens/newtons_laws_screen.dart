import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'sim_widgets.dart';

class NewtonsLawsScreen extends ConsumerStatefulWidget {
  const NewtonsLawsScreen({super.key});
  @override
  ConsumerState<NewtonsLawsScreen> createState() => _NewtonsLawsScreenState();
}

class _NewtonsLawsScreenState extends ConsumerState<NewtonsLawsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _mass = 3.0;
  double _force = 10.0;
  double _friction = 0.3;
  bool _isRunning = false;

  double _boxX = 0;
  double _velocity = 0;
  double _distance = 0;
  final List<_DataPoint> _history = [];

  static const double _g = 9.8;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..addListener(_updatePhysics);
  }

  double get _netForce => _force - _friction * _mass * _g;
  double get _acceleration => _netForce / _mass;

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

  void _updatePhysics() {
    if (!_isRunning) return;
    const dt = 0.016;
    final a = _acceleration;
    _velocity = math.max(0, _velocity + a * dt);
    _boxX += _velocity * dt * 60;
    _distance += _velocity * dt;
    if (_history.length < 200) _history.add(_DataPoint(v: _velocity, a: a));
    if (mounted) setState(() {});
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _boxX = 0;
      _velocity = 0;
      _distance = 0;
      _history.clear();
    });
    _controller.reset();
    _controller.forward();
  }

  void _reset() {
    _controller.stop();
    setState(() {
      _isRunning = false;
      _boxX = 0;
      _velocity = 0;
      _distance = 0;
      _history.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _acceleration;
    final isStatic = _force < _friction * _mass * _g;
    final lawLabel = isStatic
        ? 'Object stays at rest  (Newton\'s 1st Law)'
        : 'F_net = ma  →  a = ${a.toStringAsFixed(2)} m/s²  (2nd Law)';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Newton's Laws",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
            tooltip: 'Explain this topic',
            onPressed: () => _showAiExplanation(context, 'newtons-laws'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'F = ma   •   f = μN',
                style: TextStyle(
                  color: const Color(0xFFFF7043).withOpacity(0.6),
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
              accentColor: const Color(0xFFFF7043),
              child: CustomPaint(
                size: Size.infinite,
                painter: NewtonPainter(
                  boxX: _boxX,
                  velocity: _velocity,
                  mass: _mass,
                  force: _force,
                  friction: _friction,
                  isRunning: _isRunning,
                  history: List.from(_history),
                  distance: _distance,
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
                    label: 'Mass (m)',
                    value: _mass,
                    unit: ' kg',
                    min: 0.5,
                    max: 10,
                    decimals: 1,
                    accentColor: const Color(0xFFFF7043),
                    onChanged: (v) => setState(() => _mass = v),
                  ),
                  SimSliderRow(
                    label: 'Applied Force (F)',
                    value: _force,
                    unit: ' N',
                    min: 0,
                    max: 50,
                    decimals: 0,
                    accentColor: const Color(0xFFFF7043),
                    onChanged: (v) => setState(() => _force = v),
                  ),
                  SimSliderRow(
                    label: 'Friction Coefficient (μ)',
                    value: _friction,
                    unit: '',
                    min: 0,
                    max: 0.9,
                    decimals: 2,
                    accentColor: const Color(0xFFFF7043),
                    onChanged: (v) => setState(() => _friction = v),
                  ),
                  const SizedBox(height: 8),
                  // Law label banner
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isStatic
                          ? AppColors.surfaceDeep
                          : AppColors.blue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: isStatic
                              ? AppColors.border
                              : AppColors.blue,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      lawLabel,
                      style: TextStyle(
                        color:
                            isStatic ? AppColors.textMuted : AppColors.blueLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // FBD widget
                  const SizedBox(height: 10),
                  _FBDWidget(
                      force: _force,
                      friction: _friction * _mass * _g,
                      netForce: _netForce),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SimPrimaryButton(
                          label: _isRunning ? 'Running…' : 'Apply Force',
                          icon: Icons.play_arrow_rounded,
                          onPressed: _isRunning ? null : _start,
                          color: const Color(0xFFFF7043),
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
                          icon: Icons.bolt_rounded,
                          label: 'Acceleration',
                          value: '${a.toStringAsFixed(2)} m/s²',
                          color: AppColors.amber,
                          progress: (a / 20).clamp(0.0, 1.0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.speed_rounded,
                          label: 'Velocity',
                          value: '${_velocity.toStringAsFixed(2)} m/s',
                          color: AppColors.blueLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimStatTile(
                          icon: Icons.balance_rounded,
                          label: 'Net Force',
                          value: '${_netForce.toStringAsFixed(1)} N',
                          color: const Color(0xFFFF7043),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SimFormulaBar(
                      'F = ma   •   f = μN   •   a = (F − f) / m'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline Free Body Diagram widget ──────────────────────
class _FBDWidget extends StatelessWidget {
  const _FBDWidget(
      {required this.force,
      required this.friction,
      required this.netForce});
  final double force, friction, netForce;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SimSectionLabel('FBD'),
          const Spacer(),
          // Simple FBD using widgets
          SizedBox(
            width: 130,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Block
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.purple),
                  ),
                  child: const Center(
                    child: Text('m',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                // F arrow left
                Positioned(
                  left: 0,
                  top: 22,
                  child: _ArrowLabel('F', AppColors.amber, isLeft: true),
                ),
                // friction right
                Positioned(
                  right: 0,
                  top: 22,
                  child: _ArrowLabel('f', AppColors.red, isLeft: false),
                ),
                // N up
                Positioned(
                  top: 0,
                  left: 55,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_upward_rounded,
                        size: 12, color: AppColors.green),
                    const Text('N',
                        style: TextStyle(
                            color: AppColors.green, fontSize: 9)),
                  ]),
                ),
                // mg down
                Positioned(
                  bottom: 0,
                  left: 55,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('mg',
                        style: TextStyle(
                            color: AppColors.red, fontSize: 9)),
                    const Icon(Icons.arrow_downward_rounded,
                        size: 12, color: AppColors.red),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowLabel extends StatelessWidget {
  const _ArrowLabel(this.label, this.color, {required this.isLeft});
  final String label;
  final Color color;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    final children = [
      if (isLeft)
        Icon(Icons.arrow_forward_rounded, size: 12, color: color),
      Text(label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w600)),
      if (!isLeft)
        Icon(Icons.arrow_back_rounded, size: 12, color: color),
    ];
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

// ── DataPoint ─────────────────────────────────────────────
class _DataPoint {
  final double v, a;
  const _DataPoint({required this.v, required this.a});
}

// ── Painter (unchanged logic) ─────────────────────────────
class NewtonPainter extends CustomPainter {
  final double boxX, velocity, mass, force, friction, distance;
  final bool isRunning;
  final List<_DataPoint> history;

  NewtonPainter({
    required this.boxX,
    required this.velocity,
    required this.mass,
    required this.force,
    required this.friction,
    required this.isRunning,
    required this.history,
    required this.distance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 28.0;
    final floorY = size.height * 0.6;
    final trackW = size.width - pad * 2;

    final gP = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 8; i++) {
      canvas.drawLine(Offset(pad + trackW / 8 * i, pad),
          Offset(pad + trackW / 8 * i, floorY), gP);
    }

    canvas.drawRect(
        Rect.fromLTRB(pad, floorY, size.width - pad, floorY + 10),
        Paint()..color = AppColors.green.withOpacity(0.12));
    canvas.drawLine(Offset(pad, floorY), Offset(size.width - pad, floorY),
        Paint()
          ..color = AppColors.green.withOpacity(0.45)
          ..strokeWidth = 2);
    for (double x = pad; x < size.width - pad; x += 14) {
      canvas.drawLine(Offset(x, floorY), Offset(x - 10, floorY + 8),
          Paint()
            ..color = AppColors.green.withOpacity(0.15)
            ..strokeWidth = 1);
    }

    final boxSize = 40.0 + mass * 4;
    final displayX = pad + (boxX % (trackW - boxSize));

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                displayX + 3, floorY - boxSize + 3, boxSize, boxSize),
            const Radius.circular(6)),
        Paint()..color = Colors.black.withOpacity(0.28));

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(displayX, floorY - boxSize, boxSize, boxSize),
            const Radius.circular(6)),
        Paint()..color = const Color(0xFF1565C0).withOpacity(0.72));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(displayX, floorY - boxSize, boxSize, boxSize),
            const Radius.circular(6)),
        Paint()
          ..color = AppColors.blue.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    final mTP = TextPainter(
        text: TextSpan(
            text: '${mass.toStringAsFixed(0)}kg',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout();
    mTP.paint(canvas,
        Offset(displayX + (boxSize - mTP.width) / 2,
            floorY - boxSize / 2 - mTP.height / 2));

    if (force > 0) {
      final fLen = math.min(force * 2.5, 90.0);
      final arrowY = floorY - boxSize / 2;
      canvas.drawLine(Offset(displayX - fLen, arrowY),
          Offset(displayX - 2, arrowY),
          Paint()
            ..color = AppColors.amber
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
      _arrowHead(canvas, Offset(displayX - 2, arrowY), 0, AppColors.amber);
      final fTP = TextPainter(
          text: TextSpan(
              text: 'F=${force.toStringAsFixed(0)}N',
              style: const TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr)
        ..layout();
      fTP.paint(canvas,
          Offset(displayX - fLen / 2 - fTP.width / 2, arrowY - 16));
    }

    if (isRunning && velocity > 0.1) {
      final frictLen = math.min(friction * mass * 9.8 * 2.5, 70.0);
      final arrowY = floorY - 8;
      canvas.drawLine(
          Offset(displayX + boxSize + frictLen, arrowY),
          Offset(displayX + boxSize + 2, arrowY),
          Paint()
            ..color = Colors.redAccent
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
      _arrowHead(canvas, Offset(displayX + boxSize + 2, arrowY),
          math.pi, Colors.redAccent);
      final fTP = TextPainter(
          text: TextSpan(
              text:
                  'f=${(friction * mass * 9.8).toStringAsFixed(1)}N',
              style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
          textDirection: TextDirection.ltr)
        ..layout();
      fTP.paint(canvas,
          Offset(displayX + boxSize + frictLen / 2 - fTP.width / 2,
              arrowY - 14));
    }

    if (isRunning) {
      const nLen = 28.0;
      final nx = displayX + boxSize / 2;
      canvas.drawLine(Offset(nx, floorY - boxSize),
          Offset(nx, floorY - boxSize - nLen),
          Paint()
            ..color = Colors.white54
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
      _arrowHead(canvas, Offset(nx, floorY - boxSize - nLen),
          -math.pi / 2, Colors.white54);

      const wLen = 22.0;
      final wx = displayX + boxSize * 0.3;
      canvas.drawLine(Offset(wx, floorY), Offset(wx, floorY + wLen),
          Paint()
            ..color = Colors.orange.withOpacity(0.6)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
      _arrowHead(canvas, Offset(wx, floorY + wLen), math.pi / 2,
          Colors.orange.withOpacity(0.6));
    }

    if (history.length > 2) {
      final gx = pad;
      final gy = floorY + 36;
      final gw = (size.width - pad * 2) * 0.48;
      final gh = size.height - floorY - 56;
      if (gh > 10) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(gx, gy, gw, gh), const Radius.circular(6)),
            Paint()..color = Colors.white.withOpacity(0.04));
        final maxV = history
            .map((p) => p.v)
            .reduce(math.max)
            .clamp(0.1, double.infinity);
        final vPath = Path();
        for (int i = 0; i < history.length; i++) {
          final px2 = gx + (i / history.length) * gw;
          final py2 = gy + gh - (history[i].v / maxV) * gh;
          i == 0 ? vPath.moveTo(px2, py2) : vPath.lineTo(px2, py2);
        }
        canvas.drawPath(
            vPath,
            Paint()
              ..color = Colors.greenAccent
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke);
        final lTP = TextPainter(
            text: const TextSpan(
                text: 'v-t',
                style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
            textDirection: TextDirection.ltr)
          ..layout();
        lTP.paint(canvas, Offset(gx + 4, gy + 2));
      }
    }

    final fmTP = TextPainter(
        text: TextSpan(
            text:
                'F_net = ${(force - friction * mass * 9.8).toStringAsFixed(1)}N  →  a = ${((force - friction * mass * 9.8) / mass).toStringAsFixed(2)} m/s²',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 10)),
        textDirection: TextDirection.ltr)
      ..layout();
    fmTP.paint(canvas, Offset(pad, 12));
  }

  void _arrowHead(Canvas canvas, Offset tip, double angle, Color color) {
    const s = 8.0;
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
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant NewtonPainter old) =>
      old.boxX != boxX ||
      old.velocity != velocity ||
      old.mass != mass ||
      old.force != force ||
      old.friction != friction ||
      old.isRunning != isRunning;
}