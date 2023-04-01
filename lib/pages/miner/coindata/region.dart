import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/utils/walletaddress.dart';
import 'package:emoji_flag_converter/emoji_flag_converter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Region extends StatefulWidget {
  const Region({Key? key, required this.setCurrentCoinDataWizardStep})
      : super(key: key);

  final ValueChanged<CoinDataWizardStep?> setCurrentCoinDataWizardStep;

  @override
  State<Region> createState() => _RegionState();
}

class _RegionState extends State<Region> {
  Future<void> _onPressDone(
      CoinData coinData, String poolName, Pool poolRegion) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 1),
        content:
            Text("Done pressed, first item from next steps will be selected")));
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
    Provider.of<CoinDataProvider>(context, listen: false).selectedMinerBinary =
        MinerBinary.xmrig;
    widget.setCurrentCoinDataWizardStep(null);
  }

  Widget _renderOneRegion(String region, String? selectedRegion) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: region == selectedRegion
              ? Theme.of(context).primaryColor.withOpacity(0.23)
              : Colors.white,
          borderRadius: BorderRadius.circular(4)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Provider.of<CoinDataProvider>(context, listen: false).selectedRegion =
              region;
          widget.setCurrentCoinDataWizardStep(CoinDataWizardStep.poolUrlSelect);
        },
        child: Row(
          children: [
            Text(EmojiConverter.fromAlpha2CountryCode(region)),
            const SizedBox(
              width: 8,
            ),
            Text(
              region,
              style: Theme.of(context).textTheme.labelLarge,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinDataProvider = Provider.of<CoinDataProvider>(context);
    final selectedCoinData = coinDataProvider.selectedCoinData;
    final selectedPoolName = coinDataProvider.selectedPoolName;
    final selectedRegion = coinDataProvider.selectedRegion;

    final selectedPoolsRegions = selectedPoolName != null &&
            selectedCoinData != null
        ? Set<Pool>.from(selectedCoinData.pools
            .where((e) => e.poolName.trim().toLowerCase() == selectedPoolName))
        : <Pool>{};

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select region",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: ListView(
            children: selectedPoolsRegions.isNotEmpty
                ? selectedPoolsRegions
                    .map((e) => _renderOneRegion(e.region, selectedRegion))
                    .toList()
                : [
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                          "There is no region in selected pool at this moment",
                          style: Theme.of(context).textTheme.labelLarge),
                    )
                  ],
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  onPressed: () {
                    Provider.of<CoinDataProvider>(context, listen: false)
                        .selectedRegion = null;
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.poolNameSelect);
                  },
                  style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 16,
                  )),
              Wrap(
                spacing: 4,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            duration: Duration(seconds: 1),
                            content: Text(
                                "Next pressed, first item on list will be selected")));
                        Provider.of<CoinDataProvider>(context, listen: false)
                            .selectedRegion = selectedPoolsRegions.first.region;
                        widget.setCurrentCoinDataWizardStep(
                            CoinDataWizardStep.poolUrlSelect);
                      },
                      style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder()),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 16,
                      )),
                  ElevatedButton(
                      onPressed: () async {
                        await _onPressDone(
                            selectedCoinData!,
                            selectedPoolName!.trim().toLowerCase(),
                            selectedPoolsRegions.first);
                      },
                      style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder()),
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
