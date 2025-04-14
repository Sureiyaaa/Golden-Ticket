import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';

class PriorityTab extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final Function(DateTime) onFromDateChanged;
  final Function(DateTime) onToDateChanged;
  final VoidCallback onRefresh;
  final double scrollPosition;
  final double visibleRange;
  final Function(double) onScrollChanged;
  final List tickets;

  const PriorityTab({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onRefresh,
    required this.scrollPosition,
    required this.visibleRange,
    required this.onScrollChanged,
    required this.tickets,
  });

  @override
  State<PriorityTab> createState() => _PriorityTabState();
}

class _PriorityTabState extends State<PriorityTab> {
  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required Function(DateTime)? onPick,
  }) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text("$label: ${DateFormat('MMMM d, yyyy').format(date)}"),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2022, 1, 1),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick!(picked);
      },
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      barWidth: 3,
    );
  }

  List<FlSpot> _filterSpots(List<FlSpot> spots) {
    return spots.where((spot) {
      return spot.x >= widget.scrollPosition &&
          spot.x < widget.scrollPosition + widget.visibleRange;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTickets = widget.tickets.where((t) {
      final created = t.createdAt;
      return created != null &&
          !created.isBefore(widget.fromDate) &&
          !created.isAfter(widget.toDate);
    });

    if (filteredTickets.isEmpty) {
      return const Center(
          child: Text('No data available for the selected date range.'));
    }

    final Map<String, Map<String, int>> monthlyReports = {};

    DateTime current = DateTime(widget.fromDate.year, widget.fromDate.month);
    final end = DateTime(widget.toDate.year, widget.toDate.month);
    final dateFormatter =
    DateFormat(widget.fromDate.year != widget.toDate.year ? 'MMM yyyy' : 'MMM');

    while (!current.isAfter(end)) {
      final monthName = dateFormatter.format(current);
      monthlyReports[monthName] = {'Low': 0, 'Medium': 0, 'High': 0};
      current = DateTime(current.year, current.month + 1);
      if (current.month > 12) current = DateTime(current.year + 1, 1);
    }

    for (var ticket in filteredTickets) {
      final created = ticket.createdAt;
      final month = dateFormatter.format(created);
      final priority = ticket.priority ?? 'Medium';
      if (monthlyReports.containsKey(month)) {
        monthlyReports[month]![priority] =
            monthlyReports[month]![priority]! + 1;
      }
    }

    List<String> sortedMonths = monthlyReports.keys.toList();
    sortedMonths.sort((a, b) {
      final aDate = DateTime.parse(dateFormatter.parse(a).toString());
      final bDate = DateTime.parse(dateFormatter.parse(b).toString());
      return aDate.compareTo(bDate);
    });

    Map<String, List<FlSpot>> prioritySpots = {
      'Low': [],
      'Medium': [],
      'High': [],
    };

    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final low = monthlyReports[month]!['Low']!;
      final medium = monthlyReports[month]!['Medium']!;
      final high = monthlyReports[month]!['High']!;
      prioritySpots['Low']!.add(FlSpot(i.toDouble(), low.toDouble()));
      prioritySpots['Medium']!.add(FlSpot(i.toDouble(), medium.toDouble()));
      prioritySpots['High']!.add(FlSpot(i.toDouble(), high.toDouble()));
    }

    double minY = monthlyReports.values.expand((e) => e.values).reduce((a, b) => a < b ? a : b) - 1;
    double maxY = monthlyReports.values.expand((e) => e.values).reduce((a, b) => a > b ? a : b) + 3;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildDateButton(
                label: "From",
                date: widget.fromDate,
                onPick: widget.onFromDateChanged,
              ),
              const SizedBox(width: 16),
              _buildDateButton(
                label: "To",
                date: widget.toDate,
                onPick: widget.onToDateChanged,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: widget.onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              final index = value.toInt();
                              if (index >= widget.scrollPosition &&
                                  index < widget.scrollPosition + widget.visibleRange) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    sortedMonths[index],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        _buildLine(_filterSpots(prioritySpots['Low']!), getPriorityColor('Low')),
                        _buildLine(_filterSpots(prioritySpots['Medium']!), getPriorityColor('Medium')),
                        _buildLine(_filterSpots(prioritySpots['High']!), getPriorityColor('High')),
                      ],
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                    ),
                  ),
                ),
                if (sortedMonths.length > widget.visibleRange)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Slider(
                      value: widget.scrollPosition,
                      min: 0,
                      max: (sortedMonths.length - widget.visibleRange).toDouble(),
                      divisions: (sortedMonths.length - widget.visibleRange).toInt(),
                      label: 'Scroll',
                      thumbColor: kPrimary,
                      activeColor: kPrimary,
                      inactiveColor: kPrimaryContainer,
                      onChanged: widget.onScrollChanged,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
