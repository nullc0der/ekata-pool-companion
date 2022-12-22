import 'dart:async';
import 'dart:io';

import 'package:ekatapoolcompanion/models/chartsdata.dart';
import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/models/minersummary.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/providers/minersummary.dart';
import 'package:ekatapoolcompanion/services/minersummary.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/widgets/chart.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

class DesktopMiner extends StatefulWidget {
  const DesktopMiner(
      {Key? key,
      this.threadCount,
      required this.minerConfigPath,
      required this.setCurrentWizardStep})
      : super(key: key);

  final int? threadCount;
  final String minerConfigPath;
  final ValueChanged<WizardStep> setCurrentWizardStep;

  @override
  State<DesktopMiner> createState() => _DesktopMinerState();
}

class _DesktopMinerState extends State<DesktopMiner> {
  List<String> _currentMinerLog = [];
  List<ChartData> _chartDatas = [];
  Timer? _minerSummaryFetchTimer;
  StreamSubscription<dynamic>? _minerLogStreamSubscription;

  @override
  void initState() {
    super.initState();
    DesktopMinerUtil.instance.initialize(
      minerConfigPath: widget.minerConfigPath,
      threadCount: widget.threadCount,
    );
    _startMinerLogSubscription();
    _restartMinerSummaryFetcher();
    _changeMiningCoin();
  }

  @override
  void dispose() {
    _minerSummaryFetchTimer?.cancel();
    _minerLogStreamSubscription?.cancel();
    DesktopMinerUtil.instance.clean();
    super.dispose();
  }

  _changeMiningCoin() {
    final currentlyMiningMinerConfig =
        Provider.of<MinerStatusProvider>(context, listen: false)
            .currentlyMiningMinerConfig;
    final minerConfig =
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
    final threadCount =
        Provider.of<MinerStatusProvider>(context, listen: false).threadCount;
    final currentThreadCount =
        Provider.of<MinerStatusProvider>(context, listen: false)
            .currentThreadCount;
    if (currentlyMiningMinerConfig != minerConfig ||
        threadCount != currentThreadCount) {
      if (Provider.of<MinerStatusProvider>(context, listen: false).isMining) {
        _stopMining();
        _startMining();
      } else {
        _startMining();
      }
    } else {
      if (!Provider.of<MinerStatusProvider>(context, listen: false).isMining) {
        _startMining();
      }
    }
  }

  void _startMining() {
    final minerConfig =
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
    final threadCount =
        Provider.of<MinerStatusProvider>(context, listen: false).threadCount;
    final coinData = getCoinDataFromMinerConfig(minerConfig);
    if (DesktopMinerUtil.instance.initialized) {
      DesktopMinerUtil.instance.startMining().then((value) {
        _fetchMinerSummaryPeriodically();
        if (MatomoTracker.instance.initialized) {
          MatomoTracker.instance.trackEvent(
              eventCategory: 'Mining',
              action:
                  'Started - ${coinData != null ? coinData.coinName : minerConfig?.pools.first.algo}');
        }
        Provider.of<MinerStatusProvider>(context, listen: false).isMining =
            value;
        _startMinerLogSubscription();
        File(widget.minerConfigPath).readAsString().then((value) {
          try {
            Provider.of<MinerStatusProvider>(context, listen: false)
                .currentlyMiningMinerConfig = minerConfigFromJson(value);
          } on FormatException catch (_) {}
        });
        Provider.of<MinerStatusProvider>(context, listen: false)
            .currentThreadCount = threadCount;
        Provider.of<MinerSummaryProvider>(context, listen: false).minerSummary =
            null;
      });
    }
  }

  void _stopMining() {
    if (DesktopMinerUtil.instance.initialized) {
      bool stopped = DesktopMinerUtil.instance.stopMining();
      if (stopped) {
        final minerConfig =
            Provider.of<MinerStatusProvider>(context, listen: false)
                .minerConfig;
        final coinData = getCoinDataFromMinerConfig(minerConfig);
        _minerSummaryFetchTimer?.cancel();
        if (MatomoTracker.instance.initialized) {
          MatomoTracker.instance.trackEvent(
              eventCategory: 'Mining',
              action:
                  'Stopped - ${coinData != null ? coinData.coinName : minerConfig?.pools.first.algo}');
        }
        Provider.of<MinerStatusProvider>(context, listen: false).isMining =
            false;
        Provider.of<MinerStatusProvider>(context, listen: false)
            .currentlyMiningMinerConfig = null;
        Provider.of<MinerStatusProvider>(context, listen: false)
            .currentThreadCount = null;
      }
    }
  }

