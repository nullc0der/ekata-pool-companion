import 'package:ekatapoolcompanion/models/coindata.dart';
import 'package:ekatapoolcompanion/models/minerconfig.dart';
import 'package:ekatapoolcompanion/pages/miner/miner.dart';
import 'package:ekatapoolcompanion/providers/minerstatus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CurrentlyMining extends StatelessWidget {
  const CurrentlyMining({Key? key, required this.setCurrentWizardStep})
      : super(key: key);

  final ValueChanged<WizardStep> setCurrentWizardStep;

  @override
  Widget build(BuildContext context) {
    CoinData? coinData = Provider.of<MinerStatusProvider>(context).coinData;
    MinerConfig? currentlyMiningMinerConfig =
        Provider.of<MinerStatusProvider>(context).currentlyMiningMinerConfig;

    return currentlyMiningMinerConfig != null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (coinData != null) ...[
                Text("Currently Mining: ${coinData.coinName}"),
                const SizedBox(
                  width: 8,
                ),
                ClipOval(
                  child: SizedBox.fromSize(
                    size: const Size.fromRadius(12),
                    child: Image.network(
                      coinData.coinLogoUrl,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF273951),
                      ),
                    ),
                  ),
                ),
              ] else
                Text(
                    "Currently Mining: ${currentlyMiningMinerConfig.pools.first.algo}"),
              const SizedBox(
                width: 16,
              ),
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(shadowColor: Colors.transparent),
                  onPressed: () {
                    Provider.of<MinerStatusProvider>(context, listen: false)
                        .minerConfig = currentlyMiningMinerConfig;
                    setCurrentWizardStep(WizardStep.miner);
                  },
                  child: const Text("Show"))
            ],
          )
        : Container();
  }
}
