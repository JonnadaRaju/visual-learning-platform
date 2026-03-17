import 'package:flutter/material.dart';

import '../models/concept.dart';
import 'concept_screen.dart';

IconData _topicIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('projectile')) return Icons.show_chart;
  if (lower.contains('wave') || lower.contains('shm')) return Icons.waves;
  if (lower.contains('circuit') || lower.contains('electric')) return Icons.electric_bolt;
  if (lower.contains('gravitation') || lower.contains('gravity')) return Icons.public;
  if (lower.contains('optics')) return Icons.wb_sunny;
  if (lower.contains('thermodynamics') || lower.contains('thermal')) return Icons.thermostat;
  if (lower.contains('force')) return Icons.speed;
  if (lower.contains('acceleration')) return Icons.trending_up;
  if (lower.contains('speed') || lower.contains('velocity')) return Icons.directions_run;
  return Icons.science;
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
    final available = {
      for (final simulation in simulations) simulation.slug: simulation,
    };
    final topics = topicCatalog
        .where((topic) => topic.subjectId == subject.id)
        .where((topic) => topic.matchesClass(selectedClass))
        .where((topic) => available.containsKey(topic.simulationSlug))
        .toList();
    final byCategory = <String, List<TopicCatalogItem>>{};
    for (final topic in topics) {
      byCategory.putIfAbsent(topic.category, () => []).add(topic);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(subject.emoji == '📚' ? Icons.science : Icons.science, color: subject.accent, size: 24),
            const SizedBox(width: 10),
            Text(subject.name),
          ],
        ),
        backgroundColor: const Color(0xFF0F0F13),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: subject.accent),
        ),
      ),
      body: topics.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No topics for Class $selectedClass yet. Check back soon!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFFAAAAAA)),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: byCategory.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
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
                      GridView.count(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: entry.value.map((topic) {
                          final simulation = available[topic.simulationSlug]!;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              final baseTheme = Theme.of(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => Theme(
                                    data: baseTheme.copyWith(
                                      appBarTheme: baseTheme.appBarTheme.copyWith(
                                        backgroundColor: subject.accent,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    child: ConceptScreen(simulation: simulation),
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
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}