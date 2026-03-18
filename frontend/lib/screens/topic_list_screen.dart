import 'package:flutter/material.dart';

import '../models/concept.dart';
import 'concept_screen.dart';
// Physics
import 'projectile_motion_screen.dart';
import 'gravitation_orbits_screen.dart';
import 'newtons_laws_screen.dart';
import 'fluid_pressure_screen.dart';
import 'waves_screen.dart';
import 'electric_circuits_screen.dart';
// Maths
import 'linear_equations_screen.dart';
import 'geometry_screen.dart';
// Chemistry
import 'atomic_structure_screen.dart';
import 'acids_bases_screen.dart';

/// All slugs that have a dedicated local screen — no API required.
const _localSlugs = {
  // Physics
  'projectile-motion',
  'waves-shm',
  'electric-circuits',
  'gravitation-orbits',
  'newtons-laws',
  'fluid-pressure',
  // Maths
  'linear-equations',
  'geometry',
  // Chemistry
  'atomic-structure',
  'acids-bases',
};

IconData _topicIcon(String name) {
  final l = name.toLowerCase();
  if (l.contains('projectile')) return Icons.show_chart;
  if (l.contains('wave') || l.contains('shm')) return Icons.waves;
  if (l.contains('circuit') || l.contains('electric')) return Icons.electric_bolt;
  if (l.contains('gravitation') || l.contains('gravity')) return Icons.public;
  if (l.contains('newton')) return Icons.balance;
  if (l.contains('fluid') || l.contains('pressure')) return Icons.water_drop;
  if (l.contains('linear') || l.contains('equation')) return Icons.trending_up;
  if (l.contains('geometry') || l.contains('triangle') || l.contains('circle')) return Icons.change_history;
  if (l.contains('atom') || l.contains('structure')) return Icons.grain;
  if (l.contains('acid') || l.contains('base') || l.contains('ph')) return Icons.science;
  return Icons.science_outlined;
}

Widget _getSimulationScreen(String slug, SimulationDefinition? simulation) {
  switch (slug) {
    case 'projectile-motion':   return const ProjectileMotionScreen();
    case 'waves-shm':           return const WavesScreen();
    case 'electric-circuits':   return const ElectricCircuitsScreen();
    case 'gravitation-orbits':  return const GravitationOrbitsScreen();
    case 'newtons-laws':        return const NewtonsLawsScreen();
    case 'fluid-pressure':      return const FluidPressureScreen();
    case 'linear-equations':    return const LinearEquationsScreen();
    case 'geometry':            return const GeometryScreen();
    case 'atomic-structure':    return const AtomicStructureScreen();
    case 'acids-bases':         return const AcidsBasesScreen();
    default:
      if (simulation != null) return ConceptScreen(simulation: simulation);
      return const _ComingSoonScreen();
  }
}

class TopicListScreen extends StatelessWidget {
  const TopicListScreen({
    super.key,
    required this.subject,
    required this.selectedClass,
    required this.simulations,
  });

  final SubjectCatalogItem subject;
  final int selectedClass;
  final List<SimulationDefinition> simulations;

  @override
  Widget build(BuildContext context) {
    final apiAvailable = {for (final s in simulations) s.slug: s};

    // Show topic if it has a local screen OR API returned it
    final topics = topicCatalog
        .where((t) => t.subjectId == subject.id)
        .where((t) => t.matchesClass(selectedClass))
        .where((t) =>
            _localSlugs.contains(t.simulationSlug) ||
            apiAvailable.containsKey(t.simulationSlug))
        .toList();

    final byCategory = <String, List<TopicCatalogItem>>{};
    for (final topic in topics) {
      byCategory.putIfAbsent(topic.category, () => []).add(topic);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.science, color: subject.accent, size: 22),
            const SizedBox(width: 10),
            Text(subject.name),
          ],
        ),
        backgroundColor: const Color(0xFF0F0F13),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: subject.accent),
        ),
      ),
      body: topics.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science_outlined,
                        color: subject.accent.withValues(alpha: 0.4), size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'No topics for Class $selectedClass yet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: const Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: byCategory.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF888899),
                              letterSpacing: 1.4,
                            ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final cols =
                            w > 900 ? 6 : w > 600 ? 4 : w > 400 ? 3 : 2;
                        return GridView.count(
                          crossAxisCount: cols,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: entry.value.map((topic) {
                            final simulation =
                                apiAvailable[topic.simulationSlug];
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                final baseTheme = Theme.of(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => Theme(
                                      data: baseTheme.copyWith(
                                        appBarTheme:
                                            baseTheme.appBarTheme.copyWith(
                                          backgroundColor: subject.accent,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      child: _getSimulationScreen(
                                          topic.simulationSlug, simulation),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      subject.accent.withOpacity(0.15),
                                      const Color(0xFF1A1A24),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: subject.accent.withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: subject.accent.withOpacity(0.22),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _topicIcon(topic.name),
                                        size: 20,
                                        color: subject.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      topic.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F18),
          foregroundColor: Colors.white,
          elevation: 0),
      body: const Center(
        child: Text('Simulation coming soon!',
            style: TextStyle(color: Colors.white70, fontSize: 18)),
      ),
    );
  }
}