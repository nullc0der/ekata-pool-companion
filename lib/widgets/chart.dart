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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(
            width: 80,
            child: Divider(
              thickness: 2,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          AspectRatio(
            aspectRatio: 2.5,
            child: LineChart(
              LineChartData(
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
                        barWidth: 1,
                        belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [
                                  0.5,
                                  1.0
                                ],
                                colors: [
                                  Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.8),
                                  Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5)
                                ]))),
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
                          }))),
              swapAnimationDuration: Duration.zero,
            ),
          )
        ],
      ),
    );
  }
}

class NetworkShareChart extends StatefulWidget {
  const NetworkShareChart(
      {Key? key,
      required this.poolSharePercent,
      required this.otherSharePercent})
      : super(key: key);

  final double poolSharePercent;
  final double otherSharePercent;

  @override
  State<NetworkShareChart> createState() => _NetworkShareChartState();
}

class _NetworkShareChartState extends State<NetworkShareChart> {
  int touchedIndex = -1;

  List<PieChartSectionData> showingSections() {
    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xff273951),
            value: widget.poolSharePercent,
            title: '${widget.poolSharePercent.toStringAsFixed(2)}%',
            radius: radius,
            titleStyle: const TextStyle(fontSize: 12, color: Color(0xffffffff)),
          );
        case 1:
          return PieChartSectionData(
            color: const Color(0xffb0c1d8),
            value: widget.otherSharePercent,
            title: '${widget.otherSharePercent.toStringAsFixed(2)}%',
            radius: radius,
            titleStyle: const TextStyle(fontSize: 12, color: Color(0xff273951)),
          );
        default:
          throw Error();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "Network Share",
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
          height: 32,
        ),
        Row(
          children: [
            Expanded(
                child: AspectRatio(
              aspectRatio: 2.5,
              child: PieChart(
                PieChartData(
                    pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    }),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: showingSections()),
              ),
            )),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Indicator(
                  color: Color(0xff273951),
                  text: 'Our Pool',
                  isSquare: true,
                ),
                SizedBox(
                  height: 4,
                ),
                Indicator(
                  color: Color(0xffb0c1d8),
                  text: 'Other',
                  isSquare: true,
                ),
                SizedBox(
                  height: 4,
                )
              ],
            )
          ],
        ),
        const SizedBox(
          height: 16,
        )
      ]),
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  const Indicator({
    Key? key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor = const Color(0xff505050),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(fontSize: 16, color: textColor),
        )
      ],
    );
  }
}
