import 'package:flutter/material.dart';

class ResultStat {
  const ResultStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
}

class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.cacheHit,
    this.onSave,
    this.isSaving = false,
  });

  final String title;
  final String subtitle;
  final List<ResultStat> stats;
  final bool cacheHit;
  final VoidCallback? onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (cacheHit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999)),
                    child: const Text('Cached'),
                  ),
              ],
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats
                    .map(
                      (s) => Container(
                        width: 180,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (s.color ?? colorScheme.primary)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.label,
                                style:
                                    Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 8),
                            Text(
                              s.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: s.color ?? colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (onSave != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(isSaving ? 'Saving...' : 'Save experiment'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}