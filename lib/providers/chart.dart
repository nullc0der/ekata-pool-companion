import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/chartsdata.dart';

class ChartDataProvider extends ChangeNotifier {
  List<ChartData> _hashrates = [];
  List<ChartData> _workers = [];
  List<ChartData> _difficulty = [];

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
            if (!isAlreadyExist) {
              if (_hashrates.length >= 20) {
                _hashrates = List.from(_hashrates.skip(_hashrates.length - 20));
              }
              _hashrates.add(chartData);
            }
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
            if (!isAlreadyExist) {
              if (_workers.length >= 20) {
                _workers = List.from(_workers.skip(_workers.length - 20));
              }
              _workers.add(chartData);
            }
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
            if (!isAlreadyExist) {
              if (_difficulty.length >= 20) {
                _difficulty =
                    List.from(_difficulty.skip(_difficulty.length - 20));
              }
              _difficulty.add(chartData);
            }
          }
          notifyListeners();
          break;
      }
    }
  }
}
