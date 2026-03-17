import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/concept.dart';
import '../providers/compute_provider.dart';
import 'class_selection_screen.dart';
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
      appBar: AppBar(
        title: const Text('EduViz'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              backgroundColor: const Color(0xFF1A1A24),
              side: const BorderSide(color: Color(0xFF333343)),
              label: Text('Class $selectedClass'),
              avatar: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFFAAAAAA)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClassSelectionScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<SimulationDefinition>>(
        future: ref.read(apiServiceProvider).fetchSimulations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => (context as Element).markNeedsBuild(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final simulations = snapshot.data ?? const <SimulationDefinition>[];
          final availableSlugs = simulations.map((item) => item.slug).toSet();
          final greeting = _greeting();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting Ready to explore?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a subject to see topics curated for Class $selectedClass.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFFAAAAAA)),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: subjectCatalog.map((subject) {
                    final topicCount = topicCatalog
                        .where((topic) => topic.subjectId == subject.id)
                        .where((topic) => topic.matchesClass(selectedClass))
                        .where((topic) => availableSlugs.contains(topic.simulationSlug))
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_subjectIcon(subject.id), size: 22, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (subject.comingSoon)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text('Coming Soon', style: TextStyle(color: Colors.white)),
                                    ),
                                  Text(
                                    subject.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$topicCount topics',
                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                  ),
                                ],
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
        },
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    }
    if (hour < 17) {
      return 'Good afternoon!';
    }
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
      case 'biology':
        return Icons.eco;
      default:
        return Icons.menu_book_rounded;
    }
  }
}