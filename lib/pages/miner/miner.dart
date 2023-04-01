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

enum WizardStep { coinNameSelect, minerConfig, usersMinerConfigs, miner }

class Miner extends StatefulWidget {
  const Miner({Key? key}) : super(key: key);

  @override
  State<Miner> createState() => _MinerState();
}

class _MinerState extends State<Miner> {
  WizardStep _currentWizardStep = WizardStep.coinNameSelect;

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

    return _getCurrentWizard(_currentWizardStep, currentlyMiningMinerConfig,
        coinData, threadCount, minerConfigPath);
  }
}
