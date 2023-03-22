import 'dart:io';

import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/android_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/pages/miner/desktop_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/final_miner_config.dart';
import 'package:ekatapoolcompanion/pages/miner/miner_support.dart';
import 'package:ekatapoolcompanion/pages/miner/user_miner_config.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

//TODO: Cleanup - Old files, commented codes, image assets

enum WizardStep { coinNameSelect, minerConfig, usersMinerConfigs, miner }

class Miner extends StatefulWidget {
  const Miner({Key? key}) : super(key: key);

  @override
  State<Miner> createState() => _MinerState();
}

class _MinerState extends State<Miner> {
  WizardStep _currentWizardStep = WizardStep.coinNameSelect;

  // int? _selectedCoinIndex;

  @override
  void initState() {
    super.initState();
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance
          .trackEvent(eventCategory: 'Page Change', action: 'Miner');
    }
  }

  void _setCurrentWizardStep(WizardStep wizardStep) {
    setState(() {
      _currentWizardStep = wizardStep;
    });
  }

  // Widget _showCoinSelect(MinerConfig? currentlyMining, String? gpuVendor) {
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       _showCoinSelectInput(gpuVendor),
  //       if (_selectedCoinIndex != null) ...[
  //         const SizedBox(
  //           height: 8,
  //         ),
  //         _showPoolSelectInput(gpuVendor)
  //       ],
  //       const SizedBox(
  //         height: 8,
  //       ),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           OutlinedButton(
  //               onPressed: () {
  //                 _setCurrentWizardStep(WizardStep.minerConfig);
  //               },
  //               child: const Text("Use custom config")),
  //           const SizedBox(
  //             width: 8,
  //           ),
  //           OutlinedButton(
  //               onPressed: () {
  //                 _setCurrentWizardStep(WizardStep.usersMinerConfigs);
  //               },
  //               child: const Text("Saved configs"))
  //         ],
  //       ),
  //       const SizedBox(
  //         height: 8,
  //       ),
  //       _showCurrentlyMining(currentlyMining)
  //     ],
  //   );
  // }

  // Widget _showCoinSelectInput(String? gpuVendor) {
  //   var deviceHasGPU = gpuVendor != null;
  //   var _coinDatas = deviceHasGPU
  //       ? coinDatas
  //       : coinDatas.where((coinData) => coinData.cpuMineable);
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         "Select the coin you want to mine",
  //         style: TextStyle(
  //           fontSize: 14,
  //           color: Theme.of(context).primaryColor,
  //         ),
  //       ),
  //       SizedBox(
  //         width: 300,
  //         child: DropdownButton<CoinData>(
  //             itemHeight: null,
  //             isExpanded: true,
  //             hint: const Text("Select coin"),
  //             style: TextStyle(color: Theme.of(context).primaryColor),
  //             value: _selectedCoinIndex != null
  //                 ? coinDatas[_selectedCoinIndex!]
  //                 : null,
  //             items: _coinDatas
  //                 .map<DropdownMenuItem<CoinData>>(
  //                     (CoinData coinData) => DropdownMenuItem<CoinData>(
  //                         value: coinData,
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             const SizedBox(
  //                               height: 8,
  //                             ),
  //                             Row(
  //                               children: [
  //                                 Image(
  //                                   image: AssetImage(coinData.coinLogoUrl),
  //                                   width: 24,
  //                                   height: 24,
  //                                 ),
  //                                 const SizedBox(
  //                                   width: 8,
  //                                 ),
  //                                 Text(coinData.coinName),
  //                                 const SizedBox(
  //                                   width: 4,
  //                                 ),
  //                                 Text(
  //                                   "(${coinData.coinAlgo})",
  //                                   style: TextStyle(
  //                                       fontSize: 12,
  //                                       color: Theme.of(context).primaryColor),
  //                                 )
  //                               ],
  //                             ),
  //                             const SizedBox(
  //                               height: 8,
  //                             ),
  //                           ],
  //                         )))
  //                 .toList(),
  //             onChanged: (CoinData? coinData) {
  //               if (coinData != null) {
  //                 setState(() {
  //                   _selectedCoinIndex = coinDatas.indexOf(coinData);
  //                 });
  //               }
  //             }),
  //       )
  //     ],
  //   );
  // }

  // Widget _showPoolSelectInput(String? gpuVendor) {
  //   var deviceHasGPU = gpuVendor != null;
  //   List<CoinPool>? _coinPools;
  //   CoinData? _coinData;
  //   if (_selectedCoinIndex != null) {
  //     _coinData = coinDatas[_selectedCoinIndex!];
  //     _coinPools = _coinData.coinPools;
  //   }
  //
  //   return _coinData != null
  //       ? Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               "Select the pool where you want to mine ${_coinData.coinName}",
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 color: Theme.of(context).primaryColor,
  //               ),
  //             ),
  //             const SizedBox(
  //               height: 8,
  //             ),
  //             SizedBox(
  //               width: 300,
  //               child: DropdownButton<CoinPool>(
  //                 isExpanded: true,
  //                 hint: const Text("Select Pool"),
  //                 style: TextStyle(color: Theme.of(context).primaryColor),
  //                 items: _coinPools!
  //                     .map<DropdownMenuItem<CoinPool>>((CoinPool coinPool) =>
  //                         DropdownMenuItem<CoinPool>(
  //                             value: coinPool,
  //                             child: DefaultTextStyle(
  //                                 style: TextStyle(
  //                                     fontSize: 12,
  //                                     color: Theme.of(context).primaryColor),
  //                                 child: Row(
  //                                   children: [
  //                                     deviceHasGPU
  //                                         ? Text(
  //                                             "${coinPool.poolAddress}:${coinPool.poolPortGPU}")
  //                                         : Text(
  //                                             "${coinPool.poolAddress}:${coinPool.poolPortCPU}")
  //                                   ],
  //                                 ))))
  //                     .toList(),
  //                 onChanged: (CoinPool? coinPool) {
  //                   if (coinPool != null) {
  //                     _loadWalletAddress(
  //                         "${coinPool.poolAddress}:${deviceHasGPU ? coinPool.poolPortGPU : coinPool.poolPortCPU}");
  //                     MinerConfig minerConfig = MinerConfig(pools: [
  //                       Pool(
  //                           algo: _coinData!.coinAlgo,
  //                           url:
  //                               "${coinPool.poolAddress}:${deviceHasGPU ? coinPool.poolPortGPU : coinPool.poolPortCPU}",
  //                           user: "")
  //                     ]);
  //                     if (deviceHasGPU) {
  //                       if (gpuVendor.toLowerCase() == "nvidia") {
  //                         minerConfig.cuda = Gpu(enabled: true);
  //                       }
  //                       if (gpuVendor.toLowerCase() == "amd") {
  //                         minerConfig.opencl = Gpu(enabled: true);
  //                       }
  //                     } else {
  //                       minerConfig.cpu = Cpu(enabled: true);
  //                     }
  //                     Provider.of<MinerStatusProvider>(context, listen: false)
  //                         .minerConfig = minerConfig;
  //                     _setCurrentWizardStep(WizardStep.walletAddressInput);
  //                   }
  //                 },
  //               ),
  //             )
  //           ],
  //         )
  //       : Column();
  // }

  Widget _getMiner(
      String? minerConfigPath, ValueChanged<WizardStep> setCurrentWizardStep,
      [int? threadCount]) {
    return Platform.isAndroid
        ? AndroidMiner(
            minerConfigPath: minerConfigPath!,
            setCurrentWizardStep: setCurrentWizardStep,
            threadCount: threadCount,
          )
        : Platform.isLinux || Platform.isWindows
            ? DesktopMiner(
                minerConfigPath: minerConfigPath!,
                setCurrentWizardStep: setCurrentWizardStep,
                threadCount: threadCount,
              )
            : const MinerSupport();
  }

  Widget _getCurrentWizard(WizardStep wizardStep, MinerConfig? currentlyMining,
      CoinData? coinData, int? threadCount, String? minerConfigPath) {
    switch (wizardStep) {
      case WizardStep.coinNameSelect:
        return CoinDataWidget(setCurrentWizardStep: _setCurrentWizardStep);
      // case WizardStep.walletAddressInput:
      //   return WalletAddress(setCurrentWizardStep: _setCurrentWizardStep);
      case WizardStep.minerConfig:
        return FinalMinerConfig(
          setCurrentWizardStep: _setCurrentWizardStep,
        );
      case WizardStep.usersMinerConfigs:
        return UserMinerConfig(
          setCurrentWizardStep: _setCurrentWizardStep,
        );
      case WizardStep.miner:
        return _getMiner(minerConfigPath, _setCurrentWizardStep, threadCount);
      default:
        return CoinDataWidget(setCurrentWizardStep: _setCurrentWizardStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    CoinData? coinData = Provider.of<MinerStatusProvider>(context).coinData;
    MinerConfig? currentlyMiningMinerConfig =
        Provider.of<MinerStatusProvider>(context).currentlyMiningMinerConfig;
    int? threadCount =
        Provider.of<MinerStatusProvider>(context, listen: false).threadCount;
    String? minerConfigPath =
        Provider.of<MinerStatusProvider>(context).minerConfigPath;

    // return coinData == null
    //     ? _showCoinSelectInput(currentlyMiningMinerConfig, gpuVendor)
    //     : minerConfig != null && showMinerScreen
    //         ? _getMiner(coinData, minerConfig.pools.first.user,
    //             threadCount: threadCount, gpuVendor: gpuVendor)
    //         : _showWalletAddressInput(coinData, currentlyMiningMinerConfig);
    return _getCurrentWizard(_currentWizardStep, currentlyMiningMinerConfig,
        coinData, threadCount, minerConfigPath);
  }
}
