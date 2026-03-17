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

class ConceptScreen extends ConsumerStatefulWidget {
  const ConceptScreen({super.key, required this.simulation});

  final SimulationDefinition simulation;

  @override
  ConsumerState<ConceptScreen> createState() => _ConceptScreenState();
}

class _ConceptScreenState extends ConsumerState<ConceptScreen> {
  static const _waveColors = [Color(0xFF0F766E), Color(0xFFF97316), Color(0xFF2563EB)];

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
    _values = {for (final p in widget.simulation.parameters) p.paramName: p.defaultValue};
    _waveInputs = List.generate(3, (index) {
      return {
        'amplitude': (_values['amplitude'] ?? 20) - index * 4,
        'frequency': (_values['frequency'] ?? 2) + index * 0.4,
        'phase': (_values['phase'] ?? 0) + index * 0.6,
      };
    });
    _waveTypes = ['sine', 'cosine', 'sine'];
    _components = [
      _CircuitComponentModel(
        id: 'battery-1',
        type: 'battery',
        label: 'Battery',
        value: 12,
        position: const Offset(40, 86),
      ),
      _CircuitComponentModel(
        id: 'resistor-1',
        type: 'resistor',
        label: 'Resistor',
        value: 6,
        position: const Offset(270, 86),
      ),
    ];
  }

  bool get _isProjectile => widget.simulation.slug == 'projectile-motion';
  bool get _isWave => widget.simulation.slug == 'waves-shm';
  bool get _isCircuit => widget.simulation.slug == 'electric-circuits';

  Future<void> _runSimulation() async {
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    try {
      if (_isProjectile) {
        _projectile = await api.runProjectile(_values);
      } else if (_isWave) {
        if (_superMode) {
          final payload = [
            for (var index = 0; index < _waveCount; index++)
              {
                'amplitude': _waveInputs[index]['amplitude'],
                'frequency': _waveInputs[index]['frequency'],
                'phase': _waveInputs[index]['phase'],
                'wave_type': _waveTypes[index],
                'label': 'Wave ${index + 1}',
              },
          ];
          _superposition = await api.runSuperposition(payload);
          _wave = null;
        } else {
          _wave = await api.runWave({
            'amplitude': _waveInputs[0]['amplitude'],
            'frequency': _waveInputs[0]['frequency'],
            'phase': _waveInputs[0]['phase'],
            'wave_type': _waveTypes[0],
          });
          _superposition = null;
        }
      } else if (_isCircuit) {
        _circuit = await api.runCircuit(_buildCircuitPayload());
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveRun() async {
    final runId = _projectile?.runId ?? _wave?.runId ?? _superposition?.runId ?? _circuit?.runId;
    if (runId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(apiServiceProvider).saveRun(runId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiment saved')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.simulation.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.simulation.description, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 18),
          _buildCanvas(),
          const SizedBox(height: 18),
          if (_isProjectile) _buildProjectileControls(),
          if (_isWave) _buildWaveControls(),
          if (_isCircuit) _buildCircuitControls(),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loading ? null : _runSimulation,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(_loading ? 'Running...' : _isCircuit ? 'Simulate circuit' : 'Run simulation'),
          ),
          const SizedBox(height: 18),
          if (_buildResultPanel() case final panel?) panel,
          if (_buildGraph() case final graph?) ...[
            const SizedBox(height: 18),
            graph,
          ],
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    if (_isProjectile) {
      return AnimationCanvas.projectile(projectilePoints: _projectile?.trajectory ?? const []);
    }
    if (_isWave) {
      final series = <AnimatedWaveSeries>[];
      if (_wave != null) {
        series.add(AnimatedWaveSeries(label: 'Wave 1', points: _wave!.points, color: _waveColors[0], highlight: true));
      }
      if (_superposition != null) {
        for (var index = 0; index < _superposition!.waves.length; index++) {
          final wave = _superposition!.waves[index];
          series.add(AnimatedWaveSeries(label: wave.label, points: wave.points, color: _waveColors[index % _waveColors.length]));
        }
        series.add(
          AnimatedWaveSeries(
            label: 'Resultant',
            points: _superposition!.combinedPoints,
            color: const Color(0xFF8B1E3F),
            highlight: true,
          ),
        );
      }
      return AnimationCanvas.waves(waveSeries: series);
    }
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          Positioned.fill(child: AnimationCanvas.circuit(wires: _visualWires())),
          ..._components.map(_buildComponentCard),
        ],
      ),
    );
  }

  Widget _buildProjectileControls() {
    return SliderPanel(
      sections: [
        SliderSectionData(
          title: 'Launch Controls',
          fields: widget.simulation.parameters
              .map(
                (parameter) => SliderFieldData(
                  id: parameter.paramName,
                  label: parameter.paramLabel,
                  unit: parameter.unit,
                  value: _values[parameter.paramName] ?? parameter.defaultValue,
                  min: parameter.minValue,
                  max: parameter.maxValue,
                  step: parameter.stepSize,
                ),
              )
              .toList(),
        ),
      ],
      onChanged: (change) => setState(() => _values[change.$1] = change.$2),
    );
  }

  Widget _buildWaveControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Superposition mode'),
                  subtitle: const Text('Blend up to three waves and compare the resultant motion.'),
                  value: _superMode,
                  onChanged: (value) => setState(() {
                    _superMode = value;
                    _waveCount = value ? math.max(_waveCount, 2) : 1;
                  }),
                ),
                if (_superMode) ...[
                  const SizedBox(height: 10),
                  Text('Number of waves: $_waveCount'),
                  Slider(
                    value: _waveCount.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    onChanged: (value) => setState(() => _waveCount = value.round()),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_superMode ? _waveCount : 1, (index) {
          final fields = widget.simulation.parameters
              .map(
                (parameter) => SliderFieldData(
                  id: parameter.paramName,
                  label: parameter.paramLabel,
                  unit: parameter.unit,
                  value: _waveInputs[index][parameter.paramName] ?? parameter.defaultValue,
                  min: parameter.minValue,
                  max: parameter.maxValue,
                  step: parameter.stepSize,
                  color: _waveColors[index % _waveColors.length],
                ),
              )
              .toList();
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Wave ${index + 1}', style: Theme.of(context).textTheme.titleMedium)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'sine', label: Text('Sine')),
                          ButtonSegment(value: 'cosine', label: Text('Cosine')),
                        ],
                        selected: {_waveTypes[index]},
                        onSelectionChanged: (selection) => setState(() => _waveTypes[index] = selection.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderPanel(
                    sections: [SliderSectionData(title: 'Wave parameters', fields: fields)],
                    onChanged: (change) => setState(() => _waveInputs[index][change.$1] = change.$2),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCircuitControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _addBattery,
                  icon: const Icon(Icons.battery_full_outlined),
                  label: const Text('Add battery'),
                ),
                OutlinedButton.icon(
                  onPressed: _addResistor,
                  icon: const Icon(Icons.linear_scale),
                  label: const Text('Add resistor'),
                ),
                OutlinedButton.icon(
                  onPressed: _wireLinks.isEmpty ? null : () => setState(() => _wireLinks.removeLast()),
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo wire'),
                ),
                if (_selectedTerminalId != null)
                  Text('Connecting: $_selectedTerminalId', style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Drag components to reposition them. Tap a terminal dot on one component, then tap a terminal on another component to connect with a wire.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget? _buildResultPanel() {
    if (_projectile != null) {
      return ResultPanel(
        title: 'Projectile summary',
        subtitle: 'The projectile path is sampled every 0.05 seconds until it reaches the ground.',
        stats: [
          ResultStat(label: 'Max height', value: '${_projectile!.maxHeight.toStringAsFixed(2)} m'),
          ResultStat(label: 'Range', value: '${_projectile!.range.toStringAsFixed(2)} m'),
          ResultStat(label: 'Time of flight', value: '${_projectile!.timeOfFlight.toStringAsFixed(2)} s'),
        ],
        cacheHit: _projectile!.cacheHit,
        onSave: _saveRun,
        isSaving: _saving,
      );
    }
    if (_wave != null) {
      return ResultPanel(
        title: 'Wave summary',
        subtitle: 'Single-wave motion across two periods of travel.',
        stats: [
          ResultStat(label: 'Period', value: '${_wave!.period.toStringAsFixed(2)} s'),
          ResultStat(label: 'Angular frequency', value: '${_wave!.angularFrequency.toStringAsFixed(2)} rad/s'),
        ],
        cacheHit: _wave!.cacheHit,
        onSave: _saveRun,
        isSaving: _saving,
      );
    }
    if (_superposition != null) {
      final first = _superposition!.waves.first;
      return ResultPanel(
        title: 'Superposition summary',
        subtitle: 'Each source wave is shown separately, with the resultant highlighted.',
        stats: [
          ResultStat(label: 'Active waves', value: '${_superposition!.waves.length}'),
          ResultStat(label: 'Reference period', value: '${first.period.toStringAsFixed(2)} s'),
          ResultStat(label: 'Reference angular frequency', value: '${first.angularFrequency.toStringAsFixed(2)} rad/s'),
        ],
        cacheHit: _superposition!.cacheHit,
        onSave: _saveRun,
        isSaving: _saving,
      );
    }
    if (_circuit != null) {
      return ResultPanel(
        title: 'Circuit summary',
        subtitle: 'Node voltages and branch currents come from nodal analysis on the current workbench.',
        stats: [
          ResultStat(label: 'Total resistance', value: _circuit!.totalResistance == null ? 'N/A' : '${_circuit!.totalResistance!.toStringAsFixed(2)} ohm'),
          ResultStat(label: 'Total power', value: '${_circuit!.totalPower.toStringAsFixed(2)} W'),
          ResultStat(label: 'Solved nodes', value: '${_circuit!.nodeVoltages.length}'),
        ],
        cacheHit: _circuit!.cacheHit,
        onSave: _saveRun,
        isSaving: _saving,
      );
    }
    return null;
  }

  Widget? _buildGraph() {
    if (_projectile != null) {
      return GraphWidget(
        title: 'Trajectory graph',
        series: [
          GraphSeries(
            label: 'Projectile arc',
            spots: _projectile!.trajectory.map((point) => FlSpot(point.x, point.y)).toList(),
            color: const Color(0xFF0F766E),
          ),
        ],
      );
    }
    if (_wave != null) {
      return GraphWidget(
        title: 'Wave graph',
        series: [
          GraphSeries(
            label: 'Wave 1',
            spots: _wave!.points.map((point) => FlSpot(point.x, point.y)).toList(),
            color: _waveColors[0],
          ),
        ],
      );
    }
    if (_superposition != null) {
      return GraphWidget(
        title: 'Wave superposition graph',
        series: [
          for (var index = 0; index < _superposition!.waves.length; index++)
            GraphSeries(
              label: _superposition!.waves[index].label,
              spots: _superposition!.waves[index].points.map((point) => FlSpot(point.x, point.y)).toList(),
              color: _waveColors[index % _waveColors.length],
            ),
          GraphSeries(
            label: 'Resultant',
            spots: _superposition!.combinedPoints.map((point) => FlSpot(point.x, point.y)).toList(),
            color: const Color(0xFF8B1E3F),
            width: 4,
          ),
        ],
      );
    }
    if (_circuit != null) {
      return GraphWidget(
        title: 'Branch current graph',
        series: [
          GraphSeries(
            label: 'Branch current',
            spots: [
              for (var index = 0; index < _circuit!.branchCurrents.length; index++)
                FlSpot(index.toDouble(), _circuit!.branchCurrents[index].current)
            ],
            color: const Color(0xFF2563EB),
            curved: false,
          ),
        ],
      );
    }
    return null;
  }

  Widget _buildComponentCard(_CircuitComponentModel component) {
    final current = _circuit?.branchCurrents.where((item) => item.componentId == component.id).firstOrNull?.current;
    final voltageDrop = current == null
        ? (component.type == 'battery' ? component.value : null)
        : component.type == 'battery'
            ? component.value
            : current.abs() * component.value;
    return Positioned(
      left: component.position.dx,
      top: component.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) => setState(() {
          final updated = component.position + details.delta;
          _replaceComponent(component.copyWith(position: Offset(updated.dx.clamp(0, 420), updated.dy.clamp(0, 200))));
        }),
        child: SizedBox(
          width: component.size.width,
          height: component.size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Card(
                color: component.type == 'battery' ? const Color(0xFFFFF6D6) : const Color(0xFFE7F1FF),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(component.label, style: Theme.of(context).textTheme.titleMedium)),
                          IconButton(
                            onPressed: () => setState(() {
                              _components.removeWhere((item) => item.id == component.id);
                              _wireLinks.removeWhere((wire) => wire.startTerminal.startsWith(component.id) || wire.endTerminal.startsWith(component.id));
                            }),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(component.type == 'battery' ? '${component.value.toStringAsFixed(1)} V source' : '${component.value.toStringAsFixed(1)} ohm resistor'),
                      if (current != null) ...[
                        const SizedBox(height: 6),
                        Text('I = ${current.toStringAsFixed(2)} A'),
                      ],
                      if (voltageDrop != null) Text('V = ${voltageDrop.toStringAsFixed(2)} V'),
                    ],
                  ),
                ),
              ),
              _buildTerminal(component, true),
              _buildTerminal(component, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminal(_CircuitComponentModel component, bool isA) {
    final terminalId = isA ? component.terminalA : component.terminalB;
    final selected = terminalId == _selectedTerminalId;
    return Positioned(
      left: isA ? -10 : component.size.width - 10,
      top: component.size.height / 2 - 10,
      child: GestureDetector(
        onTap: () => _handleTerminalTap(terminalId),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF8B1E3F) : const Color(0xFF0F766E),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  void _handleTerminalTap(String terminalId) {
    setState(() {
      if (_selectedTerminalId == null) {
        _selectedTerminalId = terminalId;
        return;
      }
      if (_selectedTerminalId == terminalId) {
        _selectedTerminalId = null;
        return;
      }
      final duplicate = _wireLinks.any(
        (wire) => (wire.startTerminal == _selectedTerminalId && wire.endTerminal == terminalId) || (wire.startTerminal == terminalId && wire.endTerminal == _selectedTerminalId),
      );
      if (!duplicate) {
        _wireLinks.add(_WireLink(id: 'wire-${_wireLinks.length + 1}', startTerminal: _selectedTerminalId!, endTerminal: terminalId));
      }
      _selectedTerminalId = null;
    });
  }

  void _addBattery() {
    final count = _components.where((item) => item.type == 'battery').length + 1;
    setState(() {
      _components.add(
        _CircuitComponentModel(
          id: 'battery-$count',
          type: 'battery',
          label: 'Battery $count',
          value: 9 + count.toDouble(),
          position: Offset(40 + count * 20, 30 + count * 12),
        ),
      );
    });
  }

  void _addResistor() {
    final count = _components.where((item) => item.type == 'resistor').length + 1;
    setState(() {
      _components.add(
        _CircuitComponentModel(
          id: 'resistor-$count',
          type: 'resistor',
          label: 'Resistor $count',
          value: 4 + count.toDouble() * 2,
          position: Offset(240 + count * 18, 40 + count * 20),
        ),
      );
    });
  }

  void _replaceComponent(_CircuitComponentModel updated) {
    final index = _components.indexWhere((item) => item.id == updated.id);
    if (index >= 0) {
      _components[index] = updated;
    }
  }

  List<Map<String, dynamic>> _buildCircuitPayload() {
    return [
      ..._components.map(
        (component) => {
          'id': component.id,
          'type': component.type,
          'value': component.value,
          'node_a': component.terminalA,
          'node_b': component.terminalB,
        },
      ),
      ..._wireLinks.map(
        (wire) => {
          'id': wire.id,
          'type': 'wire',
          'value': 0,
          'node_a': wire.startTerminal,
          'node_b': wire.endTerminal,
        },
      ),
    ];
  }

  List<CircuitVisualWire> _visualWires() {
    final currentById = {
      for (final current in _circuit?.branchCurrents ?? const <BranchCurrent>[]) current.componentId: current.current,
    };
    return _wireLinks
        .map((wire) {
          final startComponent = _components.firstWhere((component) => wire.startTerminal.startsWith(component.id));
          final endComponent = _components.firstWhere((component) => wire.endTerminal.startsWith(component.id));
          final start = wire.startTerminal.endsWith('_a') ? startComponent.leftTerminal : startComponent.rightTerminal;
          final end = wire.endTerminal.endsWith('_a') ? endComponent.leftTerminal : endComponent.rightTerminal;
          final speed = math.max(
            currentById[startComponent.id]?.abs() ?? 0,
            currentById[endComponent.id]?.abs() ?? 0,
          );
          return CircuitVisualWire(id: wire.id, start: start, end: end, speed: speed);
        })
        .toList();
  }
}

class _CircuitComponentModel {
  const _CircuitComponentModel({
    required this.id,
    required this.type,
    required this.label,
    required this.value,
    required this.position,
    this.size = const Size(150, 110),
  });

  final String id;
  final String type;
  final String label;
  final double value;
  final Offset position;
  final Size size;

  String get terminalA => '${id}_a';
  String get terminalB => '${id}_b';
  Offset get leftTerminal => Offset(position.dx, position.dy + size.height / 2);
  Offset get rightTerminal => Offset(position.dx + size.width, position.dy + size.height / 2);

  _CircuitComponentModel copyWith({Offset? position}) => _CircuitComponentModel(
        id: id,
        type: type,
        label: label,
        value: value,
        position: position ?? this.position,
        size: size,
      );
}

class _WireLink {
  const _WireLink({required this.id, required this.startTerminal, required this.endTerminal});

  final String id;
  final String startTerminal;
  final String endTerminal;
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}


