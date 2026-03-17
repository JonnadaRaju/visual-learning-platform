import 'package:flutter/material.dart';

class SliderFieldData {
  const SliderFieldData({
    required this.id,
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    this.color,
  });

  final String id;
  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final double step;
  final Color? color;
}

class SliderSectionData {
  const SliderSectionData({required this.title, required this.fields});

  final String title;
  final List<SliderFieldData> fields;
}

class SliderPanel extends StatelessWidget {
  const SliderPanel({
    super.key,
    required this.sections,
    required this.onChanged,
  });

  final List<SliderSectionData> sections;
  final ValueChanged<(String, double)> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections
          .map(
            (section) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...section.fields.map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    field.label,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                Text(
                                  '${field.value.toStringAsFixed(field.step < 1 ? 1 : 0)} ${field.unit}'.trim(),
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: field.color ?? Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: field.color,
                                thumbColor: field.color,
                                overlayColor: (field.color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.15),
                              ),
                              child: Slider(
                                value: field.value.clamp(field.min, field.max),
                                min: field.min,
                                max: field.max,
                                divisions: ((field.max - field.min) / field.step).round(),
                                onChanged: (value) => onChanged((field.id, value)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

