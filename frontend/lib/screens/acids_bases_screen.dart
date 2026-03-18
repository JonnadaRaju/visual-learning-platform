import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Chemistry: Acids, Bases & pH — interactive pH scale + neutralisation
class AcidsBasesScreen extends StatefulWidget {
  const AcidsBasesScreen({super.key});

  @override
  State<AcidsBasesScreen> createState() => _AcidsBasesScreenState();
}

class _AcidsBasesScreenState extends State<AcidsBasesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _pH = 7.0;
  // Titration mixing
  double _acidVol = 50; // mL
  double _baseVol = 50; // mL
  double _acidConc = 0.1; // mol/L
  double _baseConc = 0.1; // mol/L

  bool _showTitration = false;

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

  // Moles of H+ and OH-
  double get _molesH => _acidConc * _acidVol / 1000;
  double get _molesOH => _baseConc * _baseVol / 1000;
  double get _totalVol => (_acidVol + _baseVol) / 1000;

  double get _mixedPH {
    final excess = _molesH - _molesOH;
    if (excess.abs() < 1e-9) return 7.0;
    if (excess > 0) {
      // excess acid
      final concH = excess / _totalVol;
      return -math.log(concH) / math.ln10;
    } else {
      // excess base
      final concOH = -excess / _totalVol;
      final pOH = -math.log(concOH) / math.ln10;
      return 14 - pOH;
    }
  }

  double get _activePH => _showTitration ? _mixedPH.clamp(0, 14) : _pH;

  Color _pHColor(double ph) {
    if (ph < 2) return const Color(0xFFB71C1C);
    if (ph < 4) return const Color(0xFFE53935);
    if (ph < 6) return const Color(0xFFFFA726);
    if (ph < 7) return const Color(0xFFFFEE58);
    if (ph == 7) return const Color(0xFF66BB6A);
    if (ph < 9) return const Color(0xFF42A5F5);
    if (ph < 11) return const Color(0xFF1565C0);
    return const Color(0xFF4A148C);
  }

  String _pHLabel(double ph) {
    if (ph < 3) return 'Strong Acid';
    if (ph < 6) return 'Weak Acid';
    if (ph < 6.5) return 'Slightly Acidic';
    if (ph <= 7.5) return 'Neutral';
    if (ph < 9) return 'Slightly Basic';
    if (ph < 11) return 'Weak Base';
    return 'Strong Base';
  }

  static const _commonSubstances = [
    ('Battery Acid', 0.5),
    ('Lemon Juice', 2.0),
    ('Vinegar', 3.0),
    ('Tomato', 4.5),
    ('Coffee', 5.0),
    ('Milk', 6.5),
    ('Pure Water', 7.0),
    ('Blood', 7.4),
    ('Baking Soda', 8.3),
    ('Soap', 9.5),
    ('Milk of Magnesia', 10.5),
    ('Bleach', 12.5),
    ('Drain Cleaner', 14.0),
  ];

  @override
  Widget build(BuildContext context) {
    final ph = _activePH;
    final phColor = _pHColor(ph);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        title: const Text('Acids, Bases & pH'),
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
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
                    painter: _PHPainter(
                      pH: ph,
                      phColor: phColor,
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
                // Mode toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12121A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _modeTab(false, '⚗ pH Scale'),
                      _modeTab(true, '🔬 Titration'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_showTitration) ...[
                  _buildSlider('pH Value', _pH, 0, 14, '', (v) => setState(() => _pH = v)),
                  // Quick pick substances
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _commonSubstances.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _pH = s.$2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (_pH - s.$2).abs() < 0.3
                                  ? _pHColor(s.$2).withValues(alpha: 0.35)
                                  : const Color(0xFF12121A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _pHColor(s.$2).withValues(alpha: 0.4)),
                            ),
                            child: Text(s.$1,
                                style: TextStyle(
                                    color: _pHColor(s.$2),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ] else ...[
                  _buildSlider('Acid Volume (mL)', _acidVol, 10, 100, ' mL',
                      (v) => setState(() => _acidVol = v)),
                  _buildSlider('Base Volume (mL)', _baseVol, 10, 100, ' mL',
                      (v) => setState(() => _baseVol = v)),
                  _buildSlider('Acid Conc. (mol/L)', _acidConc, 0.01, 0.5, ' M',
                      (v) => setState(() => _acidConc = v)),
                  _buildSlider('Base Conc. (mol/L)', _baseConc, 0.01, 0.5, ' M',
                      (v) => setState(() => _baseConc = v)),
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
                      _buildStat('pH', ph.toStringAsFixed(2), phColor),
                      _buildStat('H⁺ conc.', '${math.pow(10, -ph).toDouble().toStringAsExponential(1)} M', phColor),
                      _buildStat('Type', _pHLabel(ph), phColor),
                      _buildStat('pOH', (14 - ph).toStringAsFixed(2), Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'pH = −log[H⁺]   •   pH + pOH = 14   •   Neutral: pH = 7',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTab(bool titration, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _showTitration = titration),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: _showTitration == titration
                  ? const Color(0xFFFF8A65)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _showTitration == titration
                        ? Colors.white
                        : Colors.white54,
                    fontSize: 12,
                    fontWeight: _showTitration == titration
                        ? FontWeight.bold
                        : FontWeight.normal)),
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
            Text('${value.toStringAsFixed(2)}$unit',
                style: const TextStyle(
                    color: Color(0xFFFF8A65), fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF8A65),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: const Color(0xFFFF8A65),
            overlayColor: const Color(0xFFFF8A65).withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) => Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      );
}

extension on double {
  String toStringExponential(int fractionDigits) {
    final exp = (-this).floor();
    final mantissa = this == exp.toDouble() ? 1.0 : math.pow(10, this - exp.floor());
    if (this == 0) return '1.0 × 10⁰';
    final value = math.pow(10, -this);
    if (value == 0) return '~0';
    final exponent = (math.log(value) / math.ln10).floor();
    final m = value / math.pow(10, exponent);
    return '${m.toStringAsFixed(fractionDigits)}×10${_superscript(exponent)}';
  }

  String _superscript(int n) {
    const sups = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
    final s = n.abs().toString();
    final chars = s.split('').map((c) => sups[int.parse(c)]).join();
    return n < 0 ? '⁻$chars' : chars;
  }
}

class _PHPainter extends CustomPainter {
  final double pH;
  final Color phColor;
  final double pulse;

  _PHPainter({required this.pH, required this.phColor, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const barH = 32.0;
    const barPad = 40.0;
    final barW = size.width - barPad * 2;
    final barY = size.height * 0.25;

    // --- pH Rainbow bar ---
    final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barPad, barY, barW, barH), const Radius.circular(16));

    // Rainbow gradient 0-14
    final rainbowGrad = const LinearGradient(colors: [
      Color(0xFFB71C1C),
      Color(0xFFE53935),
      Color(0xFFFFA726),
      Color(0xFFFFEE58),
      Color(0xFF66BB6A),
      Color(0xFF42A5F5),
      Color(0xFF1565C0),
      Color(0xFF4A148C),
    ]).createShader(Rect.fromLTWH(barPad, barY, barW, barH));

    canvas.drawRRect(barRect, Paint()..shader = rainbowGrad);
    canvas.drawRRect(barRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // pH tick marks + numbers
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 14; i++) {
      final x = barPad + (i / 14) * barW;
      canvas.drawLine(Offset(x, barY + barH), Offset(x, barY + barH + 6),
          Paint()..color = Colors.white.withValues(alpha: 0.4)..strokeWidth = 1);
      if (i % 2 == 0) {
        tp.text = TextSpan(
            text: '$i',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9));
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, barY + barH + 8));
      }
    }

    // pH cursor
    final cursorX = barPad + (pH / 14) * barW;
    final cursorPulse = 1.0 + pulse * 0.08;
    canvas.drawLine(Offset(cursorX, barY - 10), Offset(cursorX, barY + barH + 10),
        Paint()..color = Colors.white..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(cursorX, barY - 14), 8 * cursorPulse,
        Paint()..color = phColor);
    tp.text = TextSpan(
        text: pH.toStringAsFixed(1),
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, Offset(cursorX - tp.width / 2, barY - 14 - tp.height / 2));

    // Acid / Neutral / Base labels
    tp.text = TextSpan(
        text: '◀ ACID',
        style: TextStyle(color: const Color(0xFFE53935).withValues(alpha: 0.7), fontSize: 10));
    tp.layout(); tp.paint(canvas, Offset(barPad, barY - 22));

    tp.text = TextSpan(
        text: 'BASE ▶',
        style: TextStyle(color: const Color(0xFF1565C0).withValues(alpha: 0.7), fontSize: 10));
    tp.layout(); tp.paint(canvas, Offset(size.width - barPad - tp.width, barY - 22));

    tp.text = TextSpan(
        text: 'NEUTRAL',
        style: TextStyle(color: const Color(0xFF66BB6A).withValues(alpha: 0.7), fontSize: 10));
    tp.layout(); tp.paint(canvas, Offset(cx - tp.width / 2, barY - 22));

    // Large pH display
    final bigPH = pH.toStringAsFixed(1);
    tp.text = TextSpan(
        text: 'pH = $bigPH',
        style: TextStyle(
            color: phColor, fontSize: 42, fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, size.height * 0.52));

    // Common substances scatter on the bar
    const substances = [
      ('Battery Acid', 0.5),
      ('Lemon', 2.0),
      ('Vinegar', 3.0),
      ('Coffee', 5.0),
      ('Water', 7.0),
      ('Blood', 7.4),
      ('Soap', 9.5),
      ('Bleach', 12.5),
    ];
    for (final s in substances) {
      final sx = barPad + (s.$2 / 14) * barW;
      canvas.drawCircle(Offset(sx, barY + barH / 2), 4,
          Paint()..color = Colors.white.withValues(alpha: 0.5));
      if ((pH - s.$2).abs() < 1.5) {
        tp.text = TextSpan(
            text: s.$1,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 9));
        tp.layout();
        tp.paint(canvas, Offset(sx - tp.width / 2, barY + barH + 20));
      }
    }

    // H+ vs OH- molecule count visualisation
    final acidSide = pH < 7;
    final molecules = ((7 - pH).abs() * 4).round().clamp(0, 24);
    final rngM = math.Random(42);
    final zone = Rect.fromLTWH(barPad, size.height * 0.7,
        barW, size.height * 0.22);

    for (int i = 0; i < 24; i++) {
      final mx = zone.left + rngM.nextDouble() * zone.width;
      final my = zone.top + rngM.nextDouble() * zone.height;
      final isActive = i < molecules;
      final label = acidSide ? 'H⁺' : 'OH⁻';
      final color = acidSide ? const Color(0xFFE53935) : const Color(0xFF1565C0);
      canvas.drawCircle(Offset(mx, my),
          isActive ? 8 : 5,
          Paint()
            ..color = (isActive ? color : Colors.white)
                .withValues(alpha: isActive ? 0.6 : 0.1));
      if (isActive) {
        tp.text = TextSpan(
            text: label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 7));
        tp.layout();
        tp.paint(canvas, Offset(mx - tp.width / 2, my - tp.height / 2));
      }
    }

    // Zone label
    tp.text = TextSpan(
        text: acidSide
            ? 'More H⁺ ions (acidic)'
            : pH == 7
                ? 'Equal H⁺ and OH⁻ (neutral)'
                : 'More OH⁻ ions (basic)',
        style: TextStyle(
            color: phColor.withValues(alpha: 0.7), fontSize: 10));
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, zone.top - 14));
  }

  @override
  bool shouldRepaint(covariant _PHPainter old) =>
      old.pH != pH || old.pulse != pulse;
}