import 'dart:io';

import 'package:ekatapoolcompanion/pages/miner/android_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/pages/miner/desktop_miner.dart';
import 'package:ekatapoolcompanion/pages/miner/final_miner_config.dart';
import 'package:ekatapoolcompanion/pages/miner/miner_support.dart';
import 'package:ekatapoolcompanion/pages/miner/user_miner_config.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

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

  Widget _getMiner(ValueChanged<WizardStep> setCurrentWizardStep) {
    return Platform.isAndroid
        ? AndroidMiner(
            setCurrentWizardStep: setCurrentWizardStep,
          )
        : Platform.isLinux || Platform.isWindows
            ? DesktopMiner(
                setCurrentWizardStep: setCurrentWizardStep,
              )
            : const MinerSupport();
  }

  Widget _getCurrentWizard(WizardStep wizardStep) {
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
        return _getMiner(_setCurrentWizardStep);
      default:
        return CoinDataWidget(setCurrentWizardStep: _setCurrentWizardStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _getCurrentWizard(_currentWizardStep);
  }
}
