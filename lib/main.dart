import 'dart:io';

import 'package:ekatapoolcompanion/providers/addressstat.dart';
import 'package:ekatapoolcompanion/providers/addressstatpayments.dart';
import 'package:ekatapoolcompanion/providers/chart.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:ekatapoolcompanion/providers/minersummary.dart';
import 'package:ekatapoolcompanion/providers/poolblock.dart';
import 'package:ekatapoolcompanion/providers/poolpayment.dart';
import 'package:ekatapoolcompanion/providers/poolstat.dart';
import 'package:ekatapoolcompanion/providers/uistate.dart';
import 'package:ekatapoolcompanion/screens/homepage.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_size/window_size.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux || Platform.isWindows) {
    setWindowMaxSize(const Size(450, 750));
    setWindowMinSize(const Size(450, 750));
  }
  if (!kDebugMode) {
    await SentryFlutter.init((options) {
      options.dsn =
          'https://93f420112d92434884109e77d8ecce56@o47401.ingest.sentry.io/6579571';
      options.tracesSampleRate = 0.5;
    }, appRunner: () => runApp(_mainApp()));
  } else {
    runApp(_mainApp());
  }
}

Widget _mainApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PoolStatProvider()),
      ChangeNotifierProvider(create: (_) => AddressStatProvider()),
      ChangeNotifierProvider(create: (_) => MinerSummaryProvider()),
      ChangeNotifierProvider(create: (_) => MinerStatusProvider()),
      ChangeNotifierProvider(create: (_) => UiStateProvider()),
      ChangeNotifierProvider(create: (_) => CoinDataProvider()),
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
  );
}

class EkataPoolCompanion extends StatelessWidget {
  const EkataPoolCompanion({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Ekata Pool Companion',
        // theme: ThemeData(
        //   primarySwatch: createMaterialColor(const Color(0xFF273951)),
        //   textTheme: Theme.of(context).textTheme.apply(
        //       bodyColor: const Color(0xFF273951),
        //       displayColor: const Color(0xFF273951)),
        // ),
        theme: FlexThemeData.light(
          scheme: FlexScheme.brandBlue,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 7,
          subThemesData: const FlexSubThemesData(
            blendOnLevel: 10,
            blendOnColors: false,
            useM2StyleDividerInM3: true,
            navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
            navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurface,
            navigationBarMutedUnselectedLabel: false,
            navigationBarSelectedIconSchemeColor: SchemeColor.onSurface,
            navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
            navigationBarMutedUnselectedIcon: false,
            navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
            navigationBarIndicatorOpacity: 1.00,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        ),
        darkTheme: FlexThemeData.dark(
          scheme: FlexScheme.brandBlue,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 13,
          subThemesData: const FlexSubThemesData(
            blendOnLevel: 20,
            useM2StyleDividerInM3: true,
            navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
            navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurface,
            navigationBarMutedUnselectedLabel: false,
            navigationBarSelectedIconSchemeColor: SchemeColor.onSurface,
            navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
            navigationBarMutedUnselectedIcon: false,
            navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
            navigationBarIndicatorOpacity: 1.00,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomePage());
  }
}
