import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/compute_result.dart';
import '../models/concept.dart';
import '../providers/compute_provider.dart';
import '../widgets/animation_canvas.dart';
import '../widgets/graph_widget.dart';
import '../widgets/result_panel.dart';
import '../widgets/slider_panel.dart';
import '../widgets/ai_explanation_dialog.dart';

class ConceptScreen extends ConsumerStatefulWidget {
  const ConceptScreen({super.key, required this.simulation});
  final SimulationDefinition simulation;

  @override
  ConsumerState<ConceptScreen> createState() => _ConceptScreenState();
}

class _ConceptScreenState extends ConsumerState<ConceptScreen> {
  static const _waveColors = [
    Color(0xFF0F766E),
    Color(0xFFF97316),
    Color(0xFF2563EB),
  ];

  late Map<String, double> _values;
  late List<Map<String, double>> _waveInputs;
  late List<String> _waveTypes;
  late List<_CircuitComponentModel> _components;
  final List<_WireLink> _wireLinks = [];

  ProjectileResult? _projectile;
  WaveResult? _wave;
  WaveSuperpositionResult? _superposition;
  CircuitResult? _circuit;
  bool _loading = false;
  bool _saving = false;
  bool _superMode = false;
  int _waveCount = 2;
  String? _selectedTerminalId;

