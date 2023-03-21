import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PoolUrl extends StatefulWidget {
  const PoolUrl({Key? key, required this.setCurrentCoinDataWizardStep})
      : super(key: key);

  final ValueChanged<CoinDataWizardStep?> setCurrentCoinDataWizardStep;

  @override
  State<PoolUrl> createState() => _PoolUrlState();
}

class _PoolUrlState extends State<PoolUrl> {
  Widget _renderOnePoolUrl(String poolUrl, String? selectedPoolUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: poolUrl == selectedPoolUrl
              ? Theme.of(context).primaryColor.withOpacity(0.23)
              : Colors.white,
          borderRadius: BorderRadius.circular(4)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Provider.of<CoinDataProvider>(context, listen: false)
              .selectedPoolUrl = poolUrl;
        },
        child: Row(
          children: [
            Text(
              poolUrl,
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
    final selectedPoolUrl = coinDataProvider.selectedPoolUrl;

    final poolUrls = selectedCoinData != null
        ? selectedCoinData.pools
            .firstWhere((element) =>
                element.poolName.toLowerCase().trim() == selectedPoolName &&
                element.region == selectedRegion)
            .urls
        : [];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select url",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: ListView(
            children: poolUrls.isNotEmpty
                ? poolUrls
                    .map((e) => _renderOnePoolUrl(e, selectedPoolUrl))
                    .toList()
                : [
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                          "There is no pool url in selected region at this moment",
                          style: Theme.of(context).textTheme.labelLarge),
                    )
                  ],
          )),
          Row(
            mainAxisAlignment: selectedPoolUrl != null
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              OutlinedButton(
                  onPressed: () {
                    Provider.of<CoinDataProvider>(context, listen: false)
                        .selectedPoolUrl = null;
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.regionSelect);
                  },
                  child: const Text("Select Region")),
              if (selectedPoolUrl != null)
                ElevatedButton(
                    onPressed: () {
                      widget.setCurrentCoinDataWizardStep(
                          CoinDataWizardStep.portSelect);
                    },
                    child: const Text("Select Port"))
            ],
          )
        ],
      ),
    );
  }
}
