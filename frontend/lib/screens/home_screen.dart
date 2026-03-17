import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/concept.dart';
import '../providers/compute_provider.dart';
import 'concept_screen.dart';
import 'history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduViz Simulations'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
            icon: const Icon(Icons.history),
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
          final items = snapshot.data ?? const [];
          final groups = <String, List<SimulationDefinition>>{};
          for (final item in items) {
            groups.putIfAbsent(item.category, () => []).add(item);
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Interactive Physics', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Launch projectiles, blend waves, and solve circuits with live visual feedback.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ...groups.entries.map(
                (entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...entry.value.map(
                      (simulation) => Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          title: Text(simulation.name, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(simulation.description),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ConceptScreen(simulation: simulation)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
