import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/chartsdata.dart';

class ChartDataProvider extends ChangeNotifier {
  final List<ChartData> _hashrates = [];
  final List<ChartData> _workers = [];
  final List<ChartData> _difficulty = [];

  UnmodifiableListView<ChartData> get hashrates =>
      UnmodifiableListView(_hashrates);
  UnmodifiableListView<ChartData> get workers => UnmodifiableListView(_workers);
  UnmodifiableListView<ChartData> get difficulty =>
      UnmodifiableListView(_difficulty);

  void addChartData(List<List<int>>? charts, String chartType) {
    if (charts != null) {
      switch (chartType) {
        case 'hashrate':
          for (final chart in charts) {
            ChartData chartData = ChartData.fromList(chart);
            bool isAlreadyExist = _hashrates
                .where(
                    (element) => element.time.isAtSameMomentAs(chartData.time))
                .isNotEmpty;
            if (!isAlreadyExist) _hashrates.add(chartData);
          }
          notifyListeners();
          break;
        case 'workers':
          for (final chart in charts) {
            ChartData chartData = ChartData.fromList(chart);
            bool isAlreadyExist = _workers
                .where(
                    (element) => element.time.isAtSameMomentAs(chartData.time))
                .isNotEmpty;
            if (!isAlreadyExist) _workers.add(chartData);
          }
          notifyListeners();
          break;
        case 'difficulty':
          for (final chart in charts) {
            ChartData chartData = ChartData.fromList(chart);
            bool isAlreadyExist = _difficulty
                .where(
                    (element) => element.time.isAtSameMomentAs(chartData.time))
                .isNotEmpty;
            if (!isAlreadyExist) _difficulty.add(chartData);
          }
          notifyListeners();
          break;
      }
    }
  }
}
