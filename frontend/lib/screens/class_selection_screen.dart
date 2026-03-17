import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'home_screen.dart';

class ClassSelectionScreen extends StatelessWidget {
  const ClassSelectionScreen({super.key});

  static const _groups = <_ClassGroup>[
    _ClassGroup('Middle School',  Color(0xFF26A69A), [6, 7, 8]),
    _ClassGroup('Secondary',      Color(0xFF42A5F5), [9, 10]),
    _ClassGroup('Senior Secondary', Color(0xFFAB47BC), [11, 12]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        automaticallyImplyLeading: AppConfig.instance.selectedClass != null,
        title: const Text('Choose Class',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0F0F18),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'What class are you in?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We'll show topics perfect for your level",
                style: TextStyle(fontSize: 15, color: Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 32),
              // Groups with section labels
              ..._groups.map((group) => _GroupSection(group: group)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group});
  final _ClassGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label with color dot
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: group.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                group.label.toUpperCase(),
                style: TextStyle(
                  color: group.borderColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Cards row
          Row(
            children: group.classes.map((classNum) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: classNum != group.classes.last ? 10 : 0,
                  ),
                  child: _ClassCard(
                    classNumber: classNum,
                    group: group,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatefulWidget {
  const _ClassCard({required this.classNumber, required this.group});
  final int classNumber;
  final _ClassGroup group;

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: widget.group.borderColor.withOpacity(0.15),
        onTap: () async {
          await AppConfig.instance.setSelectedClass(widget.classNumber);
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 100,
          decoration: BoxDecoration(
            color: _hovered
                ? widget.group.borderColor.withOpacity(0.08)
                : const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? widget.group.borderColor
                  : widget.group.borderColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Class ${widget.classNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.group.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassGroup {
  const _ClassGroup(this.label, this.borderColor, this.classes);
  final String label;
  final Color borderColor;
  final List<int> classes;
}