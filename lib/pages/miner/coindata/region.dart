import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
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
  Widget _renderOneRegion(String region, String? selectedRegion) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: region == selectedRegion
              ? Theme.of(context).primaryColor.withOpacity(0.56)
              : Theme.of(context).primaryColor.withOpacity(0.23),
          borderRadius: BorderRadius.circular(4)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Provider.of<CoinDataProvider>(context, listen: false).selectedRegion =
              region;
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

    final regions = selectedPoolName != null && selectedCoinData != null
        ? Set<String>.from(selectedCoinData.pools.map((e) {
            if (e.poolName.trim().toLowerCase() == selectedPoolName) {
              return e.region;
            }
          }))
        : <String>{};

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
            children: regions.isNotEmpty
                ? regions
                    .map((e) => _renderOneRegion(e, selectedRegion))
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
            mainAxisAlignment: selectedRegion != null
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              OutlinedButton(
                  onPressed: () {
                    Provider.of<CoinDataProvider>(context, listen: false)
                        .selectedRegion = null;
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.poolNameSelect);
                  },
                  child: const Text("Select Pool")),
              if (selectedRegion != null)
                ElevatedButton(
                    onPressed: () {
                      widget.setCurrentCoinDataWizardStep(
                          CoinDataWizardStep.poolUrlSelect);
                    },
                    child: const Text("Select Url"))
            ],
          )
        ],
      ),
    );
  }
}
