import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/food_database.dart';
import '../models/food_log.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  DateTime weekStart =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  DateTime weekEnd =
      DateTime.now().add(Duration(days: 7 - DateTime.now().weekday));

  List<FoodLog> logs = [];
  double totalCalories = 0;
  double totalCarbs = 0;
  double totalProtein = 0;
  double totalFat = 0;
  Map<String, double> dailyCalories = {};

  @override
  void initState() {
    super.initState();
    _loadWeeklyLogs();
  }

  Future<void> _loadWeeklyLogs() async {
    final startStr = DateFormat("yyyy-MM-dd").format(weekStart);
    final endStr = DateFormat("yyyy-MM-dd").format(weekEnd);

    final data =
        await FoodDatabase.instance.readLogsByDateRange(startStr, endStr);

    double cals = 0, carbs = 0, protein = 0, fat = 0;
    Map<String, double> caloriesPerDay = {};

    for (var log in data) {
      cals += log.calories;
      carbs += log.carbs;
      protein += log.protein;
      fat += log.fat;

      caloriesPerDay[log.date] =
          (caloriesPerDay[log.date] ?? 0) + log.calories;
    }

    setState(() {
      logs = data;
      totalCalories = cals;
      totalCarbs = carbs;
      totalProtein = protein;
      totalFat = fat;
      dailyCalories = caloriesPerDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rangeLabel =
        "${DateFormat("MMM dd").format(weekStart)} - ${DateFormat("MMM dd").format(weekEnd)}";

    return Scaffold(
      appBar: AppBar(
        title: Text("Weekly Summary ($rangeLabel)"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _totalsCard(),
            const SizedBox(height: 16),
            _barChart(),
            const SizedBox(height: 16),
            _pieChart(),
            const SizedBox(height: 16),
            _logsList(),
          ],
        ),
      ),
    );
  }

  Widget _totalsCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("This Week's Totals",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox("Calories", totalCalories),
                _statBox("Carbs", totalCarbs),
                _statBox("Protein", totalProtein),
                _statBox("Fat", totalFat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _barChart() {
    final sortedDates = dailyCalories.keys.toList()..sort();
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Daily Calories"),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < sortedDates.length) {
                            final date = sortedDates[idx];
                            return Text(DateFormat("E").format(DateTime.parse(date)));
                          }
                          return const Text("");
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(sortedDates.length, (i) {
                    final date = sortedDates[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: dailyCalories[date] ?? 0,
                          width: 16,
                          color: Colors.green,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pieChart() {
    final total = totalCarbs + totalProtein + totalFat;
    if (total == 0) {
      return const Text("No macro data available");
    }
    return Card(
      margin: const EdgeInsets.all(12),
      child: SizedBox(
        height: 250,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: totalCarbs,
                color: Colors.orange,
                title: "Carbs ${(totalCarbs / total * 100).toStringAsFixed(0)}%",
              ),
              PieChartSectionData(
                value: totalProtein,
                color: Colors.blue,
                title:
                    "Protein ${(totalProtein / total * 100).toStringAsFixed(0)}%",
              ),
              PieChartSectionData(
                value: totalFat,
                color: Colors.red,
                title: "Fat ${(totalFat / total * 100).toStringAsFixed(0)}%",
              ),
            ],
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        ),
      ),
    );
  }

  Widget _logsList() {
    return logs.isEmpty
        ? const Center(child: Text("No logs this week"))
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text("${log.food} (${log.intake} g)"),
                subtitle: Text(
                  "${log.date} → C:${log.calories.toStringAsFixed(1)}, "
                  "Carb:${log.carbs.toStringAsFixed(1)}, "
                  "P:${log.protein.toStringAsFixed(1)}, "
                  "F:${log.fat.toStringAsFixed(1)}",
                ),
              );
            },
          );
  }

  Widget _statBox(String label, double value) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}
