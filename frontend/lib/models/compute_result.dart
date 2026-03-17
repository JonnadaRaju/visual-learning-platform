class PlotPoint {
  const PlotPoint({required this.x, required this.y, this.t});

  final double x;
  final double y;
  final double? t;

  factory PlotPoint.fromJson(Map<String, dynamic> json) => PlotPoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        t: json['t'] == null ? null : (json['t'] as num).toDouble(),
      );
}

class ProjectileResult {
  const ProjectileResult({
    required this.runId,
    required this.trajectory,
    required this.maxHeight,
    required this.range,
    required this.timeOfFlight,
    required this.cacheHit,
  });

  final String runId;
  final List<PlotPoint> trajectory;
  final double maxHeight;
  final double range;
  final double timeOfFlight;
  final bool cacheHit;

  factory ProjectileResult.fromJson(Map<String, dynamic> json) => ProjectileResult(
        runId: json['run_id'] as String,
        trajectory: (json['trajectory'] as List<dynamic>)
            .map((e) => PlotPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        maxHeight: (json['max_height'] as num).toDouble(),
        range: (json['range'] as num).toDouble(),
        timeOfFlight: (json['time_of_flight'] as num).toDouble(),
        cacheHit: json['cache_hit'] as bool,
      );
}

class WaveResult {
  const WaveResult({
    required this.runId,
    required this.points,
    required this.period,
    required this.angularFrequency,
    required this.cacheHit,
  });

  final String runId;
  final List<PlotPoint> points;
  final double period;
  final double angularFrequency;
  final bool cacheHit;

  factory WaveResult.fromJson(Map<String, dynamic> json) => WaveResult(
        runId: json['run_id'] as String,
        points: (json['points'] as List<dynamic>)
            .map((e) => PlotPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        period: (json['period'] as num).toDouble(),
        angularFrequency: (json['angular_frequency'] as num).toDouble(),
        cacheHit: json['cache_hit'] as bool,
      );
}

class WaveSeries {
  const WaveSeries({
    required this.label,
    required this.waveType,
    required this.points,
    required this.period,
    required this.angularFrequency,
  });

  final String label;
  final String waveType;
  final List<PlotPoint> points;
  final double period;
  final double angularFrequency;

  factory WaveSeries.fromJson(Map<String, dynamic> json) => WaveSeries(
        label: json['label'] as String,
        waveType: json['wave_type'] as String,
        points: (json['points'] as List<dynamic>)
            .map((e) => PlotPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        period: (json['period'] as num).toDouble(),
        angularFrequency: (json['angular_frequency'] as num).toDouble(),
      );
}

class WaveSuperpositionResult {
  const WaveSuperpositionResult({
    required this.runId,
    required this.waves,
    required this.combinedPoints,
    required this.cacheHit,
  });

  final String runId;
  final List<WaveSeries> waves;
  final List<PlotPoint> combinedPoints;
  final bool cacheHit;

  factory WaveSuperpositionResult.fromJson(Map<String, dynamic> json) => WaveSuperpositionResult(
        runId: json['run_id'] as String,
        waves: (json['waves'] as List<dynamic>)
            .map((e) => WaveSeries.fromJson(e as Map<String, dynamic>))
            .toList(),
        combinedPoints: (json['combined_points'] as List<dynamic>)
            .map((e) => PlotPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheHit: json['cache_hit'] as bool,
      );
}

class NodeVoltage {
  const NodeVoltage({required this.node, required this.voltage});

  final String node;
  final double voltage;

  factory NodeVoltage.fromJson(Map<String, dynamic> json) => NodeVoltage(
        node: json['node'] as String,
        voltage: (json['voltage'] as num).toDouble(),
      );
}

class BranchCurrent {
  const BranchCurrent({required this.componentId, required this.current});

  final String componentId;
  final double current;

  factory BranchCurrent.fromJson(Map<String, dynamic> json) => BranchCurrent(
        componentId: json['component_id'] as String,
        current: (json['current'] as num).toDouble(),
      );
}

class CircuitResult {
  const CircuitResult({
    required this.runId,
    required this.nodeVoltages,
    required this.branchCurrents,
    required this.totalResistance,
    required this.totalPower,
    required this.cacheHit,
  });

  final String runId;
  final List<NodeVoltage> nodeVoltages;
  final List<BranchCurrent> branchCurrents;
  final double? totalResistance;
  final double totalPower;
  final bool cacheHit;

  factory CircuitResult.fromJson(Map<String, dynamic> json) => CircuitResult(
        runId: json['run_id'] as String,
        nodeVoltages: (json['node_voltages'] as List<dynamic>)
            .map((e) => NodeVoltage.fromJson(e as Map<String, dynamic>))
            .toList(),
        branchCurrents: (json['branch_currents'] as List<dynamic>)
            .map((e) => BranchCurrent.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalResistance: json['total_resistance'] == null
            ? null
            : (json['total_resistance'] as num).toDouble(),
        totalPower: (json['total_power'] as num).toDouble(),
        cacheHit: json['cache_hit'] as bool,
      );
}

class RunSummary {
  const RunSummary({
    required this.id,
    required this.simulationSlug,
    required this.inputParams,
    required this.resultPayload,
    required this.isSaved,
    required this.createdAt,
  });

  final String id;
  final String simulationSlug;
  final Map<String, dynamic> inputParams;
  final Map<String, dynamic> resultPayload;
  final bool isSaved;
  final DateTime createdAt;

  factory RunSummary.fromJson(Map<String, dynamic> json) => RunSummary(
        id: json['id'] as String,
        simulationSlug: json['simulation_slug'] as String,
        inputParams: Map<String, dynamic>.from(json['input_params'] as Map<String, dynamic>),
        resultPayload: Map<String, dynamic>.from(json['result_payload'] as Map<String, dynamic>),
        isSaved: json['is_saved'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class RunStats {
  const RunStats({
    required this.totalRuns,
    required this.savedRuns,
    required this.simulationsExplored,
    required this.lastActive,
  });

  final int totalRuns;
  final int savedRuns;
  final int simulationsExplored;
  final DateTime? lastActive;

  factory RunStats.fromJson(Map<String, dynamic> json) => RunStats(
        totalRuns: json['total_runs'] as int,
        savedRuns: json['saved_runs'] as int,
        simulationsExplored: json['simulations_explored'] as int,
        lastActive: json['last_active'] == null
            ? null
            : DateTime.parse(json['last_active'] as String),
      );
}