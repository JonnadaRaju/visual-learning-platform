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
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        title: const Text('Run History',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<(RunStats, List<RunSummary>)>(
        future: Future.wait<dynamic>(
                [api.fetchRunStats(), api.fetchRuns()])
            .then((v) =>
                (v[0] as RunStats, v[1] as List<RunSummary>)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF378ADD)));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(snapshot.error.toString(),
                    style:
                        const TextStyle(color: Colors.white70)));
          }
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();
          final stats = data.$1;
          final runs = data.$2;

          if (runs.isEmpty) return const _EmptyState();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatTile(
                    icon: Icons.science_rounded,
                    label: 'Total Runs',
                    value: '${stats.totalRuns}',
                    color: const Color(0xFF378ADD),
                  ),
                  _StatTile(
                    icon: Icons.bookmark_rounded,
                    label: 'Saved',
                    value: '${stats.savedRuns}',
                    color: const Color(0xFFEF9F27),
                  ),
                  _StatTile(
                    icon: Icons.explore_rounded,
                    label: 'Explored',
                    value: '${stats.simulationsExplored}',
                    color: const Color(0xFF1D9E75),
                  ),
                  _StatTile(
                    icon: Icons.access_time_rounded,
                    label: 'Last Active',
                    value: stats.lastActive == null
                        ? 'Never'
                        : '${stats.lastActive!.day}/${stats.lastActive!.month}/${stats.lastActive!.year}',
                    color: const Color(0xFFAAAAAA),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Run list
              ...runs.map((run) => _RunItem(run: run)),
            ],
          );
        },
      ),
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF777777), fontSize: 11)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Run item ──────────────────────────────────────────────
class _RunItem extends StatelessWidget {
  const _RunItem({required this.run});
  final RunSummary run;

  Color _accentForSlug(String slug) {
    if (slug.contains('projectile') || slug.contains('wave') ||
        slug.contains('gravitation') || slug.contains('newton') ||
        slug.contains('fluid') || slug.contains('circuit')) {
      return const Color(0xFF378ADD);
    }
    return const Color(0xFFAAAAAA);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForSlug(run.simulationSlug);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(width: 4, color: accent),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              run.simulationSlug,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Inputs: ${run.inputParams}',
                              style: const TextStyle(
                                  color: Color(0xFF777777),
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Result key chips
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: run.resultPayload.keys
                                  .take(4)
                                  .map(
                                    (k) => Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF12121A),
                                        borderRadius:
                                            BorderRadius.circular(5),
                                        border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.07)),
                                      ),
                                      child: Text(k,
                                          style: const TextStyle(
                                              color: Color(0xFF60B4F0),
                                              fontSize: 10)),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      // Right: bookmark + time
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (run.isSaved)
                            const Icon(Icons.bookmark_rounded,
                                color: Color(0xFFEF9F27), size: 18),
                          const SizedBox(height: 4),
                          Text(
                            '${run.createdAt.hour.toString().padLeft(2, '0')}:${run.createdAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: Color(0xFF666677), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_rounded,
              color: Colors.white.withOpacity(0.15), size: 72),
          const SizedBox(height: 16),
          const Text('No runs yet',
              style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Launch a simulation to see history here',
              style:
                  TextStyle(color: Color(0xFF666677), fontSize: 13)),
        ],
      ),
    );
  }
}