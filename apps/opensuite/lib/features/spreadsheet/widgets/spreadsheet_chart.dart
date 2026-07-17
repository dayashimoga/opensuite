import 'package:fileutility_core/fileutility_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Chart type options for spreadsheet data visualization.
enum SpreadsheetChartType { bar, line, pie }

/// A widget that renders interactive charts from spreadsheet cell data.
///
/// Supports Bar, Line, and Pie charts using fl_chart.
/// Reads data from the active [SheetData] based on the selected cell range.
class SpreadsheetChart extends StatelessWidget {
  final SheetData sheet;
  final CellRange dataRange;
  final SpreadsheetChartType chartType;
  final String? title;

  const SpreadsheetChart({
    super.key,
    required this.sheet,
    required this.dataRange,
    this.chartType = SpreadsheetChartType.bar,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _extractData();

    if (data.isEmpty) {
      return Center(
        child: Text(
          'No numeric data in selected range',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: switch (chartType) {
            SpreadsheetChartType.bar => _buildBarChart(data, theme),
            SpreadsheetChartType.line => _buildLineChart(data, theme),
            SpreadsheetChartType.pie => _buildPieChart(data, theme),
          },
        ),
      ],
    );
  }

  /// Extracts (label, value) pairs from the data range.
  ///
  /// Strategy: first column = labels, remaining columns = numeric values.
  /// If only one column, uses row index as label.
  List<_ChartEntry> _extractData() {
    final result = <_ChartEntry>[];
    final tl = dataRange.topLeft;
    final br = dataRange.bottomRight;

    for (int r = tl.row; r <= br.row; r++) {
      String label;
      double? value;

      if (tl.col < br.col) {
        // Multi-column: first col is label, second col is value
        label = sheet.getCell(CellPosition(r, tl.col)).displayValue;
        final raw = sheet.getCell(CellPosition(r, tl.col + 1)).rawValue;
        value = double.tryParse(raw);
      } else {
        // Single column: row index as label, cell value as data
        label = 'Row ${r + 1}';
        final raw = sheet.getCell(CellPosition(r, tl.col)).rawValue;
        value = double.tryParse(raw);
      }

      if (value != null && label.isNotEmpty) {
        result.add(_ChartEntry(label: label, value: value));
      }
    }

    return result;
  }

  Widget _buildBarChart(List<_ChartEntry> data, ThemeData theme) {
    final colors = _generateColors(data.length, theme);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[groupIndex].label}\n${rod.toY.toStringAsFixed(1)}',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      data[index].label.length > 8
                          ? '${data[index].label.substring(0, 8)}…'
                          : data[index].label,
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        barGroups: List.generate(
          data.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].value,
                color: colors[i],
                width: 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<_ChartEntry> data, ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final index = spot.x.toInt();
              final label =
                  index < data.length ? data[index].label : '';
              return LineTooltipItem(
                '$label\n${spot.y.toStringAsFixed(1)}',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      data[index].label.length > 6
                          ? '${data[index].label.substring(0, 6)}…'
                          : data[index].label,
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(
                color: theme.colorScheme.outlineVariant, width: 1),
            bottom: BorderSide(
                color: theme.colorScheme.outlineVariant, width: 1),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i].value),
            ),
            isCurved: true,
            curveSmoothness: 0.3,
            color: primaryColor,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: primaryColor,
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<_ChartEntry> data, ThemeData theme) {
    final colors = _generateColors(data.length, theme);
    final total = data.fold<double>(0, (sum, e) => sum + e.value.abs());

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(
                data.length,
                (i) {
                  final percentage =
                      total > 0 ? (data[i].value.abs() / total * 100) : 0;
                  return PieChartSectionData(
                    color: colors[i],
                    value: data[i].value.abs(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              data.length,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data[i].label,
                        style: theme.textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _generateColors(int count, ThemeData theme) {
    final baseColors = [
      theme.colorScheme.primary,
      theme.colorScheme.tertiary,
      theme.colorScheme.secondary,
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFF44336), // Red
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF795548), // Brown
    ];

    return List.generate(count, (i) => baseColors[i % baseColors.length]);
  }
}

class _ChartEntry {
  final String label;
  final double value;
  const _ChartEntry({required this.label, required this.value});
}
