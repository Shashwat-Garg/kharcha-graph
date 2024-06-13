import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kharcha_graph/models/transaction_info.dart';

class VisualizeTab extends StatelessWidget {
  final List<TransactionInfo> _transactionsList;

  const VisualizeTab({super.key, required List<TransactionInfo> transactions}): _transactionsList = transactions;
  
  Map<String, double> _getCategoryToAmountMap() {
    Map<String, double> categoryToAmount = {};
    for (TransactionInfo transactionInfo in _transactionsList) {
      if (transactionInfo.category != null && transactionInfo.category!.isNotEmpty) {
        categoryToAmount.putIfAbsent(transactionInfo.category!, () => 0);
        categoryToAmount[transactionInfo.category!] = categoryToAmount[transactionInfo.category!]! + transactionInfo.amount;
      }
    }

    return categoryToAmount;
  }

  double _getMaxHeight(Iterable<double> heights) {
    double maxHeight = 0;
    for (double height in heights) {
      maxHeight = max(height, maxHeight);
    }

    // Increase the height to a little more than the max height of a bar
    // This will help with better visualization
    return maxHeight * 1.2;
  }

  List<BarChartGroupData> _getBarChartGroupsData(Map<String, double> categoryToMap, List<String> categories) {
    List<BarChartGroupData> barChartGroups = [];
    for (int i = 0; i < categories.length; i++) {
      barChartGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: categoryToMap[categories[i]]!
            ),
          ],
          showingTooltipIndicators: [0]
        )
      );
    }

    return barChartGroups;
  }

  String _getTooltipText(double amount) {
    return 'Rs.${amount.toStringAsFixed(2)}';
  }

  BarTouchData _getBarTouchData(List<String> categories, Map<String, double> categoryToAmount) {
    return BarTouchData(
      enabled: false,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Colors.transparent,
        tooltipMargin: 2,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          String category = categories[groupIndex];
          return BarTooltipItem(
            _getTooltipText(categoryToAmount[category]!),
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)
          );
        }
      )
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta, List<String> categories) {
    return SideTitleWidget(
      angle: - pi / 6,
      axisSide: meta.axisSide,
      child: Text(
        categories[value.toInt()],
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  BarChartData _getBarChartData() {
    Map<String, double> categoryToAmount = _getCategoryToAmountMap();
    List<String> categories = categoryToAmount.keys.toList();
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _getMaxHeight(categoryToAmount.values),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false)
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false)
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false)
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, categories)
          )
        ),
      ),
      borderData: FlBorderData(
        show: false
      ),
      gridData: const FlGridData(
        show: false
      ),
      barGroups: _getBarChartGroupsData(categoryToAmount, categories),
      barTouchData: _getBarTouchData(categories, categoryToAmount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
      child: BarChart(
        _getBarChartData()
      )
    );
  }
}