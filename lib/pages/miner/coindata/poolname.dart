import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PoolName extends StatefulWidget {
  const PoolName({Key? key, required this.setCurrentCoinDataWizardStep})
      : super(key: key);

  final ValueChanged<CoinDataWizardStep?> setCurrentCoinDataWizardStep;

  @override
  State<PoolName> createState() => _PoolNameState();
}

class _PoolNameState extends State<PoolName> {
  Widget _renderOnePoolName(String poolName, String? selectedPoolName) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: poolName.trim().toLowerCase() == selectedPoolName
              ? Theme.of(context).primaryColor.withOpacity(0.23)
              : Colors.white,
          borderRadius: BorderRadius.circular(4)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Provider.of<CoinDataProvider>(context, listen: false)
              .selectedPoolName = poolName.trim().toLowerCase();
          widget.setCurrentCoinDataWizardStep(CoinDataWizardStep.regionSelect);
        },
        child: Row(
          children: [
            Text(
              poolName,
              style: Theme.of(context).textTheme.labelLarge,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Remove next buttons (Discuss)

    final coinDataProvider = Provider.of<CoinDataProvider>(context);
    final selectedCoinData = coinDataProvider.selectedCoinData;
    final selectedPoolName = coinDataProvider.selectedPoolName;

    final poolNames = selectedCoinData != null
        ? Set<String>.from(selectedCoinData.pools.map((e) => e.poolName))
        : <String>{};

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select pool",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: ListView(
            // TODO: Center container
            children: poolNames.isNotEmpty
                ? poolNames
                    .map((e) => _renderOnePoolName(e, selectedPoolName))
                    .toList()
                : [
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                          "There is no pool in selected coin at this moment",
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
                        .selectedPoolName = null;
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.coinNameSelect);
                  },
                  style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 16,
                  )),
              ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        duration: Duration(seconds: 1),
                        content: Text(
                            "Next pressed, first item on list will be selected")));
                    Provider.of<CoinDataProvider>(context, listen: false)
                            .selectedPoolName =
                        poolNames.first.trim().toLowerCase();
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.regionSelect);
                  },
                  style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                  ))
            ],
          )
        ],
      ),
    );
  }
}