  @override
  void initState() {
    super.initState();
    _values = {
      for (final p in widget.simulation.parameters) p.paramName: p.defaultValue,
    };
    _waveInputs = List.generate(
      3,
      (_) => {'amplitude': 1.0, 'frequency': 1.0, 'phase': 0.0},
    );
    _waveTypes = ['sine', 'sine', 'sine'];
    _components = [
      _CircuitComponentModel(
          id: 'bat1', type: 'battery', value: 12, x: 100, y: 200),
      _CircuitComponentModel(
          id: 'r1', type: 'resistor', value: 100, x: 300, y: 100),
      _CircuitComponentModel(
          id: 'r2', type: 'resistor', value: 150, x: 300, y: 300),
    ];
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final slug = widget.simulation.slug;
      if (slug == 'projectile-motion') {
        _projectile = await api.runProjectile({
          'angle_deg': _values['angle_deg'] ?? 45,
          'initial_velocity': _values['initial_velocity'] ?? 20,
          'gravity': _values['gravity'] ?? 9.8,
          'initial_height': _values['initial_height'] ?? 0,
        });
      } else if (slug == 'waves-shm') {
        if (_superMode) {
          _superposition = await api.runSuperposition(
            List.generate(
              _waveCount,
              (i) => {
                'amplitude': _waveInputs[i]['amplitude'] ?? 1,
                'frequency': _waveInputs[i]['frequency'] ?? 1,
                'phase': _waveInputs[i]['phase'] ?? 0,
              },
            ),
          );
        } else {
          _wave = await api.runWave({
            'amplitude': _values['amplitude'] ?? 1,
            'frequency': _values['frequency'] ?? 1,
            'phase': _values['phase'] ?? 0,
            'wave_type': _values['wave_type_index']?.toInt() == 1 ? 'cosine' : 'sine',
            'num_points': 300,
          });
        }
      } else if (slug == 'electric-circuits') {
        _circuit = await api.runCircuit([
          for (final c in _components)
            for (final w in _wireLinks.where(
                (w) => w.fromId == c.id || w.toId == c.id))
              {
                'id': c.id,
                'type': c.type,
                'value': c.value,
                'node_a': w.fromId,
                'node_b': w.toId,
              }
        ]);
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.saveRun(widget.simulation.slug);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.bookmark_rounded,
                    color: Color(0xFFEF9F27), size: 16),
                SizedBox(width: 8),
                Text('Experiment saved!',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: const Color(0xFF1A1A24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _explainTopic() async {
    final api = ref.read(apiServiceProvider);
    showLoading(context);
    try {
      final explanation = await api.explainTopic(widget.simulation.slug);
      if (!mounted) return;
      Navigator.pop(context);
      showAiExplanation(context, widget.simulation.slug, explanation);
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
    final sim = widget.simulation;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        title: Text(sim.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFAAAAAA),
            ),
            tooltip: 'Explain this topic',
            onPressed: _explainTopic,
          ),
          IconButton(
            icon: Icon(
              _saving
                  ? Icons.hourglass_top_rounded
                  : Icons.bookmark_border_rounded,
              color: const Color(0xFFAAAAAA),
            ),
            tooltip: 'Save experiment',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.07)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildCanvas(),
              ),
            ),
          ),
          // Controls
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A24),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildControls(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _run,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF378ADD),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.play_arrow_rounded,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text('Run Simulation',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_hasResults()) ...[
                      const SizedBox(height: 12),
                      _buildResults(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasResults() =>
      _projectile != null ||
      _wave != null ||
      _superposition != null ||
      _circuit != null;

  Widget _buildCanvas() {
    final slug = widget.simulation.slug;
    if (slug == 'projectile-motion' && _projectile != null) {
      return AnimationCanvas.projectile(projectilePoints: _projectile!.trajectory);
    }
    if (slug == 'waves-shm') {
      if (_superposition != null) {
        final series = _superposition!.waves.map((w) {
          return GraphSeries(
            label: w.label,
            spots: w.points.map((p) => FlSpot(p.x, p.y)).toList(),
            color: _waveColors[_superposition!.waves.indexOf(w) % _waveColors.length],
          );
        }).toList();
        series.add(GraphSeries(
          label: 'Combined',
          spots: _superposition!.combinedPoints.map((p) => FlSpot(p.x, p.y)).toList(),
          color: Colors.purple,
        ));
        return GraphWidget(title: 'Wave Superposition', series: series);
      }
      if (_wave != null) {
        return GraphWidget(
          title: 'Wave',
          series: [
            GraphSeries(
              label: 'Wave',
              spots: _wave!.points.map((p) => FlSpot(p.x, p.y)).toList(),
              color: _waveColors[0],
            ),
          ],
        );
      }
    }
    if (slug == 'electric-circuits' && _circuit != null) {
      return _CircuitCanvas(
        components: _components,
        wireLinks: _wireLinks,
        circuit: _circuit,
        selectedTerminalId: _selectedTerminalId,
        onTapComponent: (id) => setState(() => _selectedTerminalId =
            _selectedTerminalId == id ? null : id),
        onAddWire: (from, to) {
          setState(() {
            _wireLinks.add(_WireLink(fromId: from, toId: to));
            _selectedTerminalId = null;
          });
        },
      );
    }
    // Default placeholder
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline_rounded,
              color: Colors.white.withOpacity(0.15), size: 56),
          const SizedBox(height: 12),
          Text(
            'Set parameters and tap Run',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final slug = widget.simulation.slug;
    if (slug == 'waves-shm') {
      return _buildWaveControls();
    }
    if (slug == 'electric-circuits') {
      return _buildCircuitControls();
    }
    return _buildGenericControls();
  }

  Widget _buildGenericControls() {
    return Column(
      children: widget.simulation.parameters.map((param) {
        return _StyledSlider(
          label: param.paramLabel,
          value: _values[param.paramName] ?? param.defaultValue,
          min: param.minValue,
          max: param.maxValue,
          unit: param.unit,
          onChanged: (v) => setState(() => _values[param.paramName] = v),
        );
      }).toList(),
    );
  }

  Widget _buildWaveControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ModeChip(
              label: 'Single',
              active: !_superMode,
              onTap: () => setState(() => _superMode = false),
            ),
            const SizedBox(width: 8),
            _ModeChip(
              label: 'Superposition',
              active: _superMode,
              onTap: () => setState(() => _superMode = true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_superMode) ...[
          _StyledSlider(
              label: 'Amplitude',
              value: _values['amplitude'] ?? 1,
              min: 0.1,
              max: 5,
              unit: '',
              onChanged: (v) =>
                  setState(() => _values['amplitude'] = v)),
          _StyledSlider(
              label: 'Frequency (Hz)',
              value: _values['frequency'] ?? 1,
              min: 0.1,
              max: 5,
              unit: ' Hz',
              onChanged: (v) =>
                  setState(() => _values['frequency'] = v)),
          _StyledSlider(
              label: 'Phase (°)',
              value: _values['phase'] ?? 0,
              min: 0,
              max: 360,
              unit: '°',
              onChanged: (v) =>
                  setState(() => _values['phase'] = v)),
        ] else ...[
          for (int i = 0; i < _waveCount; i++)
            _WaveInputRow(
              index: i,
              color: _waveColors[i],
              inputs: _waveInputs[i],
              waveType: _waveTypes[i],
              onChanged: (key, val) =>
                  setState(() => _waveInputs[i][key] = val),
              onTypeChanged: (t) =>
                  setState(() => _waveTypes[i] = t),
            ),
          if (_waveCount < 3)
            TextButton.icon(
              onPressed: () => setState(() => _waveCount++),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add wave'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF378ADD)),
            ),
        ],
      ],
    );
  }

  Widget _buildCircuitControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Components on canvas — tap two to connect with a wire.',
            style: TextStyle(color: Color(0xFF888899), fontSize: 12)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _components.map((c) {
            final selected = _selectedTerminalId == c.id;
            return GestureDetector(
              onTap: () {
                if (_selectedTerminalId != null &&
                    _selectedTerminalId != c.id) {
                  setState(() {
                    _wireLinks.add(_WireLink(
                        fromId: _selectedTerminalId!, toId: c.id));
                    _selectedTerminalId = null;
                  });
                } else {
                  setState(() => _selectedTerminalId =
                      selected ? null : c.id);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE24B4A).withOpacity(0.15)
                      : const Color(0xFF12121A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFE24B4A)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  '${c.type} (${c.value.toStringAsFixed(0)})',
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFFE24B4A)
                        : Colors.white70,
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_wireLinks.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _wireLinks.clear()),
            icon: const Icon(Icons.link_off_rounded, size: 15),
            label: const Text('Clear wires'),
            style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                padding: EdgeInsets.zero),
          ),
        ],
      ],
    );
  }

  Widget _buildResults() {
    if (_projectile != null) {
      return _ResultsPanel(rows: [
        _ResultRow('Max Height',
            '${_projectile!.maxHeight.toStringAsFixed(2)} m',
            Icons.arrow_upward_rounded, const Color(0xFF1D9E75)),
        _ResultRow('Range',
            '${_projectile!.range.toStringAsFixed(2)} m',
            Icons.swap_horiz_rounded, const Color(0xFF378ADD)),
        _ResultRow('Flight Time',
            '${_projectile!.timeOfFlight.toStringAsFixed(2)} s',
            Icons.timer_outlined, const Color(0xFFEF9F27)),
      ]);
    }
    if (_wave != null) {
      return _ResultsPanel(rows: [
        _ResultRow('Period',
            '${_wave!.period.toStringAsFixed(3)} s',
            Icons.repeat_rounded, const Color(0xFF378ADD)),
        _ResultRow('ω',
            '${_wave!.angularFrequency.toStringAsFixed(2)} r/s',
            Icons.rotate_right_rounded, Colors.tealAccent),
      ]);
    }
    if (_circuit != null) {
      return _ResultsPanel(rows: [
        _ResultRow('Total Resistance',
            '${_circuit!.totalResistance?.toStringAsFixed(2) ?? 'N/A'} Ω',
            Icons.memory_rounded, const Color(0xFFEF9F27)),
        _ResultRow('Total Power',
            '${_circuit!.totalPower.toStringAsFixed(2)} W',
            Icons.bolt_rounded, const Color(0xFF1D9E75)),
      ]);
    }
    return const SizedBox.shrink();
  }
}

