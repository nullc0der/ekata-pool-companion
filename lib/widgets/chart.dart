import 'package:ekatapoolcompanion/models/chartsdata.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Chart extends StatelessWidget {
  const Chart({Key? key, required this.chartData, required this.chartName})
      : super(key: key);
  final List<ChartData> chartData;
  final String chartName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chartName,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor),
          ),
          SizedBox(
            width: 80,
            child: Divider(
              color: Theme.of(context).primaryColor,
              thickness: 2,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          AspectRatio(
            aspectRatio: 2.5,
            child: LineChart(LineChartData(
                lineBarsData: [
                  LineChartBarData(
                      spots: chartData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                              e.key.toDouble(), e.value.value.toDouble()))
                          .toList(),
                      isCurved: false,
                      dotData: FlDotData(show: false),
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                          show: true,
                          gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF233349), Color(0xFF526174)]))),
                ],
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 20.0,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map(
                            (LineBarSpot touchedSpot) {
                              const textStyle = TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              );
                              return LineTooltipItem(
                                '${DateFormat.yMd().add_jm().format(chartData[touchedSpot.spotIndex].time)}: ${chartData[touchedSpot.spotIndex].value.toString()}',
                                textStyle,
                              );
                            },
                          ).toList();
                        })))),
          )
        ],
      ),
    );
  }
}
