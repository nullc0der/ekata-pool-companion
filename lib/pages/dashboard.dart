import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/widgets/chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/poolstat.dart';
import '../providers/chart.dart';
import '../utils/common.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({Key? key}) : super(key: key);

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  Widget _statRow(IconData icon, String title, String data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  )),
            ),
            TextSpan(
                text: title,
                style: TextStyle(color: Theme.of(context).primaryColor))
          ]),
        ),
        Text(
          data,
          style: TextStyle(color: Theme.of(context).primaryColor),
        )
      ],
    );
  }

  List<Widget> _getPoolStatRows(PoolStat? poolStat) {
    return poolStat != null
        ? [
            _StatRowItem(
                iconData: Icons.dashboard,
                title: "Hash Rate",
                data: getReadableHashrateString(
                    poolStat.pool.hashrate.toDouble())),
            _StatRowItem(
                iconData: Icons.timer,
                title: "Block Found",
                data: timeago.format(DateTime.fromMillisecondsSinceEpoch(
                    (int.tryParse(poolStat.pool.lastBlockFound) ?? 0)))),
            _StatRowItem(
                iconData: Icons.group,
                title: "Miners",
                data: poolStat.pool.miners.toString()),
            _StatRowItem(
                iconData: Icons.payments,
                title: "Total Pool Fee",
                data: poolStat.config.fee.toString() + '%'),
          ].map((item) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: _statRow(item.iconData, item.title, item.data),
            );
          }).toList()
        : [];
  }

  List<Widget> _getNetworkStatRows(PoolStat? poolStat) {
    return poolStat != null
        ? [
            _StatRowItem(
                title: 'Hash Rate',
                data: getReadableHashrateString(poolStat.network.difficulty /
                    poolStat.config.coinDifficultyTarget),
                iconData: Icons.dashboard),
            _StatRowItem(
                title: 'Block Found',
                data: timeago.format(DateTime.fromMillisecondsSinceEpoch(
                    poolStat.network.timestamp * 1000)),
                iconData: Icons.timer),
            _StatRowItem(
                title: 'Difficulty',
                data: poolStat.network.difficulty.toString(),
                iconData: Icons.lock_open),
            _StatRowItem(
                title: 'Blockchain Height',
                data: poolStat.network.height.toString(),
                iconData: Icons.table_rows),
            _StatRowItem(
                title: 'Last Reward',
                data: poolStat.network.reward.toString(),
                iconData: Icons.payments),
            _StatRowItem(
                title: 'Pool Network Share',
                data: ((poolStat.pool.hashrate /
                                (poolStat.network.difficulty /
                                    poolStat.config.coinDifficultyTarget)) *
                            100)
                        .toStringAsFixed(2) +
                    '%',
                iconData: Icons.percent),
            _StatRowItem(
                title: 'Last Hash',
                data: poolStat.network.hash
                        .substring(poolStat.network.hash.length - 10) +
                    '...',
                iconData: Icons.developer_board)
          ]
            .map((e) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _statRow(e.iconData, e.title, e.data),
                ))
            .toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    var chartsProvider = Provider.of<ChartDataProvider>(context);
    var poolStatProvider = Provider.of<PoolStatProvider>(context);

    double networkShare =
        ((poolStatProvider.poolStat?.network.difficulty ?? 0) /
            (poolStatProvider.poolStat?.config.coinDifficultyTarget ?? 0));
    double poolShare = poolStatProvider.poolStat?.pool.hashrate.toDouble() ?? 0;
    double otherSharePercent =
        ((networkShare - poolShare) / networkShare) * 100;
    double poolSharePercent = (poolShare / networkShare) * 100;
    return poolStatProvider.poolStat != null
        ? ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Container(
                margin: const EdgeInsets.only(top: 16, right: 8, left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pool Stats",
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
                    ..._getPoolStatRows(poolStatProvider.poolStat),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      "Network Stats",
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
                    ..._getNetworkStatRows(poolStatProvider.poolStat),
                    NetworkShareChart(
                        poolSharePercent: poolSharePercent,
                        otherSharePercent: otherSharePercent),
                    Chart(
                        chartData: chartsProvider.hashrates,
                        chartName: 'Hashrates'),
                    Chart(
                        chartData: chartsProvider.workers, chartName: 'Miners'),
                    Chart(
                        chartData: chartsProvider.difficulty,
                        chartName: 'Difficulty'),
                  ],
                ),
              )
            ],
          )
        : Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
  }
}

class _StatRowItem {
  _StatRowItem(
      {required this.title, required this.data, required this.iconData});
  final String title;
  final String data;
  final IconData iconData;
}
