import 'dart:async';

import 'package:ekatapoolcompanion/models/chartsdata.dart';
import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/models/minersummary.dart';
import 'package:ekatapoolcompanion/providers/MinerStatus.dart';
import 'package:ekatapoolcompanion/providers/minersummary.dart';
import 'package:ekatapoolcompanion/services/minersummary.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/widgets/chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

class AndroidMiner extends StatefulWidget {
  const AndroidMiner(
      {Key? key, required this.coinData, required this.walletAddress})
      : super(key: key);

  final CoinData coinData;
  final String walletAddress;

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
    var currentlyMining =
        Provider.of<MinerStatusProvider>(context, listen: false)
            .currentlyMining;
    if (currentlyMining["coinData"] != widget.coinData) {
      if (Provider.of<MinerStatusProvider>(context, listen: false).isMining) {
        _stopMining().then((_) => _startMining());
      } else {
        _startMining();
      }
    } else {
      if (!Provider.of<MinerStatusProvider>(context, listen: false).isMining) {
        _startMining();
      }
    }
  }

  Future<bool> _startMining() async {
    _fetchMinerSummaryPeriodically();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance.trackEvent(
          eventCategory: 'Mining',
          action: 'Started - ${widget.coinData.coinName}');
    }
    var result = await _methodChannel.invokeMethod("startMining", {
      Constants.walletAddress: widget.walletAddress,
      Constants.coinAlgo: widget.coinData.coinAlgo,
      Constants.poolHost: widget.coinData.poolAddress,
      Constants.poolPort: widget.coinData.poolPort
    });
    if (result) {
      Provider.of<MinerStatusProvider>(context, listen: false).currentlyMining =
          {"coinData": widget.coinData, "walletAddress": widget.walletAddress};
      Provider.of<MinerSummaryProvider>(context, listen: false).minerSummary =
          null;
    }
    return result;
  }

  Future<bool> _stopMining() async {
    _minerSummaryFetchTimer?.cancel();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance.trackEvent(
          eventCategory: 'Mining',
          action: 'Stopped - ${widget.coinData.coinName}');
    }
    var result = await _methodChannel.invokeMethod("stopMining");
    if (result) {
      Provider.of<MinerStatusProvider>(context, listen: false).currentlyMining =
          {"coinData": null, "walletAddress": ""};
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
    });
  }

  void _startMinerLogStream() {
    _minerLogStreamSubscription = _minerLogEventChannel
        .receiveBroadcastStream()
        .distinct()
        .listen((event) {
      List<String> minerLogs = [..._minerLogs];
      if (minerLogs.length >= 10) {
        minerLogs[minerLogs.length - 1] = event.toString();
      } else {
        minerLogs.add(event.toString());
      }
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
        setState(() {
          _chartDatas = [
            ..._chartDatas,
            ChartData(
                time: DateTime.now(),
                value: _minerSummary.hashrate.total[0] != null
                    ? _minerSummary.hashrate.total[0]!.toInt()
                    : 0)
          ];
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

  Widget _showStartStopMining({bool isStarted = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (!isStarted) {
              _startMining();
            } else {
              _stopMining();
            }
          },
          child: isStarted
              ? Icon(
                  Icons.power_settings_new,
                  size: 96,
                  color: Colors.green.shade800,
                )
              : Icon(
                  Icons.power_settings_new,
                  size: 96,
                  color: Colors.red.shade800,
                ),
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
          color: Colors.black12, borderRadius: BorderRadius.circular(6)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _minerLogs.isNotEmpty
              ? _minerLogs
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
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Text("Currently Mining: ${widget.coinData.coinName}"),
                    const SizedBox(
                      width: 8,
                    ),
                    Image(
                      image: AssetImage(widget.coinData.coinLogoPath),
                      width: 24,
                      height: 24,
                    ),
                    const Spacer(),
                    OutlinedButton(
                        onPressed: () {
                          Provider.of<MinerStatusProvider>(context,
                                  listen: false)
                              .coinData = null;
                          Provider.of<MinerStatusProvider>(context,
                                  listen: false)
                              .walletAddress = "";
                          Provider.of<MinerStatusProvider>(context,
                                  listen: false)
                              .showMinerScreen = false;
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
