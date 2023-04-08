import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/utils/walletaddress.dart';
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
  Future<void> _onPressDone(CoinData coinData, String poolName,
      String poolRegion, String poolUrl, int poolPort) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 1),
        content:
            Text("Done pressed, first item from next steps will be selected")));
    final poolCredentials = await getPoolCredentials("$poolUrl:$poolPort");
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
    Provider.of<CoinDataProvider>(context, listen: false).threadCount = null;
    widget.setCurrentCoinDataWizardStep(null);
  }

  Widget _renderOnePoolPort(int poolPort, int? selectedPoolPort) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selected: poolPort == selectedPoolPort,
      onTap: () {
        Provider.of<CoinDataProvider>(context, listen: false).selectedPoolPort =
            poolPort;
        widget.setCurrentCoinDataWizardStep(
            CoinDataWizardStep.walletAddressInput);
      },
      title: Text(
        poolPort.toString(),
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
    final selectedPoolPort = coinDataProvider.selectedPoolPort;

    final poolPorts = selectedCoinData != null
        ? selectedCoinData.pools
            .firstWhere((element) =>
                element.poolName.toLowerCase().trim() == selectedPoolName &&
                element.region == selectedRegion)
            .ports
        : [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select port",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: poolPorts.isNotEmpty
                  ? ListView(
                      children: poolPorts
                          .map((e) => _renderOnePoolPort(e, selectedPoolPort))
                          .toList())
                  : Center(
                      child: Text(
                          "There is no pool port in selected region at this moment",
                          style: Theme.of(context).textTheme.labelLarge),
                    )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  onPressed: () {
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.poolUrlSelect);
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
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                duration: Duration(seconds: 1),
                                content:
                                    Text("Next pressed, first or selected item"
                                        " on list will be selected")));
                        Provider.of<CoinDataProvider>(context, listen: false)
                            .selectedPoolPort = selectedPoolPort != null &&
                                poolPorts.contains(selectedPoolPort)
                            ? selectedPoolPort
                            : poolPorts.first;
                        widget.setCurrentCoinDataWizardStep(
                            CoinDataWizardStep.walletAddressInput);
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
                            selectedRegion!,
                            selectedPoolUrl!,
                            selectedPoolPort != null &&
                                    poolPorts.contains(selectedPoolPort)
                                ? selectedPoolPort
                                : poolPorts.first);
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
