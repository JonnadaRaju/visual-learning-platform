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
    if (selectedClass == null) return const ClassSelectionScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Edu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'Viz',
                style: TextStyle(
                  color: Color(0xFF378ADD),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: Color(0xFFAAAAAA), size: 22),
            tooltip: 'Run History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ActionChip(
              backgroundColor: const Color(0xFF1A1A24),
              side: const BorderSide(color: Color(0xFF333343)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              label: Text(
                'Class $selectedClass',
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
              ),
              avatar: const Icon(Icons.tune_rounded,
                  size: 16, color: Color(0xFFAAAAAA)),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ClassSelectionScreen()),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<SimulationDefinition>>(
        future: ref
            .read(apiServiceProvider)
            .fetchSimulations()
            .catchError((_) => <SimulationDefinition>[]),
        builder: (context, snapshot) {
          final loading =
              snapshot.connectionState == ConnectionState.waiting;
          final simulations =
              snapshot.data ?? const <SimulationDefinition>[];
          final apiSlugs = simulations.map((s) => s.slug).toSet();

          const localSlugs = {
            'projectile-motion',
            'waves-shm',
            'electric-circuits',
            'gravitation-orbits',
            'newtons-laws',
            'fluid-pressure',
          };

          bool isAvailable(TopicCatalogItem topic) =>
              localSlugs.contains(topic.simulationSlug) ||
              apiSlugs.contains(topic.simulationSlug);

          final greeting = _greeting();
          final apiOffline = snapshot.hasError ||
              (simulations.isEmpty &&
                  snapshot.connectionState == ConnectionState.done);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Split greeting
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Ready to explore?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Topics curated for Class $selectedClass.',
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF888899)),
                ),
                // Offline banner
                if (apiOffline) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1208),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      border: const Border(
                        left: BorderSide(
                            color: Color(0xFFEF9F27), width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Color(0xFFEF9F27), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Running offline — all local simulations available.',
                            style: TextStyle(
                              color: const Color(0xFFEF9F27)
                                  .withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Subject grid
                loading
                    ? _ShimmerGrid()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final cols =
                              w > 1000 ? 4 : w > 650 ? 3 : 2;
                          const cardH = 160.0;
                          final cardW =
                              (w - (cols - 1) * 10) / cols;
                          final ratio = cardW / cardH;

                          return GridView.count(
                            crossAxisCount: cols,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: ratio,
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            children:
                                subjectCatalog.map((subject) {
                              final topicCount = topicCatalog
                                  .where(
                                      (t) => t.subjectId == subject.id)
                                  .where((t) =>
                                      t.matchesClass(selectedClass))
                                  .where((t) => isAvailable(t))
                                  .length;
                              final enabled = !subject.comingSoon;
                              return _SubjectCard(
                                subject: subject,
                                topicCount: topicCount,
                                enabled: enabled,
                                onTap: enabled
                                    ? () => Navigator.of(context)
                                            .push(MaterialPageRoute(
                                          builder: (_) =>
                                              TopicListScreen(
                                            subject: subject,
                                            selectedClass: selectedClass,
                                            simulations: simulations,
                                          ),
                                        ))
                                    : null,
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
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning!';
    if (h < 17) return 'Good afternoon!';
    return 'Good evening!';
  }
}

// ── Subject card ──────────────────────────────────────────
class _SubjectCard extends StatefulWidget {
  const _SubjectCard({
    required this.subject,
    required this.topicCount,
    required this.enabled,
    required this.onTap,
  });
  final SubjectCatalogItem subject;
  final int topicCount;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _hovered = false;

  IconData get _icon {
    switch (widget.subject.id) {
      case 'physics':   return Icons.science;
      case 'maths':     return Icons.calculate;
      case 'chemistry': return Icons.biotech;
      case 'biology':   return Icons.eco;
      default:          return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: _hovered && widget.enabled
              ? (Matrix4.identity()..scale(1.02))
              : Matrix4.identity(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.subject.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                // Icon top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(_icon, size: 22, color: Colors.white),
                  ),
                ),
                // Text bottom-left
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.subject.comingSoon)
                        Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('Coming Soon',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ),
                      Text(
                        widget.subject.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.topicCount} topics',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer loading placeholder ───────────────────────────
class _ShimmerGrid extends StatefulWidget {
  @override
  State<_ShimmerGrid> createState() => _ShimmerGridState();
}

class _ShimmerGridState extends State<_ShimmerGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.04, end: 0.14).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          4,
          (_) => Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(_anim.value),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}