import 'dart:async';
import 'dart:io';

import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/models/poolstat.dart';
import 'package:ekatapoolcompanion/pages/dashboard.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/pages/payments.dart';
import 'package:ekatapoolcompanion/pages/pool_blocks.dart';
import 'package:ekatapoolcompanion/pages/theme_chooser.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/providers/uistate.dart';
import 'package:ekatapoolcompanion/services/appversion.dart';
import 'package:ekatapoolcompanion/services/poolstat.dart';
import 'package:ekatapoolcompanion/services/systeminfo.dart';
import 'package:ekatapoolcompanion/services/userid.dart';
import 'package:ekatapoolcompanion/utils/common.dart' as common;
import 'package:ekatapoolcompanion/utils/constants.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/widgets/about_dialog.dart';
import 'package:ekatapoolcompanion/widgets/custom_bottom_navigation.dart';
import 'package:ekatapoolcompanion/widgets/pool_select_action_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: App navigation is fucked up, it is done in multiple level based on enum,
// we are loosing back button functionality, need to refactor to use flutter
// navigation feature
enum CurrentPage { themeChooser, other }

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  StreamSubscription<dynamic>? _notificationTapEventSubscription;
  final EventChannel _notificationTapEventChannel = const EventChannel(
      "io.ekata.ekatapoolcompanion/notification_tap_event_channel");
  CurrentPage _currentPage = CurrentPage.other;

  @override
  void initState() {
    super.initState();
    // Future<PoolStat> _poolStat = PoolStatService().getPoolStat();
    // _poolStat.then((value) {
    //   Provider.of<PoolStatProvider>(context, listen: false).poolStat = value;
    //   Provider.of<PoolStatProvider>(context, listen: false).hasFetchError =
    //       false;
    // }).catchError((error) {
    //   Provider.of<PoolStatProvider>(context, listen: false).hasFetchError =
    //       true;
    // });
    // _fetchPoolStatPeriodically();
    if (!kDebugMode) {
      _createAndSaveUserId().then((_) {
        _initializeMatomoTracker();
        _addAppVersion();
      });
    }
    if (Platform.isAndroid) {
      _handleNotificationTapEventStream();
    }
    if (Platform.isLinux || Platform.isWindows) {
      _getGPUVendor();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notificationTapEventSubscription?.cancel();
    super.dispose();
  }

  void _getGPUVendor() async {
    var gpuVendor = await common.getGPUVendor();
    if (gpuVendor != null) {
      Provider.of<MinerStatusProvider>(context, listen: false).gpuVendor =
          gpuVendor;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${gpuVendor.toUpperCase()} GPU found"
              ", will be enabled for mining appropriate coin/pool")));
    }
    if (gpuVendor == "nvidia") {
      _ensureCUDALoaderExist();
    }
  }

  void _ensureCUDALoaderExist() async {
    var cudaLoaderExist = await common.ensureCUDALoaderExist();
    if (!cudaLoaderExist) {
      Provider.of<MinerStatusProvider>(context, listen: false).gpuVendor = null;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("CUDA loader file couldn't be found, GPU mining disabled")));
    }
  }

  void _handleNotificationTapEventStream() {
    _notificationTapEventSubscription = _notificationTapEventChannel
        .receiveBroadcastStream()
        .distinct()
        .listen((event) {
      _populateMinerStatus(Map<String, String>.from(event));
    });
  }

  Future<void> _populateMinerStatus(
      Map<String, String> minerStatusFromAndroid) async {
    var minerStatusProvider =
        Provider.of<MinerStatusProvider>(context, listen: false);
    final selectedMinerBinary = MinerBinary.values
        .byName(minerStatusFromAndroid["minerBinary"] ?? "xmrig");
    if (minerStatusProvider.currentlyMiningMinerConfig == null &&
        minerStatusFromAndroid.containsKey("minerConfigPath") &&
        minerStatusFromAndroid["minerConfigPath"] != null) {
      final jsonString =
          await File(minerStatusFromAndroid["minerConfigPath"]!).readAsString();
      final minerConfig = minerConfigFromJson(jsonString, selectedMinerBinary);
      final threadCount = int.tryParse(minerStatusFromAndroid["threadCount"]!);
      minerStatusProvider.minerConfigPath =
          minerStatusFromAndroid["minerConfigPath"];
      minerStatusProvider.isMining = true;
      minerStatusProvider.currentlyMiningMinerConfig = minerConfig;
      minerStatusProvider.minerConfig = minerConfig;
      minerStatusProvider.threadCount = threadCount;
      minerStatusProvider.currentThreadCount = threadCount;
      minerStatusProvider.selectedMinerBinary = selectedMinerBinary;
      minerStatusProvider.currentMinerBinary = selectedMinerBinary;
      // Provider.of<UiStateProvider>(context, listen: false).showBottomNavbar =
      //     minerConfig.pools.first.url == "70.35.206.105:3333" ||
      //         minerConfig.pools.first.url == "70.35.206.105:5555";
      // Provider.of<UiStateProvider>(context, listen: false)
      //     .bottomNavigationIndex = 3;
    }
  }

  Future<void> _createAndSaveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(Constants.userIdSharedPrefs);
    if (userId == null) {
      try {
        final userId = await UserIdService.createUserId();
        if (userId.isNotEmpty) {
          prefs.setString(Constants.userIdSharedPrefs, userId);
          await SystemInfoService.uploadSystemInfo(
              userId: userId, systemInfo: common.getSystemInfo());
        }
      } on Exception catch (_) {}
    } else {
      if (userId.length > 16) {
        await _reCreateUserId();
      }
    }
  }

  // After we decided to match userId with matomo visitorId, we had to
  // trim userId size to 16 char long, so if the userId is previous 24 char long,
  // we need to recreate
  Future<void> _reCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final userId = await UserIdService.createUserId();
      if (userId.isNotEmpty) {
        prefs.setString(Constants.userIdSharedPrefs, userId);
        await SystemInfoService.uploadSystemInfo(
            userId: userId, systemInfo: common.getSystemInfo());
      }
    } on Exception catch (_) {}
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

  void _setCurrentPage(CurrentPage currentPage) {
    setState(() {
      _currentPage = currentPage;
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
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(Constants.userIdSharedPrefs);
    await MatomoTracker.instance.initialize(
        siteId: 16,
        url: 'https://matomo.ekata.io/matomo.php',
        visitorId: userId);
  }

  Future<void> _addAppVersion() async {
    final appVersion = await common.getPackageVersion();
    final prefs = await SharedPreferences.getInstance();
    final appVersionInPrefs =
        prefs.getString(Constants.currentAppVersionSharedPrefs);
    final userId = prefs.getString(Constants.userIdSharedPrefs);
    if (appVersion != appVersionInPrefs && userId != null) {
      try {
        final success = await AppVersionService.addAppVersion(
            userId: userId, appVersion: appVersion);
        if (success) {
          await prefs.setString(
              Constants.currentAppVersionSharedPrefs, appVersion);
        }
      } on Exception catch (_) {}
    }
  }

  void _switchTab(int tabIndex) {
    if (tabIndex == 3) {
      _timer?.cancel();
    } else {
      if (_timer == null || !_timer!.isActive) {
        _fetchPoolStatPeriodically();
      }
    }
    Provider.of<UiStateProvider>(context, listen: false).bottomNavigationIndex =
        tabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final showBottomNavbar =
        Provider.of<UiStateProvider>(context).showBottomNavbar;
    final bottomNavbarCurrentIndex =
        Provider.of<UiStateProvider>(context).bottomNavigationIndex;

    return Scaffold(
        appBar: AppBar(
          title: const Text("Ekata Pool Companion"),
          actions: [
            PopupMenuButton(
                offset: const Offset(0.0, 40.0),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      onTap: () {
                        Future.delayed(const Duration(seconds: 0),
                            () => showAboutAppDialog(context));
                      },
                      child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: const [
                            Icon(Icons.info),
                            SizedBox(
                              width: 4,
                            ),
                            Text('About')
                          ]),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        _setCurrentPage(CurrentPage.themeChooser);
                      },
                      child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: const [
                            Icon(Icons.dark_mode),
                            SizedBox(
                              width: 4,
                            ),
                            Text('Configure Theme')
                          ]),
                    )
                  ];
                })
          ],
        ),
        body: _currentPage == CurrentPage.themeChooser
            ? ThemeChooser(setCurrentPage: _setCurrentPage)
            : showBottomNavbar
                ? _getBody(bottomNavbarCurrentIndex)
                : const Miner(),
        bottomNavigationBar: showBottomNavbar
            ? CustomBottomNavigation(
                selectedIndex: bottomNavbarCurrentIndex,
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
              )
            : null);
  }
}