  void _fetchMinerSummaryPeriodically() {
    _minerSummaryFetchTimer?.cancel();
    _minerSummaryFetchTimer =
        Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        MinerSummary _minerSummary =
            await MinerSummaryService().getMinerSummary();
        Provider.of<MinerSummaryProvider>(context, listen: false).minerSummary =
            _minerSummary;
        var chartDatas = List<ChartData>.from(_chartDatas);
        if (chartDatas.length >= 20) {
          chartDatas =
              List<ChartData>.from(chartDatas.skip(chartDatas.length - 20));
        }
        chartDatas.add(ChartData(
            time: DateTime.now(),
            value: _minerSummary.hashrate.total[0] != null
                ? _minerSummary.hashrate.total[0]!.toInt()
                : 0));
        setState(() {
          _chartDatas = chartDatas;
        });
      } on Exception {
        bool hasMinerSummary =
            Provider.of<MinerSummaryProvider>(context, listen: false)
                    .minerSummary !=
                null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: hasMinerSummary
                ? const Text(
                    "There is some issue updating miner summary, will retry")
                : const Text(
                    "There is some issue fetching miner summary, will retry")));
      }
    });
  }

  // When this widget is disposed the miner summary fetch timer is cancelled,
  // restart timer if miner is running
  void _restartMinerSummaryFetcher() {
    if (Provider.of<MinerStatusProvider>(context, listen: false).isMining &&
        _minerSummaryFetchTimer == null) {
      _fetchMinerSummaryPeriodically();
    }
  }

  void _startMinerLogSubscription() {
    _minerLogStreamSubscription?.cancel();
    if (DesktopMinerUtil.instance.initialized) {
      _minerLogStreamSubscription =
          DesktopMinerUtil.instance.logStream.distinct().listen((event) {
        List<String> currentMinerLog = List<String>.from(_currentMinerLog);
        if (currentMinerLog.length >= 10) {
          currentMinerLog = List<String>.from(
              currentMinerLog.skip(currentMinerLog.length - 10));
        }
        currentMinerLog.addAll(event
            .toString()
            .split("\n")
            .where((element) => element.isNotEmpty));
        setState(() {
          _currentMinerLog = currentMinerLog;
        });
      });
    }
  }

  Widget _showStartStopMining({bool isMining = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 16,
        ),
        Transform.scale(
          scale: 2,
          child: Switch(
            activeColor: Colors.green,
            activeTrackColor: Colors.green.withOpacity(0.4),
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.withOpacity(0.4),
            activeThumbImage: const AssetImage("assets/images/power.png"),
            inactiveThumbImage: const AssetImage("assets/images/power.png"),
            value: isMining,
            onChanged: (_) => {!isMining ? _startMining() : _stopMining()},
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        isMining
            ? Text(
                "Mining Started",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold),
              )
            : Text(
                "Mining Stopped",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold),
              )
      ],
    );
  }

  Widget _minerLogsContainer() {
    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.black12, borderRadius: BorderRadius.circular(6)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _currentMinerLog.isNotEmpty
              ? _currentMinerLog
                  .map((e) => Text(
                        e,
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ))
                  .toList()
              : [
                  Text("Log will appear here once mining starts",
                      style: TextStyle(color: Theme.of(context).primaryColor))
                ]),
    );
  }

  Widget _summaryRow(IconData icon, String title, String data) {
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

  List<Widget> _minerSummaries(MinerSummary? minerSummary) {
    return minerSummary != null
        ? [
            _MinerSummaryItem(
                title: "Uptime",
                data: timeStringFromSecond(minerSummary.uptime),
                iconData: Icons.timer),
            _MinerSummaryItem(
                title: "Algo",
                data: minerSummary.algo,
                iconData: Icons.terminal),
            _MinerSummaryItem(
                title: "CPU brand",
                data: minerSummary.cpu.brand,
                iconData: Icons.developer_board),
            _MinerSummaryItem(
                title: "Connected Pool",
                data: minerSummary.connection.pool,
                iconData: Icons.group),
            _MinerSummaryItem(
                title: "Memory (Free/Total)",
                data:
                    "${convertByteToGB(minerSummary.resources.memory.free)}/${convertByteToGB(minerSummary.resources.memory.total)}",
                iconData: Icons.memory),
            _MinerSummaryItem(
                title: "Share submitted (Good/Total)",
                data:
                    "${minerSummary.results.sharesGood}/${minerSummary.results.sharesTotal}",
                iconData: Icons.percent),
            _MinerSummaryItem(
                title: "Hashrate",
                data: getReadableHashrateString(
                    minerSummary.hashrate.total[0] != null
                        ? minerSummary.hashrate.total[0]!.toDouble()
                        : 0),
                iconData: Icons.developer_board)
          ].map((e) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: _summaryRow(e.iconData, e.title, e.data),
            );
          }).toList()
        : [];
  }

  @override
  Widget build(BuildContext context) {
    var minerSummary = Provider.of<MinerSummaryProvider>(context).minerSummary;
    var isMining = Provider.of<MinerStatusProvider>(context).isMining;

    final minerConfig = Provider.of<MinerStatusProvider>(context).minerConfig;
    final coinData = getCoinDataFromMinerConfig(minerConfig);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (minerConfig != null)
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      if (coinData != null) ...[
                        Text("Currently Mining: ${coinData.coinName}"),
                        const SizedBox(
                          width: 8,
                        ),
                        Image(
                          image: AssetImage(coinData.coinLogoPath),
                          width: 24,
                          height: 24,
                        ),
                      ] else
                        Text(
                            "Currently Mining: ${minerConfig.pools.first.algo}"),
                      const Spacer(),
                      OutlinedButton(
                          onPressed: () {
                            Provider.of<MinerStatusProvider>(context,
                                    listen: false)
                                .minerConfig = null;
                            widget.setCurrentWizardStep(
                                WizardStep.coinNameSelect);
                          },
                          child: const Text("Mine Another"))
                    ],
                  ),
                ),
              const SizedBox(
                height: 16,
              ),
              SizedBox(
                  width: double.infinity,
                  child: _showStartStopMining(isMining: isMining)),
              if (minerSummary != null) ...[
                const SizedBox(
                  height: 8,
                ),
                Text(
                  "Miner Summary",
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
                ..._minerSummaries(minerSummary),
              ],
              if (_chartDatas.isNotEmpty)
                Chart(
                  chartData: _chartDatas,
                  chartName: "Hashrate",
                ),
              if (isMining) ...[
                const SizedBox(
                  height: 16,
                ),
                Text(
                  "Miner log",
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
                _minerLogsContainer()
              ],
            ],
          ),
        )
      ],
    );
  }
}

class _MinerSummaryItem {
  _MinerSummaryItem(
      {required this.title, required this.data, required this.iconData});

  final String title;
  final String data;
  final IconData iconData;
}