// ── Styled slider ─────────────────────────────────────────
class _StyledSlider extends StatelessWidget {
  const _StyledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });
  final String label;
  final double value, min, max;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFAAAAAA), fontSize: 12)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF378ADD).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                  color: Color(0xFF378ADD),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF378ADD),
            inactiveTrackColor: Colors.white.withOpacity(0.08),
            thumbColor: const Color(0xFF378ADD),
            overlayColor: const Color(0xFF378ADD).withOpacity(0.12),
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

// ── Mode chip ─────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  const _ModeChip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF378ADD).withOpacity(0.15)
              : const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF378ADD)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: active
                  ? const Color(0xFF378ADD)
                  : const Color(0xFFAAAAAA),
              fontSize: 12,
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}

// ── Wave input row ────────────────────────────────────────
class _WaveInputRow extends StatelessWidget {
  const _WaveInputRow({
    required this.index,
    required this.color,
    required this.inputs,
    required this.waveType,
    required this.onChanged,
    required this.onTypeChanged,
  });
  final int index;
  final Color color;
  final Map<String, double> inputs;
  final String waveType;
  final void Function(String, double) onChanged;
  final void Function(String) onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Wave ${index + 1}',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              _TypeToggle(
                  active: waveType == 'sine',
                  label: 'Sine',
                  onTap: () => onTypeChanged('sine')),
              const SizedBox(width: 6),
              _TypeToggle(
                  active: waveType == 'cosine',
                  label: 'Cosine',
                  onTap: () => onTypeChanged('cosine')),
            ],
          ),
          _MiniSlider(
              label: 'A',
              value: inputs['amplitude'] ?? 1,
              min: 0.1,
              max: 5,
              onChanged: (v) => onChanged('amplitude', v),
              color: color),
          _MiniSlider(
              label: 'f',
              value: inputs['frequency'] ?? 1,
              min: 0.1,
              max: 5,
              onChanged: (v) => onChanged('frequency', v),
              color: color),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle(
      {required this.active, required this.label, required this.onTap});
  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.white38,
                fontSize: 10)),
      ),
    );
  }
}

