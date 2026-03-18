import 'package:flutter/material.dart';

class SimulationParameter {
  const SimulationParameter({
    required this.id,
    required this.paramName,
    required this.paramLabel,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.stepSize,
  });

  final String id;
  final String paramName;
  final String paramLabel;
  final String unit;
  final double minValue;
  final double maxValue;
  final double defaultValue;
  final double stepSize;

  factory SimulationParameter.fromJson(Map<String, dynamic> json) =>
      SimulationParameter(
        id: json['id'] as String,
        paramName: json['param_name'] as String,
        paramLabel: json['param_label'] as String,
        unit: json['unit'] as String,
        minValue: (json['min_value'] as num).toDouble(),
        maxValue: (json['max_value'] as num).toDouble(),
        defaultValue: (json['default_value'] as num).toDouble(),
        stepSize: (json['step_size'] as num).toDouble(),
      );
}

class SimulationDefinition {
  const SimulationDefinition({
    required this.id,
    required this.category,
    required this.name,
    required this.slug,
    required this.description,
    required this.parameters,
  });

  final String id;
  final String category;
  final String name;
  final String slug;
  final String description;
  final List<SimulationParameter> parameters;

  factory SimulationDefinition.fromJson(Map<String, dynamic> json) =>
      SimulationDefinition(
        id: json['id'] as String,
        category: json['category'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String,
        parameters: (json['parameters'] as List<dynamic>)
            .map((e) => SimulationParameter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SubjectCatalogItem {
  const SubjectCatalogItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gradient,
    required this.accent,
    this.comingSoon = false,
  });

  final String id;
  final String name;
  final String emoji;
  final List<Color> gradient;
  final Color accent;
  final bool comingSoon;
}

class TopicCatalogItem {
  const TopicCatalogItem({
    required this.subjectId,
    required this.simulationSlug,
    required this.name,
    required this.category,
    required this.emoji,
    required this.classRange,
  });

  final String subjectId;
  final String simulationSlug;
  final String name;
  final String category;
  final String emoji;
  final List<int> classRange;

  bool matchesClass(int selectedClass) => classRange.contains(selectedClass);
}

// ── Subject Catalog ────────────────────────────────────────────────────────────

const subjectCatalog = <SubjectCatalogItem>[
  SubjectCatalogItem(
    id: 'physics',
    name: 'Physics',
    emoji: '📚',
    gradient: [Color(0xFF1565C0), Color(0xFF0288D1)],
    accent: Color(0xFF42A5F5),
  ),
  SubjectCatalogItem(
    id: 'maths',
    name: 'Maths',
    emoji: '📐',
    gradient: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    accent: Color(0xFFBA68C8),
  ),
  SubjectCatalogItem(
    id: 'chemistry',
    name: 'Chemistry',
    emoji: '🧪',
    gradient: [Color(0xFFBF360C), Color(0xFFFF7043)],
    accent: Color(0xFFFF8A65),
    // comingSoon removed — now has real simulations
  ),
  SubjectCatalogItem(
    id: 'biology',
    name: 'Biology',
    emoji: '🧬',
    gradient: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
    accent: Color(0xFF81C784),
    comingSoon: true,
  ),
];

// ── Topic Catalog ──────────────────────────────────────────────────────────────

const topicCatalog = <TopicCatalogItem>[

  // ── Physics ──────────────────────────────────────────────────────────────────

  TopicCatalogItem(
    subjectId: 'physics',
    simulationSlug: 'projectile-motion',
    name: 'Projectile Motion',
    category: 'Mechanics',
    emoji: '🏏',
    classRange: [9, 10, 11, 12],
  ),
  TopicCatalogItem(
    subjectId: 'physics',
    simulationSlug: 'waves-shm',
    name: 'Waves / SHM',
    category: 'Mechanics',
    emoji: '🌊',
    classRange: [9, 10, 11, 12],
  ),
  TopicCatalogItem(
    subjectId: 'physics',
    simulationSlug: 'electric-circuits',
    name: 'Electric Circuits',
    category: 'Electricity',
    emoji: '⚡',
    classRange: [9, 10, 11, 12],
  ),
  TopicCatalogItem(
    subjectId: 'physics',
    simulationSlug: 'gravitation-orbits',
    name: 'Gravitation & Orbits',
    category: 'Mechanics',
    emoji: '🪐',
    classRange: [9, 10, 11, 12],
  ),
  TopicCatalogItem(
    subjectId: 'physics',
    simulationSlug: 'newtons-laws',
    name: "Newton's Laws",
    category: 'Mechanics',
    emoji: '⚖️',
    classRange: [9, 10, 11, 12],
  ),
  TopicCatalogItem(
    subjectId: 'physics',
    simulationSlug: 'fluid-pressure',
    name: 'Fluid Pressure',
    category: 'Fluids',
    emoji: '💧',
    classRange: [9, 10, 11, 12],
  ),

  // ── Maths ────────────────────────────────────────────────────────────────────

  TopicCatalogItem(
    subjectId: 'maths',
    simulationSlug: 'linear-equations',
    name: 'Linear Equations',
    category: 'Algebra',
    emoji: '📈',
    classRange: [6, 7, 8, 9, 10, 11, 12],
  ),
  TopicCatalogItem(
    subjectId: 'maths',
    simulationSlug: 'geometry',
    name: 'Geometry',
    category: 'Geometry',
    emoji: '📐',
    classRange: [6, 7, 8, 9, 10, 11, 12],
  ),

  // ── Chemistry ────────────────────────────────────────────────────────────────

  TopicCatalogItem(
    subjectId: 'chemistry',
    simulationSlug: 'atomic-structure',
    name: 'Atomic Structure',
    category: 'Atomic Theory',
    emoji: '⚛️',
    classRange: [6, 7, 8, 9, 10, 11, 12],
  ),
  TopicCatalogItem(
    subjectId: 'chemistry',
    simulationSlug: 'acids-bases',
    name: 'Acids & Bases',
    category: 'Chemical Reactions',
    emoji: '🧪',
    classRange: [7, 8, 9, 10, 11, 12],
  ),
];