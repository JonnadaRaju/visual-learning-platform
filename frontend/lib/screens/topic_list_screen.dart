import 'package:flutter/material.dart';

import '../models/concept.dart';
import 'concept_screen.dart';
import 'projectile_motion_screen.dart';
import 'gravitation_orbits_screen.dart';
import 'newtons_laws_screen.dart';
import 'fluid_pressure_screen.dart';
import 'waves_screen.dart';
import 'electric_circuits_screen.dart';

const _localSlugs = {
  'projectile-motion',
  'waves-shm',
  'electric-circuits',
  'gravitation-orbits',
  'newtons-laws',
  'fluid-pressure',
};

IconData _topicIcon(String name) {
  final l = name.toLowerCase();
  if (l.contains('projectile'))          return Icons.show_chart;
  if (l.contains('wave') || l.contains('shm')) return Icons.waves;
  if (l.contains('circuit') || l.contains('electric')) return Icons.electric_bolt;
  if (l.contains('gravitation') || l.contains('gravity')) return Icons.public;
  if (l.contains('optics'))              return Icons.wb_sunny;
  if (l.contains('thermodynamics') || l.contains('thermal')) return Icons.thermostat;
  if (l.contains('newton'))             return Icons.balance;
  if (l.contains('fluid') || l.contains('pressure')) return Icons.water_drop;
  return Icons.science;
}

Widget _getSimulationScreen(String slug, SimulationDefinition? simulation) {
  switch (slug) {
    case 'projectile-motion':  return const ProjectileMotionScreen();
    case 'waves-shm':          return const WavesScreen();
    case 'electric-circuits':  return const ElectricCircuitsScreen();
    case 'gravitation-orbits': return const GravitationOrbitsScreen();
    case 'newtons-laws':       return const NewtonsLawsScreen();
    case 'fluid-pressure':     return const FluidPressureScreen();
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
            Icon(_subjectIcon(subject.id), color: subject.accent, size: 20),
            const SizedBox(width: 10),
            Text(subject.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: const Color(0xFF0F0F13),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Column(
            children: [
              Container(height: 2, color: subject.accent),
              Container(
                height: 26,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Class $selectedClass topics',
                  style: TextStyle(
                    color: subject.accent.withOpacity(0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: topics.isEmpty
          ? _EmptyState(subject: subject, selectedClass: selectedClass)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: byCategory.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category header with accent line + count
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 18,
                              decoration: BoxDecoration(
                                color: subject.accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF888899),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: subject.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${entry.value.length}',
                                style: TextStyle(
                                  color: subject.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Topic grid
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
                            return _TopicCard(
                              topic: topic,
                              subject: subject,
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

  IconData _subjectIcon(String id) {
    switch (id) {
      case 'physics':   return Icons.science;
      case 'maths':     return Icons.calculate;
      case 'chemistry': return Icons.biotech;
      default:          return Icons.menu_book_rounded;
    }
  }
}

// ── Topic card ────────────────────────────────────────────
class _TopicCard extends StatefulWidget {
  const _TopicCard({
    required this.topic,
    required this.subject,
    required this.onTap,
  });
  final TopicCatalogItem topic;
  final SubjectCatalogItem subject;
  final VoidCallback onTap;

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        splashColor: widget.subject.accent.withOpacity(0.15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                widget.subject.accent.withOpacity(_hovered ? 0.22 : 0.13),
                const Color(0xFF1A1A24),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.subject.accent
                  .withOpacity(_hovered ? 0.45 : 0.22),
              width: _hovered ? 1.4 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.subject.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _topicIcon(widget.topic.name),
                  size: 22,
                  color: widget.subject.accent,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.topic.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.subject, required this.selectedClass});
  final SubjectCatalogItem subject;
  final int selectedClass;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: subject.accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.explore_off_rounded,
                color: subject.accent.withOpacity(0.5),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No topics for Class $selectedClass yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFAAAAAA)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back soon as we add more content!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF666677)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coming soon screen ────────────────────────────────────
class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: Colors.white38, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Simulation coming soon!',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}