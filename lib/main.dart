import 'dart:io';

import 'package:ekatapoolcompanion/providers/addressstat.dart';
import 'package:ekatapoolcompanion/providers/addressstatpayments.dart';
import 'package:ekatapoolcompanion/providers/chart.dart';
import 'package:ekatapoolcompanion/providers/poolblock.dart';
import 'package:ekatapoolcompanion/providers/poolpayment.dart';
import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/screens/homepage.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';

// TODO: implement search, add matomo, add sentry, change pool share text location,
// add spcaing in my account page initial form

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux) {
    setWindowMaxSize(const Size(450, 750));
    setWindowMinSize(const Size(450, 750));
  }
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PoolStatProvider()),
      ChangeNotifierProvider(create: (_) => AddressStatProvider()),
      ChangeNotifierProxyProvider<PoolStatProvider, PoolBlockProvider>(
          create: (_) => PoolBlockProvider(),
          update: (_, poolStatProvider, poolBlockProvider) {
            if (poolBlockProvider == null) {
              throw ArgumentError.notNull('poolBlockProvider');
            }
            poolBlockProvider.addBlocks(
              poolStatProvider.poolStat?.pool.blocks,
              networkHeight: poolStatProvider.poolStat?.network.height,
              depth: poolStatProvider.poolStat?.config.depth,
              slushMiningEnabled:
                  poolStatProvider.poolStat?.config.slushMiningEnabled,
              blockTime: poolStatProvider.poolStat?.config.blockTime,
              weight: poolStatProvider.poolStat?.config.weight,
            );
            return poolBlockProvider;
          }),
      ChangeNotifierProxyProvider<PoolStatProvider, PoolPaymentProvider>(
          create: (_) => PoolPaymentProvider(),
          update: (_, poolStatProvider, poolPaymentProvider) {
            if (poolPaymentProvider == null) {
              throw ArgumentError.notNull('poolPaymentProvider');
            }
            poolPaymentProvider
                .addPayments(poolStatProvider.poolStat?.pool.payments);
            return poolPaymentProvider;
          }),
      ChangeNotifierProxyProvider<AddressStatProvider,
              AddressStatPaymentsProvider>(
          create: (_) => AddressStatPaymentsProvider(),
          update: (_, addressStatProvider, addressStatPaymentsProvider) {
            if (addressStatPaymentsProvider == null) {
              throw ArgumentError.notNull('addressStatPaymentsProvider');
            }
            addressStatPaymentsProvider
                .addPayments(addressStatProvider.addressStat?.payments);
            return addressStatPaymentsProvider;
          }),
      ChangeNotifierProxyProvider<PoolStatProvider, ChartDataProvider>(
          create: (_) => ChartDataProvider(),
          update: (_, poolStatProvider, chartDataProvider) {
            if (chartDataProvider == null) {
              throw ArgumentError.notNull('chartDataProvider');
            }
            chartDataProvider.addChartData(
                poolStatProvider.poolStat?.charts.hashrate, 'hashrate');
            chartDataProvider.addChartData(
                poolStatProvider.poolStat?.charts.workers, 'workers');
            chartDataProvider.addChartData(
                poolStatProvider.poolStat?.charts.difficulty, 'difficulty');
            return chartDataProvider;
          })
    ],
    child: const EkataPoolCompanion(),
  ));
}

class EkataPoolCompanion extends StatelessWidget {
  const EkataPoolCompanion({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Ekata Pool Companion',
        theme: ThemeData(
            primarySwatch: createMaterialColor(const Color(0xFF273951))),
        home: const HomePage());
  }
}
