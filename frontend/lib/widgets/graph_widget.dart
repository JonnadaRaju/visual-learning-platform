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
    if (series.isEmpty || series.every((item) => item.spots.isEmpty)) {
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
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _interval(series)),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                  ),
                  lineBarsData: series
                      .map(
                        (item) => LineChartBarData(
                          spots: item.spots,
                          isCurved: item.curved,
                          barWidth: item.width,
                          color: item.color,
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
                    (item) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(999)),
                        ),
                        const SizedBox(width: 8),
                        Text(item.label),
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

  double _minX(List<GraphSeries> series) =>
      series.expand((item) => item.spots).map((spot) => spot.x).reduce((a, b) => a < b ? a : b);

  double _maxX(List<GraphSeries> series) =>
      series.expand((item) => item.spots).map((spot) => spot.x).reduce((a, b) => a > b ? a : b);

  double _minY(List<GraphSeries> series) {
    final value = series.expand((item) => item.spots).map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    return value == 0 ? -1 : value * 1.15;
  }

  double _maxY(List<GraphSeries> series) {
    final value = series.expand((item) => item.spots).map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return value == 0 ? 1 : value * 1.15;
  }

  double? _interval(List<GraphSeries> series) {
    final min = _minY(series);
    final max = _maxY(series);
    final span = (max - min).abs();
    if (span == 0) {
      return 1;
    }
    return span / 4;
  }
}
