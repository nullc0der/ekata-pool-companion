import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PoolPort extends StatefulWidget {
  const PoolPort({Key? key, required this.setCurrentCoinDataWizardStep})
      : super(key: key);

  final ValueChanged<CoinDataWizardStep?> setCurrentCoinDataWizardStep;

  @override
  State<PoolPort> createState() => _PoolPortState();
}

class _PoolPortState extends State<PoolPort> {
  Widget _renderOnePoolPort(int poolPort, int? selectedPoolPort) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: poolPort == selectedPoolPort
              ? Theme.of(context).primaryColor.withOpacity(0.23)
              : Colors.white,
          borderRadius: BorderRadius.circular(4)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Provider.of<CoinDataProvider>(context, listen: false)
              .selectedPoolPort = poolPort;
          widget.setCurrentCoinDataWizardStep(
              CoinDataWizardStep.walletAddressInput);
        },
        child: Row(
          children: [
            Text(
              poolPort.toString(),
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
    final selectedPoolPort = coinDataProvider.selectedPoolPort;

    final poolPorts = selectedCoinData != null
        ? selectedCoinData.pools
            .firstWhere((element) =>
                element.poolName.toLowerCase().trim() == selectedPoolName &&
                element.region == selectedRegion)
            .ports
        : [];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select port",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: ListView(
            children: poolPorts.isNotEmpty
                ? poolPorts
                    .map((e) => _renderOnePoolPort(e, selectedPoolPort))
                    .toList()
                : [
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                          "There is no pool port in selected region at this moment",
                          style: Theme.of(context).textTheme.labelLarge),
                    )
                  ],
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // mainAxisAlignment: selectedPoolPort != null
            //     ? MainAxisAlignment.spaceBetween
            //     : MainAxisAlignment.center,
            children: [
              OutlinedButton(
                  onPressed: () {
                    Provider.of<CoinDataProvider>(context, listen: false)
                        .selectedPoolPort = null;
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.poolUrlSelect);
                  },
                  child: const Text("Select Pool Url")),
              // if (selectedPoolPort != null)
              //   ElevatedButton(
              //       onPressed: () {
              //         widget.setCurrentCoinDataWizardStep(null);
              //       },
              //       child: const Text("Done"))
            ],
          )
        ],
      ),
    );
  }
}
