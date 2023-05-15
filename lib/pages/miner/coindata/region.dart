import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/common.dart';
import 'package:ekatapoolcompanion/utils/walletaddress.dart';
import 'package:emoji_flag_converter/emoji_flag_converter.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:provider/provider.dart';

class Region extends StatefulWidget {
  const Region({Key? key, required this.setCurrentCoinDataWizardStep})
      : super(key: key);

  final ValueChanged<CoinDataWizardStep?> setCurrentCoinDataWizardStep;

  @override
  State<Region> createState() => _RegionState();
}

class _RegionState extends State<Region> {
  Future<void> _onPressDone(CoinData coinData, String poolName,
      String poolRegion, List<String> supportedMiningEngines) async {
    if (MatomoTracker.instance.initialized) {
      MatomoTracker.instance.trackEvent(
          eventCategory: "CoinData Wizard",
          action: "Pressed Done - Region",
          eventName: poolRegion);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 1),
        content:
            Text("Done pressed, first item from next steps will be selected")));
    final poolUrl = coinData.pools
        .firstWhere((element) =>
            element.poolName.toLowerCase().trim() == poolName &&
            element.region == poolRegion)
        .urls
        .first;
    final poolPort = coinData.pools
        .firstWhere((element) =>
            element.poolName.toLowerCase().trim() == poolName &&
            element.region == poolRegion)
        .ports
        .first;
    final poolCredentials = await getPoolCredentials("$poolUrl:$poolPort");
    final minerBinaries = getSupportedMinerBinaries(supportedMiningEngines);
    Provider.of<CoinDataProvider>(context, listen: false).selectedMinerBinary =
        minerBinaries.first;
    Provider.of<CoinDataProvider>(context, listen: false).selectedRegion =
        poolRegion;
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

  Widget _renderOneRegion(String region, String? selectedRegion) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      selected: region == selectedRegion,
      onTap: () {
        Provider.of<CoinDataProvider>(context, listen: false).selectedRegion =
            region;
        if (MatomoTracker.instance.initialized) {
          MatomoTracker.instance.trackEvent(
              eventCategory: "CoinData Wizard",
              action: "Selected Region",
              eventName: region);
        }
        widget.setCurrentCoinDataWizardStep(CoinDataWizardStep.poolUrlSelect);
      },
      horizontalTitleGap: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: region == "WW"
          ? const Text(
              "🌐",
              style: TextStyle(fontSize: 24),
            )
          : Text(EmojiConverter.fromAlpha2CountryCode(region)),
      title: region == "WW"
          ? const Text("World Wide")
          : Text(
              region,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinDataProvider = Provider.of<CoinDataProvider>(context);
    final selectedCoinData = coinDataProvider.selectedCoinData;
    final selectedPoolName = coinDataProvider.selectedPoolName;
    final selectedRegion = coinDataProvider.selectedRegion;

    final selectedPools = selectedPoolName != null && selectedCoinData != null
        ? Set<Pool>.from(selectedCoinData.pools
            .where((e) => e.poolName.trim().toLowerCase() == selectedPoolName))
        : <Pool>{};

    final regions = Set<String>.from(selectedPools.map((pool) => pool.region));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Region",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: regions.isNotEmpty
                  ? ListView(
                      children: regions
                          .map((region) =>
                              _renderOneRegion(region, selectedRegion))
                          .toList())
                  : Center(
                      child: Text(
                          "There is no region in selected pool at this moment",
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
                        action: "Pressed Previous - Region",
                      );
                    }
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.poolNameSelect);
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
                        final region = selectedRegion != null &&
                                regions.contains(selectedRegion)
                            ? selectedRegion
                            : regions.first;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                duration: Duration(seconds: 1),
                                content:
                                    Text("Next pressed, first or selected item"
                                        " on list will be selected")));
                        Provider.of<CoinDataProvider>(context, listen: false)
                            .selectedRegion = region;
                        if (MatomoTracker.instance.initialized) {
                          MatomoTracker.instance.trackEvent(
                              eventCategory: "CoinData Wizard",
                              action: "Pressed Next - Region",
                              eventName: region);
                        }
                        widget.setCurrentCoinDataWizardStep(
                            CoinDataWizardStep.poolUrlSelect);
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
                            selectedPoolName!.trim().toLowerCase(),
                            selectedRegion != null &&
                                    regions.contains(selectedRegion)
                                ? selectedRegion
                                : regions.first,
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
