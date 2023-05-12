import 'dart:async';
import 'dart:io';

import 'package:ekatapoolcompanion/models/ccminersummary.dart';
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
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/widgets/chart.dart';
import 'package:ekatapoolcompanion/widgets/formattedlog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

class AndroidMiner extends StatefulWidget {
  const AndroidMiner({Key? key, required this.setCurrentWizardStep})
      : super(key: key);

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
    final minerStatusProvider =
        Provider.of<MinerStatusProvider>(context, listen: false);
    if (minerStatusProvider.currentlyMiningMinerConfig !=
            minerStatusProvider.minerConfig ||
        minerStatusProvider.threadCount !=
            minerStatusProvider.currentThreadCount ||
        minerStatusProvider.selectedMinerBinary !=
            minerStatusProvider.currentMinerBinary) {
      if (minerStatusProvider.isMining) {
        _stopMining().then((_) => _startMining());
      } else {
        _startMining();
      }
    } else {
      if (!minerStatusProvider.isMining) {
        _startMining();
      } else {
        _sendHeartBeat();
      }
    }
  }

  Future<bool> _startMining() async {
    final minerStatusProvider =
        Provider.of<MinerStatusProvider>(context, listen: false);
    final coinData = minerStatusProvider.coinData;
    _fetchMinerSummaryPeriodically();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance.trackEvent(
          eventCategory: 'Mining',
          action:
              'Started - ${coinData != null ? coinData.coinName : minerStatusProvider.minerConfig?.pools.first.algo}');
    }
    var result = await _methodChannel.invokeMethod("startMining", {
      Constants.minerConfigPath: minerStatusProvider.minerConfigPath,
      Constants.threadCount: minerStatusProvider.threadCount,
      Constants.minerBinary: minerStatusProvider.selectedMinerBinary.name,
      Constants.xmrigCCServerUrl: minerStatusProvider.xmrigCCServerUrl,
      Constants.xmrigCCServerToken: minerStatusProvider.xmrigCCServerToken,
      Constants.xmrigCCWorkerId: minerStatusProvider.xmrigCCWorkerId,
      Constants.ccMinerBinaryVariant:
          minerStatusProvider.minerConfig?.pools.first.algo == "verus"
              ? "ccminer-verus"
              : "ccminer",
      Constants.ccMinerAlgo: minerStatusProvider.minerConfig?.pools.first.algo,
      Constants.ccMinerPoolUrl:
          minerStatusProvider.minerConfig?.pools.first.url,
      Constants.ccMinerUsername:
          minerStatusProvider.minerConfig?.pools.first.user,
      Constants.ccMinerRigId:
          minerStatusProvider.minerConfig?.pools.first.rigId,
      Constants.ccMinerPassword:
          minerStatusProvider.minerConfig?.pools.first.pass,
    });
    if (result) {
      File(minerStatusProvider.minerConfigPath!).readAsString().then((value) {
        try {
          Provider.of<MinerStatusProvider>(context, listen: false)
                  .currentlyMiningMinerConfig =
              minerConfigFromJson(
                  value, minerStatusProvider.selectedMinerBinary);
        } on FormatException catch (_) {}
      });
      Provider.of<MinerStatusProvider>(context, listen: false)
          .currentThreadCount = minerStatusProvider.threadCount;
      Provider.of<MinerSummaryProvider>(context, listen: false).minerSummary =
          null;
      Provider.of<MinerStatusProvider>(context, listen: false)
          .sendNextHeartBeatInSeconds = Constants.initialHeartBeatInSeconds;
      Provider.of<MinerStatusProvider>(context, listen: false)
          .currentMinerBinary = minerStatusProvider.selectedMinerBinary;
      _sendHeartBeat();
    }
    return result;
  }

  Future<bool> _stopMining() async {
    final minerConfig =
        Provider.of<MinerStatusProvider>(context, listen: false).minerConfig;
    final coinData =
        Provider.of<MinerStatusProvider>(context, listen: false).coinData;
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
      Provider.of<MinerStatusProvider>(context, listen: false)
          .currentMinerBinary = null;
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
      // NOTE: Maybe cleanup other provider data too which are cleaned up in
      // _stopMining
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

  void _processCCMinerData(CCMinerSummary ccMinerSummary) {
    Provider.of<MinerSummaryProvider>(context, listen: false).ccMinerSummary =
        ccMinerSummary;
    var chartDatas = List<ChartData>.from(_chartDatas);
    if (chartDatas.length >= 20) {
      chartDatas =
          List<ChartData>.from(chartDatas.skip(chartDatas.length - 20));
    }
    chartDatas.add(ChartData(
        time: DateTime.now(),
        value: (double.tryParse(ccMinerSummary.currentHash) ?? 0).toInt()));
    setState(() {
      _chartDatas = chartDatas;
    });
  }

  Future<void> _fetchAndProcessXmrigMinerData() async {
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
  }

  Future<void> _fetchCCMinerData() async {
    await CCMinerSummaryService.instance.getSummary(_processCCMinerData);
  }

  void _fetchMinerSummaryPeriodically() {
    _minerSummaryFetchTimer?.cancel();
    _minerSummaryFetchTimer =
        Timer.periodic(const Duration(seconds: 10), (_) async {
      Provider.of<MinerStatusProvider>(context, listen: false)
                  .currentMinerBinary ==
              MinerBinary.ccminer
          ? await _fetchCCMinerData()
          : await _fetchAndProcessXmrigMinerData();
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
            thumbIcon: MaterialStateProperty.resolveWith<Icon?>((states) {
              return const Icon(Icons.power_settings_new);
            }),
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
              : [const Text("Log will appear here once mining starts")]),
    );
  }

  Widget _summaryRow(IconData icon, String title, String data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
            ),
            const SizedBox(
              width: 4,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(
              width: 4,
            ),
          ],
        ),
        Flexible(
            child: Text(
          data,
          style: Theme.of(context).textTheme.labelSmall,
        ))
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

  List<Widget> _ccMinerSummaries(CCMinerSummary? ccMinerSummary) {
    return ccMinerSummary != null
        ? [
            _MinerSummaryItem(
                title: "Algo",
                data: ccMinerSummary.algo,
                iconData: Icons.terminal),
            _MinerSummaryItem(
                title: "Hashrate",
                data: "${ccMinerSummary.currentHash} kH/s",
                iconData: Icons.developer_board),
            _MinerSummaryItem(
                title: "Solved",
                data: ccMinerSummary.solved,
                iconData: Icons.calculate),
            _MinerSummaryItem(
                title: "Accepted",
                data: ccMinerSummary.accepted,
                iconData: Icons.check_box),
            _MinerSummaryItem(
                title: "Rejected",
                data: ccMinerSummary.rejected,
                iconData: Icons.cancel_outlined),
            _MinerSummaryItem(
                title: "Difficulty",
                data: (double.tryParse(ccMinerSummary.diff) ?? 0)
                    .toInt()
                    .toString(),
                iconData: Icons.show_chart),
            _MinerSummaryItem(
                title: "Uptime",
                data: timeStringFromSecond(
                    int.tryParse(ccMinerSummary.uptime) ?? 0),
                iconData: Icons.timer),
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
    final minerSummaryProvider = Provider.of<MinerSummaryProvider>(context);
    final minerStatusProvider = Provider.of<MinerStatusProvider>(context);

    final minerSummary = minerSummaryProvider.minerSummary;
    final ccMinerSummary = minerSummaryProvider.ccMinerSummary;

    final isMining = minerStatusProvider.isMining;
    final minerConfig = minerStatusProvider.minerConfig;
    final selectedMinerBinary = minerStatusProvider.selectedMinerBinary;
    final coinData = minerStatusProvider.coinData;
    final xmrigCCServerUrl = minerStatusProvider.xmrigCCServerUrl;
    final xmrigCCWorkerId = minerStatusProvider.xmrigCCWorkerId;

    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                      ClipOval(
                        child: SizedBox.fromSize(
                          size: const Size.fromRadius(12),
                          child: Image.network(
                            coinData.coinLogoUrl,
                            width: 24,
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF273951),
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Text("Currently Mining: ${minerConfig.pools.first.algo}"),
                    const Spacer(),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shadowColor: Colors.transparent),
                        onPressed: () {
                          Provider.of<MinerStatusProvider>(context,
                                  listen: false)
                              .minerConfig = null;
                          widget
                              .setCurrentWizardStep(WizardStep.coinNameSelect);
                        },
                        child: const Text("Edit Config"))
                  ],
                ),
              ),
            const SizedBox(
              height: 16,
            ),
            if (selectedMinerBinary == MinerBinary.xmrig ||
                selectedMinerBinary == MinerBinary.ccminer)
              SizedBox(
                  width: double.infinity,
                  child: _showStartStopMining(isStarted: isMining)),
            if (selectedMinerBinary == MinerBinary.xmrigCC) ...[
              Text(
                "EPC running in worker mode",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Text("Control daemon from xmrigCCServer"),
              Text("Server URL: $xmrigCCServerUrl"),
              Text("Worker Id: $xmrigCCWorkerId")
            ],
            if (minerSummary != null || ccMinerSummary != null) ...[
              const SizedBox(
                height: 8,
              ),
              Text(
                "Miner Summary",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(
                width: 80,
                child: Divider(
                  thickness: 2,
                ),
              ),
              if (selectedMinerBinary == MinerBinary.xmrig ||
                  selectedMinerBinary == MinerBinary.xmrigCC)
                ..._minerSummaries(minerSummary),
              if (selectedMinerBinary == MinerBinary.ccminer)
                ..._ccMinerSummaries(ccMinerSummary)
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(
                width: 80,
                child: Divider(
                  thickness: 2,
                ),
              ),
              _minerLogsContainer()
            ],
          ],
        ));
  }
}

class _MinerSummaryItem {
  _MinerSummaryItem(
      {required this.title, required this.data, required this.iconData});

  final String title;
  final String data;
  final IconData iconData;
}
