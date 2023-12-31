import 'dart:collection';

import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/walletaddress.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

class PoolName extends StatefulWidget {
  const PoolName({Key? key, required this.setCurrentCoinDataWizardStep})
      : super(key: key);

  final ValueChanged<CoinDataWizardStep?> setCurrentCoinDataWizardStep;

  @override
  State<PoolName> createState() => _PoolNameState();
}

class _PoolNameState extends State<PoolName> {
  Future<void> _onPressDone(CoinData coinData, String poolName,
      List<String> supportedMiningEngines) async {
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance.trackEvent(
          eventCategory: "CoinData Wizard",
          action: "Pressed Done - PoolName",
          eventName: poolName);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 1),
        content:
            Text("Done pressed, first item from next steps will be selected")));
    final poolRegion = Set<Pool>.from(coinData.pools
        .where((e) => e.poolName.trim().toLowerCase() == poolName)).first;
    final poolUrl = coinData.pools
        .firstWhere((element) =>
            element.poolName.toLowerCase().trim() == poolName &&
            element.region == poolRegion.region)
        .urls
        .first;
    final poolPort = coinData.pools
        .firstWhere((element) =>
            element.poolName.toLowerCase().trim() == poolName &&
            element.region == poolRegion.region)
        .ports
        .first;
    final poolCredentials = await getPoolCredentials("$poolUrl:$poolPort");
    final minerBinaries = getSupportedMinerBinaries(supportedMiningEngines);
    Provider.of<CoinDataProvider>(context, listen: false).selectedMinerBinary =
        minerBinaries.first;
    Provider.of<CoinDataProvider>(context, listen: false).selectedPoolName =
        poolName;
    Provider.of<CoinDataProvider>(context, listen: false).selectedRegion =
        poolRegion.region;
    Provider.of<CoinDataProvider>(context, listen: false).selectedPoolUrl =
        poolUrl;
    Provider.of<CoinDataProvider>(context, listen: false).selectedPoolPort =
        poolPort;
    Provider.of<CoinDataProvider>(context, listen: false).walletAddress =
        poolCredentials["walletAddress"] ?? "";
    Provider.of<CoinDataProvider>(context, listen: false).password =
        poolCredentials["password"];
    Provider.of<CoinDataProvider>(context, listen: false).rigId =
        poolCredentials["rigId"];
    Provider.of<CoinDataProvider>(context, listen: false).threadCount = null;
    widget.setCurrentCoinDataWizardStep(null);
  }

  Widget _renderOnePoolName(String poolName, String? selectedPoolName) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      selected: poolName.trim().toLowerCase() == selectedPoolName,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(
        poolName,
      ),
      onTap: () {
        Provider.of<CoinDataProvider>(context, listen: false).selectedPoolName =
            poolName.trim().toLowerCase();
        if (MatomoTracker.instance.initialized) {
          MatomoTracker.instance.trackEvent(
              eventCategory: "CoinData Wizard",
              action: "Selected PoolName",
              eventName: poolName);
        }
        widget.setCurrentCoinDataWizardStep(CoinDataWizardStep.regionSelect);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinDataProvider = Provider.of<CoinDataProvider>(context);
    final selectedCoinData = coinDataProvider.selectedCoinData;
    final selectedPoolName = coinDataProvider.selectedPoolName;

    final poolNames = selectedCoinData != null
        ? SplayTreeSet<String>.from(
            selectedCoinData.pools.map((e) => e.poolName))
        : <String>{};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Pool",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: poolNames.isNotEmpty
                  ? ListView(
                      children: poolNames
                          .map((e) => _renderOnePoolName(e, selectedPoolName))
                          .toList())
                  : Center(
                      child: Text(
                          "There is no pool in selected coin at this moment",
                          style: Theme.of(context).textTheme.labelLarge),
                    )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  onPressed: () {
                    if (MatomoTracker.instance.initialized) {
                      MatomoTracker.instance.trackEvent(
                        eventCategory: "CoinData Wizard",
                        action: "Pressed Previous - PoolName",
                      );
                    }
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.coinNameSelect);
                  },
                  style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      shadowColor: Colors.transparent),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 16,
                  )),
              Wrap(
                spacing: 4,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        final poolName = selectedPoolName != null &&
                                poolNames.contains(selectedPoolName)
                            ? selectedPoolName
                            : poolNames.first.trim().toLowerCase();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                duration: Duration(seconds: 1),
                                content:
                                    Text("Next pressed, first or selected item"
                                        " on list will be selected")));
                        Provider.of<CoinDataProvider>(context, listen: false)
                            .selectedPoolName = poolName;
                        if (MatomoTracker.instance.initialized) {
                          MatomoTracker.instance.trackEvent(
                              eventCategory: "CoinData Wizard",
                              action: "Pressed Next - PoolName",
                              eventName: poolName);
                        }
                        widget.setCurrentCoinDataWizardStep(
                            CoinDataWizardStep.regionSelect);
                      },
                      style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          shadowColor: Colors.transparent),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 16,
                      )),
                  ElevatedButton(
                      onPressed: () async {
                        await _onPressDone(
                            selectedCoinData!,
                            selectedPoolName != null &&
                                    poolNames.contains(selectedPoolName)
                                ? selectedPoolName
                                : poolNames.first.trim().toLowerCase(),
                            selectedCoinData.supportedMiningEngines);
                      },
                      style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          shadowColor: Colors.transparent),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                      ))
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
