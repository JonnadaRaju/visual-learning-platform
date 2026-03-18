import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Chemistry: Atomic Structure — Bohr model interactive visualizer
class AtomicStructureScreen extends ConsumerStatefulWidget {
  const AtomicStructureScreen({super.key});

  @override
  ConsumerState<AtomicStructureScreen> createState() => _AtomicStructureScreenState();
}

class _AtomicStructureScreenState extends ConsumerState<AtomicStructureScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Atomic number 1–18
  int _atomicNumber = 6; // Carbon by default

  static const _elements = <int, _Element>{
    1:  _Element('H',  'Hydrogen',    1, 0, 0, [1]),
    2:  _Element('He', 'Helium',      2, 2, 0, [2]),
    3:  _Element('Li', 'Lithium',     3, 4, 1, [2, 1]),
    4:  _Element('Be', 'Beryllium',   4, 5, 2, [2, 2]),
    5:  _Element('B',  'Boron',       5, 6, 3, [2, 3]),
    6:  _Element('C',  'Carbon',      6, 6, 4, [2, 4]),
    7:  _Element('N',  'Nitrogen',    7, 7, 5, [2, 5]),
    8:  _Element('O',  'Oxygen',      8, 8, 6, [2, 6]),
    9:  _Element('F',  'Fluorine',    9, 10, 7, [2, 7]),
    10: _Element('Ne', 'Neon',        10, 10, 8, [2, 8]),
    11: _Element('Na', 'Sodium',      11, 12, 1, [2, 8, 1]),
    12: _Element('Mg', 'Magnesium',   12, 12, 2, [2, 8, 2]),
    13: _Element('Al', 'Aluminium',   13, 14, 3, [2, 8, 3]),
    14: _Element('Si', 'Silicon',     14, 14, 4, [2, 8, 4]),
    15: _Element('P',  'Phosphorus',  15, 16, 5, [2, 8, 5]),
    16: _Element('S',  'Sulphur',     16, 16, 6, [2, 8, 6]),
    17: _Element('Cl', 'Chlorine',    17, 18, 7, [2, 8, 7]),
    18: _Element('Ar', 'Argon',       18, 22, 8, [2, 8, 8]),
  };

  _Element get _el => _elements[_atomicNumber]!;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    final el = _el;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        title: const Text('Atomic Structure'),
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF9C27B0)),
            tooltip: 'Explain this topic',
            onPressed: () => _showAiExplanation(context, 'atomic-structure'),
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
                color: const Color(0xFF06060E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _AtomPainter(
                      element: el,
                      progress: _controller.value,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Atomic Number (Z)',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Z = $_atomicNumber  —  ${el.name}',
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
                  child: Slider(
                    value: _atomicNumber.toDouble(),
                    min: 1,
                    max: 18,
                    onChanged: (v) => setState(() => _atomicNumber = v.round()),
                  ),
                ),
                // Quick-pick element buttons
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _elements.entries.map((e) {
                      final selected = e.key == _atomicNumber;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _atomicNumber = e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFF8A65)
                                  : const Color(0xFF12121A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFF8A65)
                                      : Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              e.value.symbol,
                              style: TextStyle(
                                  color: selected ? Colors.white : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12121A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Protons', '${el.protons}'),
                      _buildStat('Neutrons', '${el.neutrons}'),
                      _buildStat('Electrons', '${el.protons}'),
                      _buildStat('Valence e⁻', '${el.valenceElectrons}'),
                      _buildStat('Shells', '${el.shells.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Shell config: ${el.shells.join(', ')}   •   Mass ≈ protons + neutrons',
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

class _Element {
  final String symbol, name;
  final int protons, neutrons, valenceElectrons;
  final List<int> shells;
  const _Element(this.symbol, this.name, this.protons, this.neutrons,
      this.valenceElectrons, this.shells);
}

class _AtomPainter extends CustomPainter {
  final _Element element;
  final double progress;

  _AtomPainter({required this.element, required this.progress});

  static const _shellColors = [
    Color(0xFF378ADD),
    Color(0xFF2DD4BF),
    Color(0xFFBA68C8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final baseR = math.min(cx, cy) * 0.18;
    final shellGap = math.min(cx, cy) * 0.22;

    // Stars background
    final rng = math.Random(77);
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          rng.nextDouble() * 1.2 + 0.3,
          Paint()..color = Colors.white.withValues(alpha: 0.25));
    }

    // Nucleus glow
    for (int i = 3; i >= 0; i--) {
      canvas.drawCircle(Offset(cx, cy), baseR + i * 5,
          Paint()..color = const Color(0xFFFF8A65).withValues(alpha: 0.06 * (4 - i)));
    }

    // Nucleus
    final nucGrad = RadialGradient(colors: [
      const Color(0xFFFFCC80),
      const Color(0xFFFF8A65),
      const Color(0xFFBF360C).withValues(alpha: 0.7),
      Colors.transparent,
    ], stops: const [0, 0.3, 0.7, 1.0]);
    canvas.drawCircle(Offset(cx, cy), baseR,
        Paint()..shader = nucGrad.createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: baseR)));

    // Proton / neutron count inside nucleus
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
        text: element.symbol,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    // Electron shells
    for (int s = 0; s < element.shells.length; s++) {
      final r = baseR + shellGap * (s + 1);
      final color = _shellColors[s % _shellColors.length];
      final electronCount = element.shells[s];

      // Shell orbit
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()
            ..color = color.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);

      // Electrons on shell — different speeds per shell
      final speedFactor = 1.0 + s * 0.4;
      for (int e = 0; e < electronCount; e++) {
        final baseAngle = (2 * math.pi / electronCount) * e;
        final angle = baseAngle + progress * 2 * math.pi * speedFactor;
        final ex = cx + r * math.cos(angle);
        final ey = cy + r * math.sin(angle);

        // Electron trail
        for (int t = 1; t <= 5; t++) {
          final ta = angle - t * 0.08;
          canvas.drawCircle(
              Offset(cx + r * math.cos(ta), cy + r * math.sin(ta)),
              2.0,
              Paint()..color = color.withValues(alpha: (1 - t / 6) * 0.3));
        }

        // Electron dot
        canvas.drawCircle(Offset(ex, ey), 5,
            Paint()..color = color);
        canvas.drawCircle(Offset(ex, ey), 5,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }

      // Shell label
      tp.text = TextSpan(
          text: 'n=${s + 1}: ${electronCount}e⁻',
          style: TextStyle(color: color.withValues(alpha: 0.65), fontSize: 9));
      tp.layout();
      tp.paint(canvas, Offset(cx + r + 4, cy - tp.height / 2));
    }

    // Atomic number & mass top-left
    tp.text = TextSpan(
        text: 'Z=${element.protons}   A=${element.protons + element.neutrons}',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10));
    tp.layout();
    tp.paint(canvas, Offset(14, 14));
  }

  @override
  bool shouldRepaint(covariant _AtomPainter old) =>
      old.progress != progress || old.element.protons != element.protons;
}