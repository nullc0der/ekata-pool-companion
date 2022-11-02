import 'dart:async';

import 'package:ekatapoolcompanion/models/chartsdata.dart';
import 'package:ekatapoolcompanion/models/minersummary.dart';
import 'package:ekatapoolcompanion/providers/MinerStatus.dart';
import 'package:ekatapoolcompanion/providers/minersummary.dart';
import 'package:ekatapoolcompanion/services/minersummary.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/widgets/chart.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DesktopMiner extends StatefulWidget {
  const DesktopMiner({Key? key}) : super(key: key);

  @override
  State<DesktopMiner> createState() => _DesktopMinerState();
}

class _DesktopMinerState extends State<DesktopMiner> {
  String _walletAddress = "";
  String _currentMinerLog = "";
  List<ChartData> _chartDatas = [];
  Timer? _minerSummaryFetchTimer;
  StreamSubscription<dynamic>? _minerLogStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadWalletAddress().then((_) => _startMinerLogSubscription());
    _restartMinerSummaryFetcher();
  }

  @override
  void dispose() {
    _minerSummaryFetchTimer?.cancel();
    _minerLogStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadWalletAddress() async {
    final prefs = await SharedPreferences.getInstance();
    String walletAddress =
        prefs.getString(Constants.walletAddressKeySharedPrefs) ?? "";
    if (walletAddress.isNotEmpty && !DesktopMinerUtil.instance.initialized) {
      DesktopMinerUtil.instance.initialize(minerAddress: walletAddress);
    }
    setState(() {
      _walletAddress = walletAddress;
    });
  }

  void _fetchMinerSummaryPeriodically() {
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

  void _startMinerLogSubscription() {
    _minerLogStreamSubscription?.cancel();
    if (DesktopMinerUtil.instance.initialized) {
      _minerLogStreamSubscription =
          DesktopMinerUtil.instance.logStream.distinct().listen((event) {
        setState(() {
          _currentMinerLog = event.toString();
        });
      });
    }
  }

  Widget _showStartStopMining({bool isMining = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            if (!isMining) {
              if (DesktopMinerUtil.instance.initialized) {
                DesktopMinerUtil.instance.startMining().then((value) {
                  _fetchMinerSummaryPeriodically();
                  if (MatomoTracker.instance.initialized) {
                    MatomoTracker.instance
                        .trackEvent(eventCategory: 'Mining', action: 'Started');
                  }
                  Provider.of<MinerStatusProvider>(context, listen: false)
                      .isMining = value;
                  _startMinerLogSubscription();
                });
              }
            } else {
              if (DesktopMinerUtil.instance.initialized) {
                bool stopped = DesktopMinerUtil.instance.stopMining();
                if (stopped) {
                  _minerSummaryFetchTimer?.cancel();
                  if (MatomoTracker.instance.initialized) {
                    MatomoTracker.instance
                        .trackEvent(eventCategory: 'Mining', action: 'Stopped');
                  }
                  Provider.of<MinerStatusProvider>(context, listen: false)
                      .isMining = false;
                }
              }
            }
          },
          child: isMining
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
              ? [
                  Text(
                    _currentMinerLog,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  )
                ]
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
    return _walletAddress.isNotEmpty
        ? Expanded(
            child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
          ))
        : const Center(
            child: Text("You need a wallet address first to mine"),
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