class _MiniSlider extends StatelessWidget {
  const _MiniSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.color,
  });
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(label,
              style: TextStyle(color: color, fontSize: 11)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
                value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontSize: 10)),
        ),
      ],
    );
  }
}

// ── Results panel ─────────────────────────────────────────
class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.rows});
  final List<_ResultRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: rows
            .map(
              (r) => Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(r.icon, size: 13, color: r.color),
                        const SizedBox(width: 4),
                        Text(r.label,
                            style: const TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.value,
                        style: TextStyle(
                            color: r.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ResultRow {
  const _ResultRow(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
}

// ── Circuit canvas placeholder ────────────────────────────
class _CircuitCanvas extends StatelessWidget {
  const _CircuitCanvas({
    required this.components,
    required this.wireLinks,
    required this.circuit,
    required this.selectedTerminalId,
    required this.onTapComponent,
    required this.onAddWire,
  });
  final List<_CircuitComponentModel> components;
  final List<_WireLink> wireLinks;
  final CircuitResult? circuit;
  final String? selectedTerminalId;
  final void Function(String) onTapComponent;
  final void Function(String, String) onAddWire;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _CircuitCanvasPainter(
        components: components,
        wireLinks: wireLinks,
        circuit: circuit,
        selectedId: selectedTerminalId,
      ),
    );
  }
}

class _CircuitCanvasPainter extends CustomPainter {
  final List<_CircuitComponentModel> components;
  final List<_WireLink> wireLinks;
  final CircuitResult? circuit;
  final String? selectedId;

  _CircuitCanvasPainter({
    required this.components,
    required this.wireLinks,
    required this.circuit,
    required this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw wires
    for (final wire in wireLinks) {
      final from =
          components.firstWhere((c) => c.id == wire.fromId,
              orElse: () => components.first);
      final to =
          components.firstWhere((c) => c.id == wire.toId,
              orElse: () => components.last);
      canvas.drawLine(
        Offset(from.x, from.y),
        Offset(to.x, to.y),
        Paint()
          ..color = const Color(0xFF378ADD).withOpacity(0.6)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Draw components
    for (final comp in components) {
      final isSelected = selectedId == comp.id;
      final color = comp.type == 'battery'
          ? Colors.greenAccent
          : Colors.amber;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(comp.x, comp.y),
              width: 64,
              height: 32),
          const Radius.circular(8),
        ),
        Paint()
          ..color = isSelected
              ? color.withOpacity(0.25)
              : const Color(0xFF1A1A24),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(comp.x, comp.y),
              width: 64,
              height: 32),
          const Radius.circular(8),
        ),
        Paint()
          ..color = isSelected ? color : color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2 : 1.2,
      );

      final tp = TextPainter(
          text: TextSpan(
              text: '${comp.type}\n${comp.value.toStringAsFixed(0)}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 9,
                  height: 1.4)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center)
        ..layout(maxWidth: 60);
      tp.paint(canvas,
          Offset(comp.x - tp.width / 2, comp.y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitCanvasPainter old) => true;
}

// ── Data models ───────────────────────────────────────────
class _CircuitComponentModel {
  final String id, type;
  final double value, x, y;
  const _CircuitComponentModel({
    required this.id,
    required this.type,
    required this.value,
    required this.x,
    required this.y,
  });
}

class _WireLink {
  final String fromId, toId;
  const _WireLink({required this.fromId, required this.toId});
}