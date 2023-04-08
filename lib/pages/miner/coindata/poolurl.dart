import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/pages/miner/coindata/coindatawidget.dart';
import 'package:ekatapoolcompanion/providers/coindata.dart';
import 'package:ekatapoolcompanion/utils/desktop_miner/miner.dart';
import 'package:ekatapoolcompanion/utils/walletaddress.dart';
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
  Future<void> _onPressDone(CoinData coinData, String poolName,
      String poolRegion, String poolUrl) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 1),
        content:
            Text("Done pressed, first item from next steps will be selected")));
    final poolPort = coinData.pools
        .firstWhere((element) =>
            element.poolName.toLowerCase().trim() == poolName &&
            element.region == poolRegion)
        .ports
        .first;
    final poolCredentials = await getPoolCredentials("$poolUrl:$poolPort");
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
    Provider.of<CoinDataProvider>(context, listen: false).threadCount = null;
    widget.setCurrentCoinDataWizardStep(null);
  }

  Widget _renderOnePoolUrl(String poolUrl, String? selectedPoolUrl) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selected: poolUrl == selectedPoolUrl,
      onTap: () {
        Provider.of<CoinDataProvider>(context, listen: false).selectedPoolUrl =
            poolUrl;
        widget.setCurrentCoinDataWizardStep(CoinDataWizardStep.portSelect);
      },
      title: Text(
        poolUrl,
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select url",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
              child: poolUrls.isNotEmpty
                  ? ListView(
                      children: poolUrls
                          .map((e) => _renderOnePoolUrl(e, selectedPoolUrl))
                          .toList(),
                    )
                  : Center(
                      child: Text(
                          "There is no pool url in selected region at this moment",
                          style: Theme.of(context).textTheme.labelLarge),
                    )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  onPressed: () {
                    widget.setCurrentCoinDataWizardStep(
                        CoinDataWizardStep.regionSelect);
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
                            .selectedPoolUrl = selectedPoolUrl != null &&
                                poolUrls.contains(selectedPoolUrl)
                            ? selectedPoolUrl
                            : poolUrls.first;
                        widget.setCurrentCoinDataWizardStep(
                            CoinDataWizardStep.portSelect);
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
                            selectedPoolUrl != null &&
                                    poolUrls.contains(selectedPoolUrl)
                                ? selectedPoolUrl
                                : poolUrls.first);
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
