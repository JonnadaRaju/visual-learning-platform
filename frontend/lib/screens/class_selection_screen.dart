import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'home_screen.dart';

class ClassSelectionScreen extends StatelessWidget {
  const ClassSelectionScreen({super.key});

  static const _groups = <_ClassGroup>[
    _ClassGroup('Middle School', Color(0xFF26A69A), [6, 7, 8]),
    _ClassGroup('Secondary', Color(0xFF42A5F5), [9, 10]),
    _ClassGroup('Senior Secondary', Color(0xFFAB47BC), [11, 12]),
  ];

  @override
  Widget build(BuildContext context) {
    final classes = [
      for (final group in _groups)
        for (final classNumber in group.classes)
          _ClassOption(classNumber: classNumber, group: group),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: AppConfig.instance.selectedClass != null,
        title: const Text('Choose Class'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What class are you in?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                "We'll show topics perfect for your level",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: classes.map((option) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await AppConfig.instance.setSelectedClass(option.classNumber);
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: option.group.borderColor.withValues(alpha: 0.85)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Class ${option.classNumber}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option.group.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassOption {
  const _ClassOption({required this.classNumber, required this.group});

  final int classNumber;
  final _ClassGroup group;
}

class _ClassGroup {
  const _ClassGroup(this.label, this.borderColor, this.classes);

  final String label;
  final Color borderColor;
  final List<int> classes;
}