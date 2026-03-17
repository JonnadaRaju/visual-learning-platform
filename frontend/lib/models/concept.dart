class SimulationParameter {
  const SimulationParameter({required this.id, required this.paramName, required this.paramLabel, required this.unit, required this.minValue, required this.maxValue, required this.defaultValue, required this.stepSize});
  final String id;
  final String paramName;
  final String paramLabel;
  final String unit;
  final double minValue;
  final double maxValue;
  final double defaultValue;
  final double stepSize;
  factory SimulationParameter.fromJson(Map<String, dynamic> json) => SimulationParameter(id: json['id'] as String, paramName: json['param_name'] as String, paramLabel: json['param_label'] as String, unit: json['unit'] as String, minValue: (json['min_value'] as num).toDouble(), maxValue: (json['max_value'] as num).toDouble(), defaultValue: (json['default_value'] as num).toDouble(), stepSize: (json['step_size'] as num).toDouble());
}

class SimulationDefinition {
  const SimulationDefinition({required this.id, required this.category, required this.name, required this.slug, required this.description, required this.parameters});
  final String id;
  final String category;
  final String name;
  final String slug;
  final String description;
  final List<SimulationParameter> parameters;
  factory SimulationDefinition.fromJson(Map<String, dynamic> json) => SimulationDefinition(id: json['id'] as String, category: json['category'] as String, name: json['name'] as String, slug: json['slug'] as String, description: json['description'] as String, parameters: (json['parameters'] as List<dynamic>).map((e) => SimulationParameter.fromJson(e as Map<String, dynamic>)).toList());
}
