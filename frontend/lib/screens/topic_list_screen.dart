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

IconData _topicIcon(String slug) {
  switch (slug) {
    case 'projectile-motion':   return Icons.show_chart;
    case 'waves-shm':           return Icons.waves;
    case 'electric-circuits':   return Icons.electric_bolt;
    case 'gravitation-orbits':  return Icons.public;
    case 'newtons-laws':        return Icons.balance;
    case 'fluid-pressure':      return Icons.water_drop;
    case 'linear-equations':    return Icons.trending_up;
    case 'geometry':            return Icons.change_history;
    case 'atomic-structure':    return Icons.grain;
    case 'acids-bases':         return Icons.science;
    default:                    return Icons.science_outlined;
  }
}

Widget _getSimulationScreen(SimulationDefinition simulation) {
  switch (simulation.slug) {
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
      // API returned a slug we don't have a local screen for yet
      // → fall back to ConceptScreen (API-driven UI)
      return ConceptScreen(simulation: simulation);
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
    // Filter simulations for this subject and class — data comes from API
    final topics = simulations
        .where((s) => s.subjectId == subject.id)
        .where((s) => s.matchesClass(selectedClass))
        .toList();

    // Group by category
    final byCategory = <String, List<SimulationDefinition>>{};
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
                        color: subject.accent.withValues(alpha: 0.4),
                        size: 56),
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
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
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
                          children: entry.value.map((simulation) {
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
                                      child: _getSimulationScreen(simulation),
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
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _topicIcon(simulation.slug),
                                        size: 20,
                                        color: subject.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      simulation.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    // Show emoji if available
                                    if (simulation.emoji.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(simulation.emoji,
                                          style:
                                              const TextStyle(fontSize: 12)),
                                    ],
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