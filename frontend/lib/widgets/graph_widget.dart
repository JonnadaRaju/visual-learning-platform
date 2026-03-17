import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphSeries {
  const GraphSeries({
    required this.label,
    required this.spots,
    required this.color,
    this.curved = true,
    this.width = 3,
  });

  final String label;
  final List<FlSpot> spots;
  final Color color;
  final bool curved;
  final double width;
}

class GraphWidget extends StatelessWidget {
  const GraphWidget({super.key, required this.title, required this.series});

  final String title;
  final List<GraphSeries> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || series.every((s) => s.spots.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: _minX(series),
                  maxX: _maxX(series),
                  minY: _minY(series),
                  maxY: _maxY(series),
                  gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _interval(series)),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 42)),
                    bottomTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 28)),
                  ),
                  lineBarsData: series
                      .map(
                        (s) => LineChartBarData(
                          spots: s.spots,
                          isCurved: s.curved,
                          barWidth: s.width,
                          color: s.color,
                          dotData: const FlDotData(show: false),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: series
                  .map(
                    (s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(999)),
                        ),
                        const SizedBox(width: 8),
                        Text(s.label),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  double _minX(List<GraphSeries> s) =>
      s.expand((i) => i.spots).map((sp) => sp.x).reduce((a, b) => a < b ? a : b);
  double _maxX(List<GraphSeries> s) =>
      s.expand((i) => i.spots).map((sp) => sp.x).reduce((a, b) => a > b ? a : b);
  double _minY(List<GraphSeries> s) {
    final v =
        s.expand((i) => i.spots).map((sp) => sp.y).reduce((a, b) => a < b ? a : b);
    return v == 0 ? -1 : v * 1.15;
  }
  double _maxY(List<GraphSeries> s) {
    final v =
        s.expand((i) => i.spots).map((sp) => sp.y).reduce((a, b) => a > b ? a : b);
    return v == 0 ? 1 : v * 1.15;
  }
  double? _interval(List<GraphSeries> s) {
    final span = (_maxY(s) - _minY(s)).abs();
    return span == 0 ? 1 : span / 4;
  }
}