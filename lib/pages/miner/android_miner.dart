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
import 'package:ekatapoolcompanion/utils/common.dart' as common;
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/widgets/chart.dart';
import 'package:ekatapoolcompanion/widgets/formattedlog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

class AndroidMiner extends StatefulWidget {
  const AndroidMiner(
      {Key? key,
      this.threadCount,
      required this.minerConfigPath,
      required this.setCurrentWizardStep})
      : super(key: key);

  final int? threadCount;
  final String minerConfigPath;
  final ValueChanged<WizardStep> setCurrentWizardStep;

  @override
  State<AndroidMiner> createState() => _AndroidMinerState();
}

class _AndroidMinerState extends State<AndroidMiner> {
  List<String> _minerLogs = [];
  List<ChartData> _chartDatas = [];
  static const _methodChannel =
      MethodChannel("io.ekata.ekatapoolcompanion/miner_method_channel");
  StreamSubscription<dynamic>? _minerStatusStreamSubscription;
  StreamSubscription<dynamic>? _minerLogStreamSubscription;
  final EventChannel _minerLogEventChannel =
      const EventChannel("io.ekata.ekatapoolcompanion/miner_log_channel");
  final EventChannel _minerStatusEventChannel =
      const EventChannel("io.ekata.ekatapoolcompanion/miner_event_channel");
  Timer? _minerSummaryFetchTimer;

  @override
  void initState() {
    super.initState();
    _startMinerLogStream();
    _startMinerEventStream();
    _restartMinerSummaryFetcher();
    _changeMiningCoin();
  }

  @override
  void dispose() {
    _minerLogStreamSubscription?.cancel();
    _minerStatusStreamSubscription?.cancel();
    _minerSummaryFetchTimer?.cancel();
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
        _stopMining().then((_) => _startMining());
      } else {
        _startMining();
      }
    } else {
      if (!Provider.of<MinerStatusProvider>(context, listen: false).isMining) {
        _startMining();
      } else {
        Provider.of<MinerStatusProvider>(context, listen: false)
            .sendNextHeartBeatInSeconds = Constants.initialHeartBeatInSeconds;
        _sendHeartBeat();
      }
    }
  }

  Future<bool> _startMining() async {
    final minerConfig =
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
    final coinData = getCoinDataFromMinerConfig(minerConfig);
    final threadCount =
        Provider.of<MinerStatusProvider>(context, listen: false).threadCount;
    _fetchMinerSummaryPeriodically();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance.trackEvent(
          eventCategory: 'Mining',
          action:
              'Started - ${coinData != null ? coinData.coinName : minerConfig?.pools.first.algo}');
    }
    var result = await _methodChannel.invokeMethod("startMining", {
      Constants.minerConfigPath: widget.minerConfigPath,
      Constants.threadCount: widget.threadCount,
    });
    if (result) {
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
      Provider.of<MinerStatusProvider>(context, listen: false)
          .sendNextHeartBeatInSeconds = Constants.initialHeartBeatInSeconds;
      _sendHeartBeat();
    }
    return result;
  }

  Future<bool> _stopMining() async {
    final minerConfig =
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
    final coinData = getCoinDataFromMinerConfig(minerConfig);
    _minerSummaryFetchTimer?.cancel();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance.trackEvent(
          eventCategory: 'Mining',
          action:
              'Stopped - ${coinData != null ? coinData.coinName : minerConfig?.pools.first.algo}');
    }
    var result = await _methodChannel.invokeMethod("stopMining");
    if (result) {
      Provider.of<MinerStatusProvider>(context, listen: false)
          .currentlyMiningMinerConfig = null;
      Provider.of<MinerStatusProvider>(context, listen: false)
          .currentThreadCount = null;
    }
    return result;
  }

  void _startMinerEventStream() {
    _minerStatusStreamSubscription = _minerStatusEventChannel
        .receiveBroadcastStream()
        .distinct()
        .listen((event) {
      Provider.of<MinerStatusProvider>(context, listen: false).isMining =
          event.toString() == Constants.minerProcessStarted;
      if (event.toString() != Constants.minerProcessStarted) {
        Provider.of<MinerStatusProvider>(context, listen: false)
            .currentlyMiningMinerConfig = null;
      }
    });
  }

  void _startMinerLogStream() {
    _minerLogStreamSubscription = _minerLogEventChannel
        .receiveBroadcastStream()
        .distinct()
        .listen((event) {
      List<String> minerLogs = List<String>.from(_minerLogs);
      if (minerLogs.length >= 10) {
        minerLogs = List<String>.from(minerLogs.skip(minerLogs.length - 10));
      }
      minerLogs.addAll(
          event.toString().split("\n").where((element) => element.isNotEmpty));
      setState(() {
        _minerLogs = minerLogs;
      });
    });
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

  Future<void> _sendHeartBeat() async {
    if (MatomoTracker.instance.initialized) {
      final minerStatusProvider =
          Provider.of<MinerStatusProvider>(context, listen: false);
      final minerSummary =
          Provider.of<MinerSummaryProvider>(context, listen: false)
              .minerSummary;
      final hashRate = minerSummary != null &&
              minerSummary.hashrate.total.first != null
          ? "@${getReadableHashrateString(minerSummary.hashrate.total.first!.toDouble())}"
          : "";
      Future.delayed(
          Duration(seconds: minerStatusProvider.sendNextHeartBeatInSeconds),
          () {
        if (minerStatusProvider.isMining) {
          MatomoTracker.instance.trackEvent(
              eventCategory: "Mining",
              action: "Heartbeat"
                  " - ${minerStatusProvider.currentlyMiningMinerConfig?.pools.first.url}"
                  "(${minerStatusProvider.currentlyMiningMinerConfig?.pools.first.algo})"
                  "$hashRate");
          minerStatusProvider.sendNextHeartBeatInSeconds *= 2;
          _sendHeartBeat();
        }
      });
    }
  }

  Widget _showStartStopMining({bool isStarted = false}) {
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
            value: isStarted,
            onChanged: (_) => {!isStarted ? _startMining() : _stopMining()},
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        isStarted
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
          color: Colors.black, borderRadius: BorderRadius.circular(6)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _minerLogs.isNotEmpty
              ? _minerLogs
                  .map((e) => FormattedLog(logTexts: common.formatLogs(e)))
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
                  child: _showStartStopMining(isStarted: isMining)),
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
