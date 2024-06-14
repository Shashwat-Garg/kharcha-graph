import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kharcha_graph/models/transaction_info.dart';
import 'package:kharcha_graph/util/common.dart';

class VisualizeTabLineChart extends StatelessWidget {
  final List<TransactionInfo> _transactionsList;

  const VisualizeTabLineChart({super.key, required List<TransactionInfo> transactions}) : _transactionsList = transactions;

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

  Map<String, Color> _getCategoryToColorMap(Iterable<String> categories) {
    Map<String, Color> categoryToColorMap = {};
    for (String category in categories) {
      categoryToColorMap.putIfAbsent(category, () => Colors.primaries[Random().nextInt(Colors.primaries.length)]);
    }

    return categoryToColorMap;
  }

  double _getMaxHeight(Iterable<double> heights) {
    double maxHeight = 0;
    for (double height in heights) {
      maxHeight = max(height, maxHeight);
    }

    // Increase the height to a little more than the max height of a value
    // This will help with better visualization
    return maxHeight * 1.2;
  }

  String _getTooltipText(double amount) {
    return 'Rs.${amount.toStringAsFixed(2)}';
  }

  LineTouchData _getLineTouchData(List<String> categories, Map<String, Color> categoryToColor) {
    return LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.8),
        tooltipMargin: 2,
        fitInsideVertically: true,
        getTooltipItems: (lineBarSpots) {
          return lineBarSpots.map((lineBarSpot) {
            return LineTooltipItem(
              _getTooltipText(lineBarSpot.y),
              TextStyle(color: categoryToColor[categories[lineBarSpot.barIndex]])
            );
          }).toList();
        }
      )
    );
  }

  Widget _getBottomTitlesWidget(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        getMonthShortHandByIndex(value.toInt()),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _getLeftTitlesWidget(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        'Rs.${value.toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 9),
      ),
    );
  }

  FlTitlesData _getTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: _getBottomTitlesWidget,
        ),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      leftTitles: AxisTitles(
        axisNameWidget: const Text(r'Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: _getLeftTitlesWidget,
          reservedSize: 55
        ),
      ),
    );
  }

  LineChartBarData _getLineChartBarData(String category, Color color) {
    List<double> monthToAmountList = List.filled(13, 0);

    for (TransactionInfo transaction in _transactionsList) {
      if (transaction.category != null && transaction.category! == category) {
        monthToAmountList[transaction.date.month] += transaction.amount;
      }
    }

    return LineChartBarData(
      dotData: const FlDotData(show: false),
      color: color,
      spots: [
        for (int i = 1; i <= 12; i++) FlSpot(i.toDouble(), monthToAmountList[i])
      ]
    );
  }

  LineChartData _getLineChartData(Map<String, double> categoryToAmount, Map<String, Color> categoryToColor) {
    return LineChartData(
      maxY: _getMaxHeight(categoryToAmount.values),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      lineTouchData: _getLineTouchData(categoryToAmount.keys.toList(), categoryToColor),
      titlesData: _getTitlesData(),
      lineBarsData: [
        for (String category in categoryToAmount.keys) _getLineChartBarData(category, categoryToColor[category]!)
      ],
    );
  }

  Widget _getLegendWidget(Map<String, Color> categoryToColor) {
    return Positioned(
      top: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            for (String category in categoryToColor.keys) Text(category, style: TextStyle(color: categoryToColor[category]))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> categoryToAmount = _getCategoryToAmountMap();
    Map<String, Color> categoryToColor = _getCategoryToColorMap(categoryToAmount.keys);
    return Container(
      margin: const EdgeInsets.all(20),
      child: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                _getLegendWidget(categoryToColor),
                LineChart(
                  _getLineChartData(categoryToAmount, categoryToColor)
                )
              ]
            )
          ),
          const Expanded(
            flex: 1,
            child: Text(r'Coming soon modifiers')
          )
        ],
      ),
    );
  }
}