import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/concept.dart';
import '../providers/compute_provider.dart';
import 'class_selection_screen.dart';
import 'history_screen.dart';
import 'topic_list_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedClass = AppConfig.instance.selectedClass;
    if (selectedClass == null) {
      return const ClassSelectionScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClassSelectionScreen()),
            );
          },
          child: const Text('EduViz'),
        ),
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFFAAAAAA)),
            tooltip: 'Run History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              backgroundColor: const Color(0xFF1A1A24),
              side: const BorderSide(color: Color(0xFF333343)),
              label: Text('Class $selectedClass',
                  style: const TextStyle(color: Colors.white)),
              avatar: const Icon(Icons.tune_rounded,
                  size: 18, color: Color(0xFFAAAAAA)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ClassSelectionScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<SimulationDefinition>>(
        // Gracefully handle API being down — local screens still work
        future: ref
            .read(apiServiceProvider)
            .fetchSimulations()
            .catchError((_) => <SimulationDefinition>[]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF378ADD)));
          }

          final simulations = snapshot.data ?? const <SimulationDefinition>[];
          final apiSlugs = simulations.map((s) => s.slug).toSet();

          // Slugs that have a dedicated local screen — always available
          const localSlugs = {
            'projectile-motion',
            'waves-shm',
            'electric-circuits',
            'gravitation-orbits',
            'newtons-laws',
            'fluid-pressure',
            'linear-equations',
            'geometry',
            'atomic-structure',
            'acids-bases',
          };

          bool isAvailable(TopicCatalogItem topic) =>
              localSlugs.contains(topic.simulationSlug) ||
              apiSlugs.contains(topic.simulationSlug);

          final greeting = _greeting();
          final apiOffline = snapshot.hasError ||
              (simulations.isEmpty &&
                  snapshot.connectionState == ConnectionState.done);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting Ready to explore?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a subject to see topics curated for Class $selectedClass.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: const Color(0xFFAAAAAA)),
                ),
                if (apiOffline) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Backend offline — all local simulations are still available.',
                            style: TextStyle(
                                color: Colors.amber.withValues(alpha: 0.85),
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Responsive grid — fixed card height ~160px
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final cols = w > 1000 ? 4 : w > 650 ? 3 : 2;
                    const cardH = 160.0;
                    final cardW = (w - (cols - 1) * 8) / cols;
                    final ratio = cardW / cardH;

                    return GridView.count(
                      crossAxisCount: cols,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: ratio,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: subjectCatalog.map((subject) {
                        final topicCount = topicCatalog
                            .where((t) => t.subjectId == subject.id)
                            .where((t) => t.matchesClass(selectedClass))
                            .where((t) => isAvailable(t))
                            .length;
                        final enabled = !subject.comingSoon;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: !enabled
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TopicListScreen(
                                        subject: subject,
                                        selectedClass: selectedClass,
                                        simulations: simulations,
                                      ),
                                    ),
                                  );
                                },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: subject.gradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.20),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(_subjectIcon(subject.id),
                                        size: 20, color: Colors.white),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 60,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (subject.comingSoon)
                                        Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.25),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: const Text('Coming Soon',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10)),
                                        ),
                                      Text(
                                        subject.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$topicCount topics',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  IconData _subjectIcon(String subjectId) {
    switch (subjectId) {
      case 'physics':
        return Icons.science;
      case 'maths':
        return Icons.calculate;
      case 'chemistry':
        return Icons.biotech;
      default:
        return Icons.menu_book_rounded;
    }
  }
}