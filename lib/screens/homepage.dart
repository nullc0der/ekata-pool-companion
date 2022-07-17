import 'dart:async';

import 'package:ekatapoolcompanion/models/poolstat.dart';
import 'package:ekatapoolcompanion/pages/dashboard.dart';
import 'package:ekatapoolcompanion/pages/my_account.dart';
import 'package:ekatapoolcompanion/pages/payments.dart';
import 'package:ekatapoolcompanion/pages/pool_blocks.dart';
import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/services/poolstat.dart';
import 'package:ekatapoolcompanion/widgets/custom_app_bar.dart';
import 'package:ekatapoolcompanion/widgets/custom_bottom_navigation.dart';
import 'package:ekatapoolcompanion/widgets/pool_select_action_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    Future<PoolStat> _poolStat = PoolStatService().getPoolStat();
    _poolStat.then((value) {
      Provider.of<PoolStatProvider>(context, listen: false).poolStat = value;
    });
    _fetchPoolStatPeriodically();
    if (!kDebugMode) {
      _initializeMatomoTracker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchPoolStatPeriodically() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      PoolStat _poolStat = await PoolStatService().getPoolStat();
      Provider.of<PoolStatProvider>(context, listen: false).poolStat =
          _poolStat;
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
        return const MyAccount();
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
              setState(() => _bottomNavbarCurrentIndex = index);
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
                selectedIcon: Icons.account_circle,
                unselectedIcon: Icons.account_circle_outlined,
                title: 'My Account'),
            CustomBottomNavigationItem(
                image: const Image(
                  image: AssetImage('assets/images/baza.png'),
                  width: 22,
                  height: 22,
                ),
                title: 'Baza')
          ],
        ));
  }
}
