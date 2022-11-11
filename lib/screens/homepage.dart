import 'dart:async';
import 'dart:io';

import 'package:ekatapoolcompanion/models/poolstat.dart';
import 'package:ekatapoolcompanion/pages/dashboard.dart';
import 'package:ekatapoolcompanion/pages/miner/coindatas.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/pages/payments.dart';
import 'package:ekatapoolcompanion/pages/pool_blocks.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/services/poolstat.dart';
import 'package:ekatapoolcompanion/widgets/custom_app_bar.dart';
import 'package:ekatapoolcompanion/widgets/custom_bottom_navigation.dart';
import 'package:ekatapoolcompanion/widgets/pool_select_action_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _bottomNavbarCurrentIndex = 0;
  Timer? _timer;
  StreamSubscription<dynamic>? _notificationTapEventSubscription;
  final EventChannel _notificationTapEventChannel = const EventChannel(
      "io.ekata.ekatapoolcompanion/notification_tap_event_channel");

  @override
  void initState() {
    super.initState();
    Future<PoolStat> _poolStat = PoolStatService().getPoolStat();
    _poolStat.then((value) {
      Provider.of<PoolStatProvider>(context, listen: false).poolStat = value;
      Provider.of<PoolStatProvider>(context, listen: false).hasFetchError =
          false;
    }).catchError((error) {
      Provider.of<PoolStatProvider>(context, listen: false).hasFetchError =
          true;
    });
    _fetchPoolStatPeriodically();
    if (!kDebugMode) {
      _initializeMatomoTracker();
    }
    if (Platform.isAndroid) {
      _handleNotificationTapEventStream();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notificationTapEventSubscription?.cancel();
    super.dispose();
  }

  void _handleNotificationTapEventStream() {
    _notificationTapEventSubscription = _notificationTapEventChannel
        .receiveBroadcastStream()
        .distinct()
        .listen((event) {
      _populateMinerStatus(Map<String, String>.from(event));
    });
  }

  void _populateMinerStatus(Map<String, String> minerStatusFromAndroid) {
    var minerStatusProvider =
        Provider.of<MinerStatusProvider>(context, listen: false);
    if (minerStatusProvider.coinData?.coinName !=
        minerStatusFromAndroid["coinName"]) {
      var coinData = coinDatas.firstWhere(
          (element) => element.coinName == minerStatusFromAndroid["coinName"]);
      var walletAddress = minerStatusFromAndroid["walletAddress"]!;
      var threadCount = int.tryParse(minerStatusFromAndroid["threadCount"]!);
      minerStatusProvider.coinData = coinData;
      minerStatusProvider.walletAddress = walletAddress;
      minerStatusProvider.threadCount = threadCount;
      minerStatusProvider.isMining = true;
      minerStatusProvider.showMinerScreen = true;
      minerStatusProvider.currentlyMining = {
        "coinData": coinData,
        "walletAddress": walletAddress,
        "threadCount": threadCount
      };
    }
    _switchTab(3);
  }

  void _fetchPoolStatPeriodically() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        PoolStat _poolStat = await PoolStatService().getPoolStat();
        Provider.of<PoolStatProvider>(context, listen: false).poolStat =
            _poolStat;
        Provider.of<PoolStatProvider>(context, listen: false).hasFetchError =
            false;
      } on Exception {
        Provider.of<PoolStatProvider>(context, listen: false).hasFetchError =
            true;
        if (Provider.of<PoolStatProvider>(context, listen: false).poolStat !=
            null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text("There is some issue updating pool data, will retry")));
        }
      }
    });
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return const DashBoard();
      case 1:
        return const PoolBlocks();
      case 2:
        return const Payments();
      case 3:
        return const Miner();
      default:
        return const DashBoard();
    }
  }

  Future<void> _initializeMatomoTracker() async {
    await MatomoTracker.instance.initialize(
      siteId: 16,
      url: 'https://matomo.ekata.io/matomo.php',
    );
  }

  void _switchTab(int tabIndex) {
    if (tabIndex == 3) {
      _timer?.cancel();
    } else {
      if (_timer == null || !_timer!.isActive) {
        _fetchPoolStatPeriodically();
      }
    }
    setState(() {
      _bottomNavbarCurrentIndex = tabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomAppBar(
          title: 'Ekata Pool Companion',
        ),
        body: _getBody(_bottomNavbarCurrentIndex),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _bottomNavbarCurrentIndex,
          onItemSelected: (index) {
            if (index != 4) {
              _switchTab(index);
            } else {
              showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return const PoolSelectActionSheet();
                  });
            }
          },
          items: [
            CustomBottomNavigationItem(
                selectedIcon: Icons.dashboard,
                unselectedIcon: Icons.dashboard_outlined,
                title: 'Dashboard'),
            CustomBottomNavigationItem(
                selectedIcon: Icons.widgets,
                unselectedIcon: Icons.widgets_outlined,
                title: 'Pool Blocks'),
            CustomBottomNavigationItem(
                selectedIcon: Icons.receipt,
                unselectedIcon: Icons.receipt_outlined,
                title: 'Payments'),
            CustomBottomNavigationItem(
                selectedIcon: Icons.developer_board,
                unselectedIcon: Icons.developer_board_outlined,
                title: 'Miner'),
            // CustomBottomNavigationItem(
            //     image: const Image(
            //       image: AssetImage('assets/images/baza.png'),
            //       width: 22,
            //       height: 22,
            //     ),
            //     title: 'Baza')
          ],
        ));
  }
}
