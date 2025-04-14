import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/priority_tab_widget.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsPage extends StatefulWidget {
  final HiveSession? session;

  ReportsPage({super.key, required this.session});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _fromDate;
  DateTime _toDate = DateTime.now();
  double _visibleRange = 6; // Number of months shown at once
  double _scrollPosition =
      0; // Ranges from 0 to (sortedMonths.length - _visibleRange)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fromDate =
        DateTime(DateTime.now().year, 1, 1); // Default to Jan 1 this year
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        if (dataManager.tickets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Reports'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Priority Reports'),
                Tab(text: 'Tag Reports'),
                Tab(text: 'Feedback Reports'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              PriorityTab(
                fromDate: _fromDate,
                toDate: _toDate,
                onFromDateChanged: (date) {
                  setState(() => _fromDate = date);
                  if (_toDate.isBefore(_fromDate)) {
                    _toDate = _fromDate;
                  }
                },
                onToDateChanged: (date) {
                  setState(() => _toDate = date);
                  if (_toDate.isBefore(_fromDate)) {
                    _toDate = _fromDate;
                  }
                },
                onRefresh: () => setState(() {}),
                scrollPosition: _scrollPosition,
                visibleRange: _visibleRange,
                onScrollChanged: (val) => setState(() => _scrollPosition = val),
                tickets: dataManager.tickets,
              ),

              _buildPlaceholderTab('Tag Reports'),
              _buildPlaceholderTab('Feedback Reports'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateButton(
      {required String label,
      required DateTime date,
      required Function(DateTime)? onPick}) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text("$label: ${DateFormat('MMMM d, yyyy').format(date)}"),
      onPressed: onPick == null
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2022, 1, 1),
                lastDate: DateTime.now(),
              );
              if (picked != null) onPick(picked);
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
      return spot.x >= _scrollPosition &&
          spot.x < _scrollPosition + _visibleRange;
    }).toList();
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Text(
        '$title Coming Soon',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
