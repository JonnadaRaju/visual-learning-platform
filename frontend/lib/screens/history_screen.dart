import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/compute_result.dart';
import '../providers/compute_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Run History')),
      body: FutureBuilder<(RunStats, List<RunSummary>)>(
        future: Future.wait<dynamic>([api.fetchRunStats(), api.fetchRuns()])
            .then((values) => (values[0] as RunStats, values[1] as List<RunSummary>)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final data = snapshot.data;
          if (data == null) {
            return const SizedBox.shrink();
          }
          final stats = data.$1;
          final runs = data.$2;
          if (runs.isEmpty) {
            return const Center(child: Text('No saved or simulated runs yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatBlock(label: 'Total runs', value: '${stats.totalRuns}'),
                      _StatBlock(label: 'Saved runs', value: '${stats.savedRuns}'),
                      _StatBlock(label: 'Explored', value: '${stats.simulationsExplored}'),
                      _StatBlock(
                        label: 'Last active',
                        value: stats.lastActive == null
                            ? 'Never'
                            : '${stats.lastActive!.day}/${stats.lastActive!.month}/${stats.lastActive!.year}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ...runs.map(
                (run) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(run.simulationSlug),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Inputs: ${run.inputParams}\nResult keys: ${run.resultPayload.keys.join(', ')}'),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (run.isSaved) const Icon(Icons.bookmark, color: Color(0xFF0F766E)),
                        Text('${run.createdAt.hour.toString().padLeft(2, '0')}:${run.createdAt.minute.toString().padLeft(2, '0')}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF7F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
